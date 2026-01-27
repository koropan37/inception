FROM debian:bookworm


RUN apt-get update && apt-get install -y \
    php \
    php-mysqli \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O /var/www/html/index.php


WORKDIR /var/www/html

CMD ["php", "-S", "0.0.0.0:8080"]