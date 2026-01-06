FROM debian:bookworm

# NGINXとOpenSSLをインストール
RUN apt-get update && apt-get install -y nginx openssl

# SSL証明書を保存するディレクトリを作成
RUN mkdir -p /etc/nginx/ssl

# 自己署名証明書（オレオレ証明書）を作成
# ここでのポイントは、対話なし(-nodes)で作成し、有効期限などを設定している点です
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=JP/ST=Tokyo/L=Shinjuku/O=42/OU=42/CN=login.42.fr/UID=login"

# 設定ファイルをコピー（次のステップで作ります）
COPY conf/nginx.conf /etc/nginx/nginx.conf

# 権限設定（www-dataユーザーが標準的）
RUN mkdir -p /var/run/nginx
RUN chmod 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html

# フォアグラウンドで実行（これをしないとDockerがすぐ終了してしまう）
CMD ["nginx", "-g", "daemon off;"]