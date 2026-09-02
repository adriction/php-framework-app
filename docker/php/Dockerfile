FROM php:8.4-fpm-alpine

# Dependances systeme :
# - git : necessaire a `plugin:install` (clone des plugins depuis leur depot).
# - icu-dev, libzip-dev : requises pour compiler les extensions intl/zip.
RUN apk add --no-cache git icu-dev libzip-dev \
    && docker-php-ext-install pdo_mysql intl zip opcache

# Composer (binaire officiel, pas de reinstallation via curl).
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY php.ini /usr/local/etc/php/conf.d/99-app.ini

WORKDIR /var/www/html
