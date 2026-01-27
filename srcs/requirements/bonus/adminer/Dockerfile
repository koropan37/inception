FROM debian:bookworm

# 必要なPHPとwgetをインストール
RUN apt-get update && apt-get install -y \
    php \
    php-mysqli \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Adminerの本体（PHPファイル）をダウンロードして配置
RUN wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O /var/www/html/index.php

# サーバーを起動する場所を作る
WORKDIR /var/www/html

# PHPのビルトインサーバーを8080番ポートで起動
CMD ["php", "-S", "0.0.0.0:8080"]