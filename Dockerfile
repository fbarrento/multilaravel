FROM php:8.4-fpm-bookworm as php
LABEL authors="franciscobarrento"

ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
ENV PHP_OPCACHE_REVALIDATE_FREQ=1


RUN usermod -u 1000 www-data

# Install system dependencies and build tools
RUN apt update && apt install -y \
    curl \
    unzip \
    libpq-dev \
    libcurl4-gnutls-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    cron \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x LTS and npm
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt update \
    && apt install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    pcntl \
    bcmath \
    zip \
    gd \
    intl

# Install Redis extension via PECL
RUN pecl install -o -f redis \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/pear

COPY --chown=www-data . /var/www
COPY docker/entrypoint.sh /usr/bin/entrypoint
COPY docker/bootstrap.sh /usr/bin/bootstrap
RUN chmod +x /usr/bin/entrypoint
RUN chmod +x /usr/bin/bootstrap

COPY ./docker/php/php.ini /usr/local/etc/php/php.ini
COPY ./docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf


COPY docker/php/scheduler /etc/cron.d/scheduler
RUN chmod 0644 /etc/cron.d/scheduler

RUN touch /var/log/cron.log

RUN crontab /etc/cron.d/scheduler

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/main

ENTRYPOINT ["entrypoint"]