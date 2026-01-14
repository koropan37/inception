#!/bin/bash
set -e

# 環境変数のデフォルト値
: "${DOMAIN_NAME:=localhost}"

mkdir -p /etc/nginx/ssl

# 証明書がなければ作成
if [ ! -f /etc/nginx/ssl/inception.crt ] || [ ! -f /etc/nginx/ssl/inception.key ]; then
    echo "Generating SSL certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName = DNS:${DOMAIN_NAME}"
    echo "SSL certificate generated."
fi

# nginx を起動
exec nginx -g 'daemon off;'