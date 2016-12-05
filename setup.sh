#!/bin/bash

#bind command
NAMED="/usr/sbin/named"
INSTALLDIR="/usr/local/easyfilter"
CONFDIR="/etc/easyfilter"
BIND_REDIR="$CONFDIR/bind-filter.conf"


	
	
function do_setup
{
	mkdir -p $INSTALLDIR
	mkdir $CONFDIR
	
	echo "***********************************************"
	echo "copying files"
	cp src/* $INSTALLDIR
	cp src/etc/*.conf $CONFDIR
	echo "OK"
	echo
	echo "We need a host IP to redirect blacklisted site to"
	echo "Typically a web server with a simple index.html file on root directory which will be displayed on each hit"
   	read -p "What is the IP to redirect balcklisted hosts ?" priv_ip
   	echo "PRIVATE_IP=$priv_ip" > $BIND_REDIR
   	echo OK
   	
   	echo "**********************************************"
 
   	
}

if [ $EUID -ne 0 ]; then
	echo "You must be root to setup"
	exit 1
fi

if [ ! -x $NAMED ]; then
	echo "bind is not installed."
	echo "try apt-get instal bind9 before"
	exit 1
fi


while true; do
    read -p "Do you wish to install this program?" yn
    case $yn in
        [Yy]* ) do_setup; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

