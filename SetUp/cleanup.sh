#!/bin/bash

# Remove Apache
sudo apt purge -y apache2

# Remove phpMyAdmin
sudo apt purge -y phpmyadmin

# Remove MySQL
sudo apt purge -y mysql-server mysql-client mysql-common
sudo rm -rf /etc/mysql/
sudo rm -rf /var/lib/mysql/

# Remove PHP
sudo apt purge -y php libapache2-mod-php php-mysql php-pdo php-intl php-gd php-xml php-json php-mbstring php-tokenizer php-fileinfo php-opcache

# Remove Composer
sudo rm -f /usr/local/bin/composer

# Remove Apache virtual host
sudo rm -f /etc/apache2/sites-available/algebra_test.conf
sudo rm -f /etc/apache2/sites-enabled/algebra_test.conf

# Remove website directory
sudo rm -rf /var/www/algebra_test

echo "Cleanup completed successfully!"
