#!/bin/bash
clear
echo "#######################################"
echo "## ##"
echo "## A D D U S E R ##"
echo "## ##"
echo "#######################################"

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: Please use root to add new user."
    exit 1
fi

echo -n "Add new user? (y/n): "
read tambah

while [ "${tambah}" != "n" ]
do
echo -n "Username: "
read namauser
echo -n "Password: "
read katasandi

echo -n "Expire date (yyyy-mm-dd): "
read expired
if [ "${expired}" != "unlimited" ]; then
	setexpiredate="-e $expired"
else
	setexpiredate=""
fi

echo -n "Allow shell access? (y/n): "
read aksessh
if [ "${aksessh}" = "y" ]; then
	setusershell="/bin/bash"
else
	setusershell="/bin/false"
fi

echo -n "Create home directory? (y/n): "
read enablehomedir
if [ "${enablehomedir}" = "y" ]; then
	sethomedir="-d /home/${namauser} -m"
else
	sethomedir="-d /home/${namauser} -M"
fi

echo -n "Set users group? (y/n): "
read setgroup
if [ "${setgroup}" = "y" ]; then
	$setgroup = "-g users"
else
	$setgroup = ""
fi

useradd $sethomedir $setexpiredate $setgroup -s $setusershell $namauser
echo "${namauser}:${katasandi}" | chpasswd

clear
echo "#######################################"
echo "## ##"
echo "## A D D U S E R ##"
echo "## ##"
echo "#######################################"

echo -n "Add another user? (y/n): "
read tambah
done

