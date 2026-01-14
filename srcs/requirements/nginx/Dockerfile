FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# SSL ディレクトリ作成
RUN mkdir -p /etc/nginx/ssl

# 設定ファイルとentrypointをコピー
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# 実行権限付与
RUN chmod +x /usr/local/bin/entrypoint.sh

# 権限設定
RUN mkdir -p /var/run/nginx && \
    chmod 755 /var/www/html && \
    chown -R www-data:www-data /var/www/html

EXPOSE 443

ENTRYPOINT ["entrypoint.sh"]