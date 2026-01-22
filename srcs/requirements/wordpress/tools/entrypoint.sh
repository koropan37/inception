#!/bin/bash
set -e

# Secretsから読み込み
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_PASSWORD=$(cat /run/secrets/wp_user_password)

# 環境変数チェック
test -n "$MYSQL_DATABASE"
test -n "$MYSQL_USER"
test -n "$MYSQL_PASSWORD"
test -n "$DOMAIN_NAME"
test -n "$WP_TITLE"
test -n "$WP_ADMIN_USER"
test -n "$WP_ADMIN_PASSWORD"
test -n "$WP_ADMIN_EMAIL"
test -n "$WP_USER"
test -n "$WP_PASSWORD"
test -n "$WP_USER_EMAIL"

# MariaDB接続待機
echo "Waiting for MariaDB..."
until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    sleep 2
done
echo "MariaDB is ready!"

cd /var/www/wordpress

# パーミッション設定
chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress

# 1. まずWordPressをダウンロード（まだない場合）
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
    
    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root
fi

# 2. WordPressがインストール済みか確認
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
    
    echo "WordPress installed successfully!"
else
    echo "WordPress already installed, updating URLs..."
    wp option update home "https://${DOMAIN_NAME}" --allow-root
    wp option update siteurl "https://${DOMAIN_NAME}" --allow-root
fi

# 3. 2人目のユーザー作成
if ! wp user get "${WP_USER}" --field=ID --allow-root 2>/dev/null; then
    echo "Creating user ${WP_USER}..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_PASSWORD}" \
        --allow-root
    
    echo "User created successfully!"
else
    echo "User ${WP_USER} already exists."
fi

# 再度パーミッション設定
chown -R www-data:www-data /var/www/wordpress

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F