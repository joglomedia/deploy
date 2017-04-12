#!/bin/sh
# simpleLNMPinstaller.sh - Simple LNMP Installer remover for Ubuntu OS
#	- Nginx 1.6
#	- MariaDB 10.0.15
#	- PHP 5.5
#	- Memcached
#	- PhpMyAdmin
#	- ionCube Loader
# Min requirement	: Ubuntu 14.04
# Build Date		: 13/11/2015
# Author			: MasEDI.Net (hi@masedi.net)

# Make sure only root can run this installer script
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root..." 1>&2
	exit 1
fi

clear

# Variables
arch=$(uname -p)

# Stop Nginx web server
service nginx stop

# Stop php5-fpm server
service php5-fpm stop

# Stop MariaDB mysql server
service mysql stop

# Stop Memcached server
service memcached stop

# Remove Nginx - PHP5 - MariaDB - PhpMyAdmin
apt-get remove -y nginx-custom

echo ""
echo -n "Completely remove Nginx configuration files (This action is not reversible)? (y/n): "
read rmngxconf
if [ "${rmngxconf}" = "y" ]; then
	echo "All your Nginx configuration files deleted..."
	sleep 2
	#rm -fr /etc/nginx
	# rm nginx-cache
	#rm -fr /var/run/nginx-cache
	# rm nginx html
	#rm -fr /usr/share/nginx
fi

apt-get --purge remove -y php-pear php5-fpm php5-cli php5-mysql php5-curl php5-geoip php5-gd php5-intl php5-mcrypt php5-memcache php5-imap php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl spawn-fcgi geoip-database snmp memcached

echo ""
echo -n "Completely remove PHP-FPM configuration files (This action is not reversible)? (y/n): "
read rmfpmconf
if [ "${rmfpmconf}" = "y" ]; then
	echo "All your PHP-FPM configuration files deleted..."
	sleep 2
	#rm -fr /etc/php5
fi

apt-get remove -y mariadb-server-10.1 mariadb-client-10.1 mariadb-server-core-10.1 mariadb-common mariadb-server libmariadbclient18 mariadb-client-core-10.1

echo ""
echo -n "Completely remove MariaDB SQL database and configuration files (This action is not reversible)? (y/n): "
read rmsqlconf
if [ "${rmsqlconf}" = "y" ]; then
	echo "All your SQL database and configuration files deleted..."
	sleep 2
	#rm -fr /etc/mysql
	#rm -fr /var/lib/mysql
fi

#apt-get remove phpmyadmin
apt-get autoremove -y

# Remove ioncube
rm -fr /usr/local/ioncube


clear
echo "#==========================================================================#"
echo "# Thanks for trying SimpleLNMPInstaller... Sad to see you Go ;(            #"
echo "# Found any bugs / errors / suggestions? please let me know....            #"
echo "# If this script useful, don't forget to buy me a coffee or milk... :D     #"
echo "# My PayPal is always open for donation, send your tips here hi@masedi.net #"
echo "#                                                                          #"
echo "# (c) 2015 - MasEDI.Net - http://masedi.net ;)                             #"
echo "===========================================================================#"
