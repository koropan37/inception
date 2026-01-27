FROM debian:bookworm


RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-mysql \
    php8.2-session \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O /var/www/html/index.php https://www.adminer.org/latest.php

COPY tools/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh


WORKDIR /var/www/html

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]