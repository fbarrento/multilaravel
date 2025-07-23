#!/bin/bash

PORT=${1:-8000}
role=${CONTAINER_ROLE:-app}

if [ ! -f vendor/autoload.php ]; then
  composer install --no-progress --no-interaction
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

  php artisan cache:clear
  php artisan config:clear
  php artisan route:clear
  php artisan view:clear




