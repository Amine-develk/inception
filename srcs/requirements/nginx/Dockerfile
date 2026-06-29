FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

COPY conf/wordpress.conf.template /etc/nginx/conf.d/wordpress.conf.template
COPY tools/init_nginx.sh /usr/local/bin/init_nginx.sh

RUN chmod +x /usr/local/bin/init_nginx.sh

EXPOSE 443

ENTRYPOINT ["init_nginx.sh"]