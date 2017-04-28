#!/usr/bin/env bash

# simpleLNMPinstaller.sh is a Simple LNMP Installer for Ubuntu
#	- Nginx 1.10
#	- MariaDB 10.1 (MySQL drop-in replacement)
#	- PHP 5.6/7.0/7.1
#	- Zend OpCache 7.0.3
#	- Memcached 1.4.14
#	- ionCube Loader
#	- SourceGuardian Loader
#	- Adminer (PhpMyAdmin replacement)
# Min requirement	: GNU/Linux Ubuntu 14.04
# Last Update		: 05/03/2017
# Author			: MasEDI.Net (hi@masedi.net)
# Version 			: 1.2.0

# Make sure only root can run this installer script
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root..." 1>&2
	exit 1
fi

# Make sure this script only run on Ubuntu install
if [ ! -f "/etc/lsb-release" ]; then
	echo "This installer only work on Ubuntu server..." 1>&2
	exit 1
else
	# Variables
	arch=$(uname -p)
	IPAddr=$(hostname -i)
	. /etc/lsb-release
fi

function header_msg {
clear
cat <<- _EOF_
#========================================================================#
# SimpleLNMPIntaller v1.2.0-dev for Ubuntu Server, Written by MasEDI.Net #
#========================================================================#
#     A small tool to install Nginx + MariaDB (MySQL) + PHP on Linux     #
#                                                                        #
#       For more information please visit http://masedi.net/tools/       #
#========================================================================#
_EOF_
sleep 1
}
header_msg

### CLONE LNMP CUSTOM CONFIGS ###

echo "Clone LNMP installer scripts..."

# Clone the deployment server config
git clone https://github.com/joglomedia/deploy.git deploy

# Fix file permission
find deploy -type d -print0 | xargs -0 chmod 755
find deploy -type f -print0 | xargs -0 chmod 644

# change to main installer directory
cd deploy

echo "Uninstall existing Webserver (Apache) and MySQL server..."

# Remove Apache2 & mysql services if exist
killall apache2 && killall mysql
apt-get --purge remove -y apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-client mysql-server mysql-common
apt-get autoremove -y


### ADD REPOS ###
echo "Adding repositories..."

# Nginx custom with ngx cache purge
if [[ "$DISTRIB_RELEASE" = "16.04" || "$DISTRIB_RELEASE" = "18" ]]; then
	# Ubuntu release 16.04, LinuxMint 18
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3050AC3CD2AE6F03
	sh -c "echo 'deb http://download.opensuse.org/repositories/home:/rtCamp:/EasyEngine/xUbuntu_16.04/ /' >> /etc/apt/sources.list.d/nginx-xenial.list"
	# Add nginx service to systemd
	#wget --no-check-certificate https://gist.githubusercontent.com/joglomedia/3bb43ee9b17262f07dbe805aac3aee15/raw/d90c02a31c2873a0340b82554a4ec571568eb202/nginx.service -O /lib/systemd/system/nginx.service
else
	# Ubuntu release 14.04
	# https://rtcamp.com/wordpress-nginx/tutorials/single-site/fastcgi-cache-with-purging/
	add-apt-repository ppa:rtcamp/nginx
fi

# Add PHP (5.6/7.0/7.1 latest stable) from Ondrej's repo
# Source: https://launchpad.net/~ondrej/+archive/ubuntu/php
add-apt-repository ppa:ondrej/php

# Add MariaDB repo from MariaDB repo configuration tool
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
touch /etc/apt/sources.list.d/MariaDB.list
cat > /etc/apt/sources.list.d/MariaDB.list <<EOL
# MariaDB 10.1 repository list - created 2014-11-30 14:04 UTC
# http://mariadb.org/mariadb/repositories/
deb [arch=amd64,i386] http://ftp.osuosl.org/pub/mariadb/repo/10.1/ubuntu trusty main
deb-src http://ftp.osuosl.org/pub/mariadb/repo/10.1/ubuntu trusty main
EOL

echo "Update repository and install pre-requisite..."

# Update repos
apt-get update -y

# Install pre-requirements
apt-get install -y software-properties-common python-software-properties build-essential git unzip curl openssl snmp spawn-fcgi fcgiwrap geoip-database


### INSTALL Nginx ###

