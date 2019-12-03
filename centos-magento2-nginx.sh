#!/bin/bash

# This script performs post-installation configuration of magento2 instance
# created on centos LEMP platform:
# 1. Adjusts directory/file ownership
# 2. Compiles magento2 code
# 3. Sets selinux access permissions
# 4. Installs nginx site configuration file for port 80 and restarts nginx
# It's supposed to be used after lightsail-centos-lemp.sh script, composer and
# `magento setup:install` commands
# MAGE_ROOT and MAGE_HOSTNAME variables will be requested to be entered from
# console.

echo -n "Enter magento2 root dir (e.g. /var/www/html/magento) and press [ENTER] "
read MAGE_ROOT
echo -n "Enter domain name for this magento installation and press [ENTER] "
read MAGE_HOSTNAME

cd $MAGE_ROOT
# bin/magento deploy:mode:set developer

find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R :nginx .
bin/magento setup:di:compile

yum -y install policycoreutils-python
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/app/etc(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/var(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/pub/media(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/pub/static(/.*)?"
restorecon -Rv "$MAGE_ROOT/"

cat > /etc/nginx/conf.d/magento.conf << EOT
upstream fastcgi_backend {
  server  unix:/run/php-fpm/php-fpm.sock;
}

server {
  listen 80;
  server_name $MAGE_HOSTNAME;
  set \$MAGE_ROOT $MAGE_ROOT;
  include $MAGE_ROOT/nginx.conf.sample;
}
EOT

service nginx restart
