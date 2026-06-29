#!/bin/bash
set -e  # exit immediately if any command fails, instead of continuing in a broken state

# Secrets are mounted as files by Docker Compose at container start.
# Reading them at runtime (not baking them into the image) keeps them out
# of `docker history` / image layers.
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

# Debian's mariadb-server package pre-creates /var/lib/mysql/mysql at BUILD
# time, so we can't use that to detect a "first run" - it always exists.
# We use our own marker file instead, only created once setup succeeds.
if [ ! -f "/var/lib/mysql/.inception_initialized" ]; then
    echo "[init_db] No existing database found, initializing..."

    # Sets up the actual data directory structure MariaDB needs to run at all.
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal \
        > /dev/null

    # Temporary instance, local-socket-only (no network), just to run setup SQL.
    # The database/users don't exist yet, so there's no reason for this to be
    # reachable from other containers at this point.
    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    tmp_pid="$!"

    # Poll until the temporary instance is actually ready to accept commands -
    # starting a background process doesn't mean it's immediately usable.
    for i in $(seq 1 30); do
        if mysqladmin --socket=/run/mysqld/mysqld.sock ping > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    # @'%' allows connection from any host, since WordPress connects from a
    # different container, not localhost. GRANT is scoped to one database
    # only, so a compromised WordPress can't touch the rest of the server.
    mysql --socket=/run/mysqld/mysqld.sock -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL

    # Clean shutdown (not killed) so everything flushes to disk properly,
    # then wait for it to fully exit before starting the real instance below.
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "$tmp_pid" 2>/dev/null || true

    # Created LAST, only after everything above succeeded. If the script
    # crashed midway, this wouldn't exist, and next start would retry setup.
    touch /var/lib/mysql/.inception_initialized
else
    echo "[init_db] Existing database found, skipping initialization."
fi

echo "[init_db] Starting MariaDB in foreground..."
# exec REPLACES this script's process with mariadbd itself, instead of
# spawning a child. This makes mariadbd PID 1, so it receives `docker stop`
# signals directly and shuts down cleanly - no wrapper process, no
# tail -f / sleep infinity style hacks.
exec mariadbd --user=mysql