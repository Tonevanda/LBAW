#!/bin/bash
set -e

cd /var/www
env >> /var/www/.env
php artisan clear-compiled
php artisan config:clear

# Add cron job into cronfile
echo "* * * * * cd /var/www && php artisan schedule:run >> /dev/null 2>&1" >> cronfile

# Install cron job
crontab cronfile

# Remove temporary file
rm cronfile

# Start cron
cron



php-fpm8.1 -D
nginx -g "daemon off;"