echo "Installing Nginx webserver..."

# Install Nginx custom
apt-get install -y --allow-unauthenticated nginx-custom

# Copy custom Nginx Config
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
cp -f nginx/nginx.conf /etc/nginx/
cp -f nginx/fastcgi_cache /etc/nginx/
cp -f nginx/fastcgi_https_map /etc/nginx/
cp -f nginx/fastcgi_params /etc/nginx/
cp -f nginx/http_cloudflare_ips /etc/nginx/
cp -f nginx/http_proxy_ips /etc/nginx/
cp -f nginx/proxy_cache /etc/nginx/
cp -f nginx/proxy_params /etc/nginx/
cp -f nginx/upstream.conf /etc/nginx/
cp -fr nginx/conf.vhost/ /etc/nginx/
cp -fr nginx/ssl/ /etc/nginx/
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
cp -f nginx/sites-available/default /etc/nginx/sites-available/
cp -f nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-available/
cp -f nginx/sites-available/adminer.conf /etc/nginx/sites-available/
cp -f nginx/sites-available/sample-wordpress.dev.conf /etc/nginx/sites-available/
cp -f nginx/sites-available/sample-wordpress-ms.dev.conf /etc/nginx/sites-available/
cp -f nginx/sites-available/ssl.sample-site.dev.conf /etc/nginx/sites-available/
unlink /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/01-default

# Nginx cache directory
mkdir /var/cache/nginx/
mkdir /var/cache/nginx/fastcgi_temp
mkdir /var/cache/nginx/proxy_temp

# Check IP Address
IPAddr=$(curl -s http://ipecho.net/plain)
# Make default server accessible from IP address
sed -i "s@localhost.localdomain@$IPAddr@g" /etc/nginx/sites-available/default

# Restart Nginx server
service nginx restart

### END Of Nginx Part ###


### INSTALL PHP ###
echo "Installing PHP..."
echo "Which version of PHP you want to install (default is 5.6)?
Supported PHP version:
1). PHP 5.6 (old stable)
2). PHP 7.0 (latest stable)
3). PHP 7.1 (latest stable)

"
echo -n "Select your option: "
read phpveropt
if [ "${phpveropt}" = "3" ]; then
	PHPVer="7.1"
	PHPkgs="php7.1 php7.1-common php7.1-fpm php7.1-cli php7.1-mysql php7.1-curl php7.1-gd php7.1-intl php7.1-json php7.1-mcrypt php7.1-mbstring php7.1-imap php7.1-pspell php7.1-pspell php7.1-recode php7.1-snmp php7.1-sqlite3 php7.1-tidy php7.1-readline php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-gmp php7.1-opcache php7.1-zip"
elif [ "${phpveropt}" = "2" ]; then
	PHPVer="7.0"
	PHPkgs="php7.0 php7.0-common php7.0-fpm php7.0-cli php7.0-mysql php7.0-curl php7.0-gd php7.0-intl php7.0-json php7.0-mcrypt php7.0-mbstring php7.0-imap php7.0-pspell php7.0-pspell php7.0-recode php7.0-snmp php7.0-sqlite3 php7.0-tidy php7.0-readline php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-gmp php7.0-opcache php7.0-zip"
else
	PHPVer="5.6"
	PHPkgs="php5.6 php5.6-common php5.6-fpm php5.6-cli php5.6-mysql php5.6-curl php5.6-gd php5.6-intl php5.6-json php5.6-mcrypt php5.6-mbstring php5.6-imap php5.6-pspell php5.6-pspell php5.6-recode php5.6-snmp php5.6-sqlite3 php5.6-tidy php5.6-readline php5.6-xml php5.6-xmlrpc php5.6-xsl php5.6-gmp php5.6-opcache php5.6-zip"
fi

# Install PHP packages
apt-get install -y $PHPkgs php-geoip php-pear pkg-php-tools

echo "Installing PHP loaders (ionCube & Source Guardian)..."

# Install PHP loaders
mkdir /usr/lib/php/loaders

# Install ionCube Loader
if [ "$arch" = "x86_64" ]; then
	wget "http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
	tar xzf ioncube_loaders_lin_x86-64.tar.gz
	rm -f ioncube_loaders_lin_x86-64.tar.gz
