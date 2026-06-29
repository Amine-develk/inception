#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(grep '^WP_ADMIN_PASSWORD=' /run/secrets/credentials | cut -d '=' -f2-)
WP_USER_PASSWORD=$(grep '^WP_USER_PASSWORD=' /run/secrets/credentials | cut -d '=' -f2-)

echo "[init_wp] Waiting for MariaDB to be reachable..."
until mysqladmin ping -h "mariadb" -u "${MYSQL_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
    sleep 2
done
echo "[init_wp] MariaDB is up."

cd /var/www/html

if [ ! -f wp-config.php ]; then
    echo "[init_wp] No existing install found, setting up WordPress..."

    wp core download --allow-root

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "[init_wp] Creating second (non-admin) WordPress user..."
    wp user create \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "[init_wp] WordPress install complete."
else
    echo "[init_wp] Existing wp-config.php found, skipping install."
fi

chown -R www-data:www-data /var/www/html

echo "[init_wp] Starting php-fpm in foreground..."
exec php-fpm8.2 -F