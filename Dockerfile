ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm-alpine

RUN apk add --no-cache nginx git unzip zip ca-certificates
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN addgroup -S container \
 && adduser -S -G container -h /home/container container \
 && mkdir -p /home/container/webroot /home/container/tmp /home/container/nginx /home/container/php-fpm \
 && chown -R container:container /home/container

WORKDIR /home/container
COPY ./start.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container
CMD ["/bin/sh", "/entrypoint.sh"]
