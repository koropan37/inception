#!/bin/bash
set -e

# Secretsから読み込み
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# 環境変数の検証
test -n "$MYSQL_DATABASE"
test -n "$MYSQL_USER"
test -n "$MYSQL_PASSWORD"
test -n "$MYSQL_ROOT_PASSWORD"

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

# データベースシステムの初期化（初回のみ）
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# 一時起動（ネットワーク無効で安全に）
echo "Starting temporary MariaDB..."
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
MARIADB_PID=$!

# 起動待機
echo "Waiting for MariaDB..."
until mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

echo "Configuring database..."

# 初期設定SQL
mysql <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "Database configured."

# 一時プロセスを停止
kill $MARIADB_PID
wait $MARIADB_PID

# 本番起動
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0