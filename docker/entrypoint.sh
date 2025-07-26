#!/bin/bash

cd /var/www/main
bootstrap 8000

cd /var/www/admin
bootstrap 8001

role=${CONTAINER_ROLE:-app}

if [ "$role" = "worker" ]; then
  echo "Starting queue worker"
  cd /var/www/admin
  php artisan horizon:terminate & php artisan horizon

elif [ "$role" = "reverb" ]; then
    echo "Starting reverb server"
    cd /var/www/main
    php artisan reverb:start --host=0.0.0.0 --port=6001

elif [ "$role" = "scheduler" ]; then
  crond &
  exec tail -f /var/log/cron.log

elif [ "$role" = "app" ]; then

  exec php-fpm --nodaemonize

fi
