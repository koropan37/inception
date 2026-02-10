#!/bin/bash
set -e

echo "[1/5] Loading configuration..."

read_secret() {
    local secret_file="/run/secrets/$1"
    if [ -f "${secret_file}" ]; then
        cat "${secret_file}"
    else
        echo "ERROR: secret '$1' not found" >&2
        echo ""
    fi
}

MYSQL_PASSWORD=$(read_secret "db_password")
WP_ADMIN_PASSWORD=$(read_secret "wp_admin_password")
WP_USER_PASSWORD=$(read_secret "wp_user_password")

test -n "$MYSQL_PASSWORD" || { echo "ERROR: db_password required" >&2; exit 1; }
test -n "$WP_ADMIN_PASSWORD" || { echo "ERROR: wp_admin_password required" >&2; exit 1; }
test -n "$WP_USER_PASSWORD" || { echo "ERROR: wp_user_password required" >&2; exit 1; }
test -n "$MYSQL_DATABASE" || { echo "ERROR: MYSQL_DATABASE required" >&2; exit 1; }
test -n "$MYSQL_USER" || { echo "ERROR: MYSQL_USER required" >&2; exit 1; }
test -n "$MYSQL_HOST" || { echo "ERROR: MYSQL_HOST required" >&2; exit 1; }
test -n "$DOMAIN_NAME" || { echo "ERROR: DOMAIN_NAME required" >&2; exit 1; }
test -n "$WP_ADMIN_USER" || { echo "ERROR: WP_ADMIN_USER required" >&2; exit 1; }
test -n "$WP_ADMIN_EMAIL" || { echo "ERROR: WP_ADMIN_EMAIL required" >&2; exit 1; }
test -n "$WP_USER" || { echo "ERROR: WP_USER required" >&2; exit 1; }
test -n "$WP_USER_EMAIL" || { echo "ERROR: WP_USER_EMAIL required" >&2; exit 1; }
test -n "$WP_TITLE" || { echo "ERROR: WP_TITLE required" >&2; exit 1; }

echo "[1/5] ✓ Configuration loaded"

set -u

echo "[2/5] Waiting for MariaDB..."

MAX_RETRIES=30
RETRY_COUNT=0

until mysqladmin ping -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: MariaDB timeout" >&2
        exit 1
    fi
    sleep 2
done

echo "[2/5] ✓ MariaDB ready"

cd /var/www/wordpress

echo "[3/5] Checking WordPress..."

if [ -f "wp-config.php" ]; then
    echo "[3/5] ✓ WordPress already installed"
else
    echo "[3/5] Installing WordPress..."
    
    echo "[4/5] Downloading WordPress..."
    wp core download --allow-root
    echo "  ✓ Downloaded"
    
    echo "  Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root
    echo "  ✓ Config created"
    
    echo "  Installing core..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    echo "  ✓ Core installed"
    
    echo "  Creating user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
    echo "  ✓ User created"
    
    echo "[4/5] ✓ Installation complete"
fi

echo "[5/5] Setting permissions..."
chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress
echo "[5/5] ✓ Permissions set"

unset MYSQL_PASSWORD WP_ADMIN_PASSWORD WP_USER_PASSWORD

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F