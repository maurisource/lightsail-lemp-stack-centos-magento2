# Lightsail LEMP Stack deployment on CentOS

This deploy script is currently used by our Magento agency to deploy a LEMP stack on Lightsail. CentOS server instance is used during spinup. After deploying the script, following services are deployed: Nginx, Mysql, Php, Composer

This is handy to quickly deploy and setup a single Php application. In our case we use it to deploy Magento 2 (centos-magento2-nginx.sh). You can also use this LEMP infrastructure for your Laravel application or any other Php app running on LEMP.

You can deploy this repo on your machine using the 5 lines code block below, or manually clone it on your server and run it as Root.

TODO: Command details will be added here to make this readme a proper documentation reference.

## Deploy while spinning your CentOS instance

    yum -y install git
    cd /root
    git clone https://github.com/maurisource/lightsail-lemp-stack-centos-magento2.git
    cd lightsail-lemp-stack-centos-magento2
    bash ./lightsail-centos-lemp.sh
  
  > Paste this code block within the Lightsail deploy interface. Make sure you've selected CentOS
  > Wait a couple of minutes for the services to become readily available
  
## Php  
  Magento 2.3.3 supports Php 7.3.x whereas previous version support 7.2.x. By default latest version of Php 7.2.25 is deployed on the server, if you'd like 7.3.x use following code during spin up.
  
    bash ./lightsail-centos-lemp.sh --php-version 7.3
    
 Php is also reconfigured. More details on the script itself. Service set to autostart 
    
 ## Php-fpm
 
 Php-fpm is also reconfigured. More details on the script itself. Service set to autostart 
    
 ## Nginx
 
 Nginx service is installed and preconfigured Root folder is var/www/html
 Service set to autostart 
 
 ## MySQL
  
 MySQL 5.7 is installed with a new user with full priviledges, a new database.
 
 -user: magento
 -database: magento
 
 Service set to autostart 
 
>  If you already have a MySQL service running, script will skip it in order not to destroy it


## Target directory user

      var/www/html
      
the targer directory is already chown for user nginx.

> Use user nginx when working in this directory via Cli to not run in permission issues. Magento strongly discourage the use of Root user, this is why this has been implemented accordingly. User nginx can be used as follow:

      sudo su - nginx

Afterward you'll be able to run default command such as:

      php bin/magento setup:upgrade
     
      
# Magento 2 post spinup script

This script performs post-installation configuration of magento2 instance. It's supposed to be used after lightsail-centos-lemp.sh script. **centos-magento2-nginx.sh** will allow you to prepare your Magento environment on the server prompting for the desired Magento root directory and your hostname. It will then perform following configuration actions accordingly:

 1. Adjusts directory/file ownership 
 2. Compiles magento2 code 
 3. Sets selinux access permissions 
 4. Installs nginx site configuration file for port 80 and restarts nginx

Afterwards we'll be ready to deploy our application. We make use of already loved [Magerun2](https://github.com/netz98/n98-magerun2) in order to pursue with vanilla Magento installation wizard.
