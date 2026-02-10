FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y mariadb-server gettext-base && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY conf/init.sql /usr/local/etc/mariadb/init.sql

COPY tools/entrypoint.sh /usr/local/bin/
COPY tools/healthcheck.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

EXPOSE 3306

ENTRYPOINT ["entrypoint.sh"]
CMD ["mysqld", "--user=mysql", "--console"]