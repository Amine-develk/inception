#!/bin/bash
set -e

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    echo "[init_nginx] Generating self-signed TLS certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=MA/ST=Casablanca/L=Casablanca/O=42Inception/CN=${DOMAIN_NAME}"
fi

echo "[init_nginx] Rendering nginx config for domain ${DOMAIN_NAME}..."
envsubst '${DOMAIN_NAME}' < /etc/nginx/conf.d/wordpress.conf.template > /etc/nginx/conf.d/wordpress.conf

echo "[init_nginx] Starting nginx in foreground..."
exec nginx -g "daemon off;"