else
	wget "http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz"
	tar xzf ioncube_loaders_lin_x86.tar.gz
	rm -f ioncube_loaders_lin_x86.tar.gz
fi
mv ioncube /usr/lib/php/loaders/

# Enable ionCube Loader extension
cat > /etc/php/${PHPVer}/mods-available/ioncube.ini <<EOL
[ioncube]
zend_extension=/usr/lib/php/loaders/ioncube/ioncube_loader_lin_${PHPVer}.so
EOL
ln -s /etc/php/${PHPVer}/mods-available/ioncube.ini /etc/php/${PHPVer}/fpm/conf.d/05-ioncube.ini
ln -s /etc/php/${PHPVer}/mods-available/ioncube.ini /etc/php/${PHPVer}/cli/conf.d/05-ioncube.ini

# Install SourceGuardian
mkdir sourceguardian
cd sourceguardian
if [ "$arch" = "x86_64" ]; then
	wget "http://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz"
	tar xzf loaders.linux-x86_64.tar.gz
	rm -f loaders.linux-x86_64.tar.gz
else
	wget "http://www.sourceguardian.com/loaders/download/loaders.linux-x86.tar.gz"
	tar xzf loaders.linux-x86.tar.gz
	rm -f loaders.linux-x86.tar.gz
fi
cd ../
mv sourceguardian /usr/lib/php/loaders/

# Enable SourceGuardian extension
cat > /etc/php/${PHPVer}/mods-available/sourceguardian.ini <<EOL
[sourceguardian]
zend_extension=/usr/lib/php/loaders/sourceguardian/ixed.${PHPVer}.lin
EOL
ln -s /etc/php/${PHPVer}/mods-available/sourceguardian.ini /etc/php/${PHPVer}/fpm/conf.d/05-sourceguardian.ini
ln -s /etc/php/${PHPVer}/mods-available/sourceguardian.ini /etc/php/${PHPVer}/cli/conf.d/05-sourceguardian.ini

### Install Zend OpCache ###
# Make sure Zend OpCache not yet installed by default
OPCACHEPATH=$(find /usr/lib/php/${PHPVer}/ -name 'opcache.so')
if [ -z "$OPCACHEPATH" ]; then
    pecl install zendopcache-7.0.3
    OPCACHEPATH=$(find /usr/lib/php/${PHPVer}/ -name 'opcache.so')
    # Enable Zend OpCache module
    ln -s /etc/php/${PHPVer}/mods-available/opcache.ini /etc/php/${PHPVer}/fpm/conf.d/05-opcache.ini
    ln -s /etc/php/${PHPVer}/mods-available/opcache.ini /etc/php/${PHPVer}/cli/conf.d/05-opcache.ini

	# Add custom settings for Zend OpCache
	cat > /etc/php/${PHPVer}/mods-available/opcache.ini <<EOL
	; configuration for php ZendOpcache module
	; priority=05
	zend_extension=${OPCACHEPATH}

	; Tunning/Optimization settings
	opcache.enable=1
	opcache.enable_cli=1
	opcache.cache_full=1
	opcache.memory_consumption=128
	opcache.interned_strings_buffer=16
	opcache.max_accelerated_files=10000
	opcache.max_wasted_percentage=5
	opcache.save_comments=0
	opcache.load_comments=0
	opcache.fast_shutdown=1
	opcache.max_file_size=5M

	;;; Following can be commented for production server ;;;

	; Setting regarding opcode cache expiration
	; If disabled, you must reset OPcache manually
	opcache.validate_timestamps=1
	; how often (in seconds) should the code cache expire and check if your code has changed
	opcache.revalidate_freq=60

	; Additional setting for Frontend Script Cache like WordPress + Plugin cache
	opcache.consistency_checks=1
	EOL
fi

# PHP Setting + Optimization #
echo "Optimizing PHP configuration..."

# Copy custom php.ini
mv /etc/php/${PHPVer}/fpm/php.ini /etc/php/${PHPVer}/fpm/php.ini.old
cp php/${PHPVer}/fpm/php.ini /etc/php/${PHPVer}/fpm/

# Copy the optimized-version of php-fpm config file
mv /etc/php/${PHPVer}/fpm/php-fpm.conf /etc/php/${PHPVer}/fpm/php-fpm.conf.old
cp php/${PHPVer}/fpm/php-fpm.conf /etc/php/${PHPVer}/fpm/

