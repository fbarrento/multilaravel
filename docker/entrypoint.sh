#!/bin/bash

cd /var/www/main
bootstrap 8000

cd /var/www/admin
bootstrap 8001

role=${CONTAINER_ROLE:-app}

if [ "$role" = "worker" ]; then
  echo "Starting queue worker"
  cd /var/www/main
  php artisan queue:work --timeout=180 --tries=3 &
  cd /var/www/admin
  exec php artisan queue:work --timeout=180 --tries=3

elif [ "$role" = "websockets" ]; then
    echo "Starting websockets server"
    cd /var/www/main
    php artisan reverb:start --host=0.0.0.0 --port=6001 &
    cd /var/www/admin
    exec php artisan reverb:start --host=0.0.0.0 --port=6002

elif [ "$role" = "scheduler" ]; then
  crond &
  exec tail -f /var/log/cron.log

elif [ "$role" = "app" ]; then

  exec php-fpm --nodaemonize

fi
