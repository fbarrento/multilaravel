#!/bin/bash

PORT=${1:-8000}
role=${CONTAINER_ROLE:-app}

if [ ! -f vendor/autoload.php ]; then
  composer install --no-progress --no-interaction
fi

if [ ! -f .env ]; then
  echo "Creating env file for new $APP_ENV"
  cp .env.example .env
else
  echo "env file already exists"
fi

if [ -d storage ]; then
  echo "Setting storage permissions"
  chmod -R 755 storage
fi

if [ -d bootstrap ]; then
  echo "Setting bootstrap permissions"
  chmod -R 755 bootstrap
fi

  php artisan migrate --force

  php artisan key:generate
  php artisan cache:clear
  php artisan config:clear
  php artisan route:clear
  php artisan view:clear




