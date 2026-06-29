#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

if [ ! -f "/var/lib/mysql/.inception_initialized" ]; then
    echo "[init_db] No existing database found, initializing..."

    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal \
        > /dev/null

    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    tmp_pid="$!"

    for i in $(seq 1 30); do
        if mysqladmin --socket=/run/mysqld/mysqld.sock ping > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    mysql --socket=/run/mysqld/mysqld.sock -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOSQL

    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "$tmp_pid" 2>/dev/null || true
else
    echo "[init_db] Existing database found, skipping initialization."
fi

echo "[init_db] Starting MariaDB in foreground..."
touch /var/lib/mysql/.inception_initialized
exec mariadbd --user=mysql