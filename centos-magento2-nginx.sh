#!/bin/bash

# This script performs pre-installation configuration of directory and nginx
# so that n98-magerun2 utility could be used to install magento2 in the
# directory:
# 1. Creates target directory and adjusts its permissions
# 2. Installs n98-magerun2 utility globally
# 3. Sets selinux access permissions
# 4. Installs nginx site configuration file for port 80 and php-fpm pool for
#    the new virtual host
# It's supposed to be used after lightsail-centos-lemp.sh script (and may be
# executed automatically in some cases).
#
# MAGE_ROOT and MAGE_HOSTNAME variables will be taken from first and second
# command line param or requested to be entered from console if MAGE_ROOT is
# missing.
#
# The following commands are supposed to be called as root after magento
# installation is complete:
# 1. restorecon -Rv <magento_home>
# 2. service php-fpm restart; service nginx restart

MAGE_ROOT=$1
MAGE_HOSTNAME=$2
if [ -z $MAGE_ROOT ]; then
  echo -n "Enter magento2 root dir (e.g. /var/www/html/magento) and press [ENTER] "
  read MAGE_ROOT
  echo -n "Enter domain name for this magento installation and press [ENTER] "
  read MAGE_HOSTNAME
fi

# create the target directory
mkdir -p $MAGE_ROOT
chown nginx.nginx $MAGE_ROOT

# install magerun2 globally
curl -L -o /usr/local/bin/n98-magerun2.phar https://files.magerun.net/n98-magerun2.phar
chmod +x /usr/local/bin/n98-magerun2.phar

chown -R :nginx .

yum -y install policycoreutils-python
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/app/etc(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/var(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/pub/media(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "$MAGE_ROOT/pub/static(/.*)?"
restorecon -Rv "$MAGE_ROOT/"

# only install nginx virtual host if $MAGE_HOSTNAME is set
if [ ! -z $MAGE_HOSTNAME ]; then
  # create a separate php-fpm pool for the new site

  # first check if www.conf.0 file exists to ensure lightsail-centos-lemp.sh
  # already worked
  if [ -f /etc/php-fpm.d/www.conf.0 ]; then
    cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/$MAGE_HOSTNAME.conf
    sed -i "s/\[www\]/[$MAGE_HOSTNAME]/g" /etc/php-fpm.d/$MAGE_HOSTNAME.conf
    sed -i "s/listen\\s*=\\s*\\/run\\/php-fpm\\/php-fpm.sock/listen=\\/run\\/php-fpm\\/php-fpm-$MAGE_HOSTNAME.sock/g" /etc/php-fpm.d/$MAGE_HOSTNAME.conf
  fi

  # add nginx virtual host for the new site (but it won't be functional before
  # magento is installed because it's dependent on nginx.conf.sample file from
  # magento installation).
  cat > /etc/nginx/conf.d/$MAGE_HOSTNAME.conf << EOT
upstream fastcgi_backend_$MAGE_HOSTNAME {
  server  unix:/run/php-fpm/php-fpm-$MAGE_HOSTNAME.sock;
}

server {
  listen 80;
  server_name $MAGE_HOSTNAME;
  set \$MAGE_ROOT $MAGE_ROOT;
  include $MAGE_ROOT/nginx.conf.sample;
}
EOT

  # restart nginx only if relevant configuration exists due to magento already
  # being installed
  [ -f $MAGE_ROOT/nginx.conf.sample ] && service nginx restart

fi
