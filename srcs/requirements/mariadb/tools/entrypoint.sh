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

if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo "Initializing MariaDB..."
    
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # --bootstrap で設定（一時起動不要）
mysqld --user=mysql --bootstrap <<-EOSQL
        USE mysql;
        FLUSH PRIVILEGES;
        
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        
        DROP DATABASE IF EXISTS test;
        
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        
        FLUSH PRIVILEGES;
EOSQL
    
    touch /var/lib/mysql/.initialized
    echo "MariaDB initialized successfully"
else
    echo "MariaDB already initialized"
fi

exec mysqld --user=mysql --bind-address=0.0.0.0