# Copy the optimized-version of php5-fpm default pool
mv /etc/php/${PHPVer}/fpm/pool.d/www.conf /etc/php/${PHPVer}/fpm/pool.d/www.conf.old
cp php/${PHPVer}/fpm/pool.d/www.conf /etc/php/${PHPVer}/fpm/pool.d/

# Fix cgi.fix_pathinfo
sed -i "s/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/${PHPVer}/fpm/php.ini

# Restart Php5-fpm server
service php5-fpm restart

echo "Installing Memcached and Php memcached module..."

# Install memcached?
apt-get install -y memcached php-memcached php-memcache

# Custom Memcache setting
sed -i 's/-m 64/-m 128/g' /etc/memcached.conf
cat > /etc/php/${PHPVer}/mods-available/memcache.ini <<EOL
; uncomment the next line to enable the module
extension=memcache.so

[memcache]
memcache.dbpath="/var/lib/memcache"
memcache.maxreclevel=0
memcache.maxfiles=0
memcache.archivememlim=0
memcache.maxfilesize=0
memcache.maxratio=0
; custom setting for WordPress + W3TC
session.bak_handler = memcache
session.bak_path = "tcp://127.0.0.1:11211"
EOL

# Restart memcached daemon
service memcached restart

### END OF PHP Part ###


### INSTALL MySQL DATABASE ###
echo "Installing MariaDB server..."

# Install MariaDB
apt-get install -y mariadb-server-10.1 mariadb-client-10.1 mariadb-server-core-10.1 mariadb-common mariadb-server libmariadbclient18 mariadb-client-core-10.1

# Fix MySQL error?
# Ref: https://serverfault.com/questions/104014/innodb-error-log-file-ib-logfile0-is-of-different-size
#service mysql stop
#mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
#mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak
#service mysql start

# MySQL Secure Install
mysql_secure_installation

# Restart MariaDB MySQL server
service mysql restart

### END OF MySQL ###


### INSTALL ADDSON ###
echo "Installing Adds on..."

# Update local time
apt-get install -y ntpdate
ntpdate -d cn.pool.ntp.org

# Install Postfix mail server
apt-get install -y postfix

# Install Nginx Vhost Creator
cp -f scripts/ngxvhost.sh /usr/local/bin/ngxvhost
chmod ugo+x /usr/local/bin/ngxvhost

# Install Web-viewer Tools
mkdir /usr/share/nginx/html/tools/

# Install Zend OpCache Web Viewer
wget --no-check-certificate https://raw.github.com/rlerdorf/opcache-status/master/opcache.php -O /usr/share/nginx/html/tools/opcache.php

# Install Memcache Web-based stats
#http://blog.elijaa.org/index.php?pages/phpMemcachedAdmin-Installation-Guide
git clone https://github.com/elijaa/phpmemcachedadmin.git /usr/share/nginx/html/tools/phpMemcachedAdmin/

# Install Adminer for Web-based MySQL Administration Tool
mkdir /usr/share/nginx/html/tools/adminer/
wget http://sourceforge.net/projects/adminer/files/latest/download?source=files -O /usr/share/nginx/html/tools/adminer/index.php

# Install PHP Info
cat > /usr/share/nginx/html/tools/phpinfo.php <<EOL
<?php phpinfo(); ?>
EOL

### Install Siege Benchmark ###
#git clone https://github.com/JoeDog/siege.git
#cd siege
#./configure
#make && make install
#cd ../

### END OF ADDSON ###


### FINAL STEP ###
# Cleaning up all build dependencies hanging around on production server?
#rm -fr deploy
apt-get autoremove -y

clear
echo "#==========================================================================#"
echo "# Thanks for installing LNMP stack using SimpleLNMPInstaller...            #"
echo "# Found any bugs / errors / suggestions? please let me know....            #"
echo "# If this script useful, don't forget to buy me a coffee or milk... :D     #"
echo "# My PayPal is always open for donation, send your tips here hi@masedi.net #"
echo "#                                                                          #"
echo "# (c) 2015-2017 - MasEDI.Net - http://masedi.net ;)                        #"
echo "#==========================================================================#"

