# This bash script installs LEMP on centos7 (tested with version 1901-01
# provided by lightsail service).
# Implements prerequisite steps from:
# https://devdocs.magento.com/guides/v2.3/install-gde/prereq/nginx.html#centos-7

# read command line params

# default PHP version (7.3 may be requested by using
# --php-version 7.3 command-line switch)
PHP_VERSION=7.2 

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --php-version)
    if [ $2 == '7.3' ]; then
      PHP_VERSION=7.3
    fi
    shift; # past argument
    shift; # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


# install required tools
yum -y install unzip wget

# install and start nginx
yum -y install epel-release
yum -y install nginx

systemctl start nginx
systemctl enable nginx

# install php 7.0
# rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
# yum -y install php70w-fpm php70w
# yum -y install php70w-pdo php70w-mysqlnd php70w-opcache php70w-xml php70w-gd php70w-devel php70w-mysql php70w-intl php70w-mbstring php70w-bcmath php70w-json php70w-iconv php70w-soap


# install php. 7.2 is the default, 7.3 can be requested by adding
# --php-version 7.3 command line param.
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y yum-utils
yum-config-manager --disable remi-php54
yum-config-manager --enable remi-php${PHP_VERSION//.}
yum -y install php-fpm php
yum -y install php-pdo php-mysqlnd php-opcache php-xml php-gd php-devel php-mysql php-intl php-mbstring php-bcmath php-json php-iconv php-soap php-pecl-zip


# reconfigure php
cp /etc/php.ini /etc/php.ini.0
sed -i '/cgi.fix_pathinfo\s*=/s/^\s*;//g' /etc/php.ini
sed -i '/cgi.fix_pathinfo\s*=/s/=.*$/=1/g' /etc/php.ini
sed -i '/memory_limit\s*=/s/=.*$/=2G/g' /etc/php.ini
sed -i '/max_execution_time\s*=/s/=.*$/=1800/g' /etc/php.ini
sed -i '/zlib.output_compression\s*=/s/=.*$/=On/g' /etc/php.ini

sed -i '/^;session.save_path\s*=/s/^;//g' /etc/php.ini
sed -i '/^session.save_path\s*=/s/=.*$/="\/var\/lib\/php\/session"/g' /etc/php.ini

# reconfigure php-fpm
cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.0
sed -i '/^user\s*=/s/=.*$/= nginx/g' /etc/php-fpm.d/www.conf
sed -i '/^group\s*=/s/=.*$/= nginx/g' /etc/php-fpm.d/www.conf
sed -i '/^listen\s*=/s/=.*$/= \/run\/php-fpm\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
sed -i '/listen.owner\s*=/s/^\s*;//g' /etc/php-fpm.d/www.conf
sed -i '/^listen.owner\s*=/s/=.*$/= nginx/g' /etc/php-fpm.d/www.conf
sed -i '/listen.group\s*=/s/^\s*;//g' /etc/php-fpm.d/www.conf
sed -i '/^listen.group\s*=/s/=.*$/= nginx/g' /etc/php-fpm.d/www.conf
sed -i '/listen.mode\s*=/s/^\s*;//g' /etc/php-fpm.d/www.conf
sed -i '/^listen.mode\s*=/s/=.*$/= 0660/g' /etc/php-fpm.d/www.conf

sed -i '/^;env\[\(HOSTNAME\|PATH\|TMP\|TMPDIR\|TEMP\)\]/s/^;//g' /etc/php-fpm.d/www.conf

mkdir -p /var/lib/php/session/
chown -R nginx:nginx /var/lib/php/
mkdir -p /run/php-fpm/
chown -R nginx:nginx /run/php-fpm/

# allow login as nginx
usermod --shell /bin/bash nginx

# chown the target directory to nginx
chown nginx.nginx /var/www/html

# start php-fpm
systemctl start php-fpm
systemctl enable php-fpm

# install mysql 5.7
cd /root
wget http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
yum -y localinstall mysql57-community-release-el7-7.noarch.rpm
yum -y install mysql-community-server

# reset root password in mysql
service mysqld stop
ls -l /var/lib/mysql > /root/mysql-dir.lst
bck_dir=/var/lib/mysql-`date +%s`
mkdir $bck_dir
mv /var/lib/mysql/* $bck_dir/
mysqld --initialize-insecure --user=mysql

# TODO: may need to add performance enhancements in my.cnf

# start mysql and add magento database and user (w/o password)
service mysqld start
systemctl enable mysqld

mysql -u root <<SQL
create database magento;
create user magento;
GRANT ALL PRIVILEGES ON magento.* TO magento;
flush privileges;
SQL

# install composer globally
curl -s https://getcomposer.org/installer > /root/composer_installer.php
HOME=/root/ /bin/php /root/composer_installer.php --install-dir=/usr/bin --filename=composer > /root/composer_install.log 2>&1

