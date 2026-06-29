# Debian 12 "bookworm" - ships PHP 8.2 by default
FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-cli \
    php-mysql \
    php-curl \
    php-gd \
    php-intl \
    php-mbstring \
    php-soap \
    php-xml \
    php-zip \
    php-bcmath \
    curl \
    ca-certificates \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# wp-cli is a single PHP script, not a Docker image - downloading it directly
# is just fetching a tool, no different from installing any other CLI utility
RUN curl -fsSL -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init_wp.sh /usr/local/bin/init_wp.sh

RUN chmod +x /usr/local/bin/init_wp.sh \
    && mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["init_wp.sh"]