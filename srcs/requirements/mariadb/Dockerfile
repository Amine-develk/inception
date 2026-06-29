FROM debian:bookworm

# install mariadb server + client (client gives us `mysql`/`mysqladmin` for init_db.sh)
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# create directories
RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod 755 /var/run/mysqld

# copy configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# copy entrypoint script
COPY tools/init_db.sh /usr/local/bin

# set permissions
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["init_db.sh"]