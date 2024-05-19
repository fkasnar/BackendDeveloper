#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update package lists
sudo apt update

# Upgrade installed packages to their latest versions
sudo apt upgrade -y

# Check if Apache is installed
if ! dpkg -l apache2 &> /dev/null; then
    # If Apache is not installed, install it
    sudo apt install -y apache2
fi

# Check if Apache is running
if ! systemctl is-active --quiet apache2; then
    # If Apache is not running, start it
    sudo systemctl start apache2
fi

# Check if MySQL server is installed
if ! dpkg -l mysql-server &> /dev/null; then
    # If MySQL is not installed, install it
    sudo apt install -y mysql-server
fi

# Check if MySQL service is running
if ! systemctl is-active --quiet mysql; then
    # If MySQL is not running, start it
    sudo systemctl start mysql
fi

# Configure MySQL
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
CREATE USER 'algebra'@'localhost' IDENTIFIED BY 'algebra';
GRANT ALL PRIVILEGES ON *.* TO 'algebra'@'localhost';
exit
EOF

# Install PHP and its modules
sudo apt install -y php libapache2-mod-php php-mysql php-pdo php-intl php-gd php-xml php-json php-mbstring php-tokenizer php-fileinfo php-opcache

# Configure Apache virtual host
sudo tee /etc/apache2/sites-available/algebra_test.conf >/dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin algebra@localhost
    DocumentRoot /var/www/algebra_test
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/algebra_test>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    Alias /phpmyadmin /usr/share/phpmyadmin
    <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Create directory for website
sudo mkdir -p /var/www/algebra_test

# Enable the site
sudo a2ensite algebra_test

# Disable the default site
sudo a2dissite 000-default

# Test Apache configuration
sudo apache2ctl configtest

# Reload Apache
sudo systemctl reload apache2

# Create index.html
cat <<EOF | sudo tee /var/www/algebra_test/index.html >/dev/null
<html>
  <head>
    <title>Algebra Test Website</title>
  </head>
  <body>
    <h1>Hello World!</h1>
    <p>This is the landing page of <strong>Algebra Test</strong>.</p>
  </body>
</html>
EOF

# Create index.php with phpinfo
echo "<?php phpinfo(); ?>" | sudo tee /var/www/algebra_test/index.php >/dev/null

# Configure .htaccess for URL rewriting
sudo tee /var/www/algebra_test/.htaccess >/dev/null <<EOF
RewriteEngine On
RewriteRule ^test1/?$ /test2 [R=301,L]
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME}.php -f
RewriteRule ^([^/]+)/?$ \$1.php [L]
ErrorDocument 404 /404.html
EOF

sudo chown -R $USER:$USER /var/www/algebra_test

# Enable rewrite module
sudo a2enmod rewrite

# Reload Apache to apply changes
sudo systemctl reload apache2

# Install phpMyAdmin
sudo apt install -y phpmyadmin
sudo phpenmod -v ALL mbstring
sudo systemctl restart apache2

# Install Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

echo "Setup completed successfully!"
