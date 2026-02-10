#!/bin/bash
set -e

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

test -n "$MYSQL_DATABASE"
test -n "$MYSQL_USER"
test -n "$MYSQL_PASSWORD"
test -n "$MYSQL_ROOT_PASSWORD"

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Socket指定で起動
    mysqld --user=mysql \
           --skip-networking \
           --socket=/var/run/mysqld/mysqld.sock &
    pid="$!"

    # 起動待機（タイムアウト付き）
    for i in {30..0}; do
        if mysqladmin \
            --socket=/var/run/mysqld/mysqld.sock \
            ping > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    if [ "$i" = "0" ]; then
        echo "ERROR: MariaDB did not start"
        exit 1
    fi

    # SQLファイルを使用
    envsubst < /usr/local/etc/mariadb/init.sql | \
        mysql --user=root --socket=/var/run/mysqld/mysqld.sock

    # 正常シャットダウン
    mysqladmin \
        --user=root \
        --password="${MYSQL_ROOT_PASSWORD}" \
        --socket=/var/run/mysqld/mysqld.sock \
        shutdown

    wait "$pid" || true
fi

exec mysqld --user=mysql --console