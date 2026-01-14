FROM debian:bookworm

# PHP-FPM と必要な拡張機能をインストール
RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    mariadb-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# WP-CLIをインストール
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# PHP-FPMの設定をコピー
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# エントリーポイントスクリプトをコピー
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# WordPress用のディレクトリを作成
RUN mkdir -p /var/www/wordpress
RUN chown -R www-data:www-data /var/www/wordpress

WORKDIR /var/www/wordpress

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]