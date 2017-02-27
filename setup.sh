#!/bin/bash
. settings.debian
#bind command
		
do_setup()
{
	mkdir -p $INSTALLDIR
	mkdir $CONFDIR
	
	echo "***********************************************"
	echo "copying files"
	cp src/* $INSTALLDIR
	cp -R src/www $INSTALLDIR
	cp src/etc/*.conf $CONFDIR
	cp settings.freebsd $CONFDIR
	echo "OK"
	echo
	echo "We need a host IP to redirect blacklisted site to"
	echo "Typically a web server with a simple index.html file on root directory which will be displayed on each hit"
   	read -p "What is the IP to redirect balcklisted hosts ?" priv_ip
   	echo "PRIVATE_IP=$priv_ip" > $BIND_REDIR
   	echo "CNAME_REDIR=redir.local" >> $BIND_REDIR
   	echo OK
   	
   	echo "**********************************************"
 	
	 while true; do
	    read -p "Do you wish to start dedicated web server on boot (you need to change webconfigurator default port)  ?" yn
	    case $yn in
	        [Yy]* ) 
	        	cp src/rc.d/nginx_easyfilter.sh $RCDIR
				chmod u+x $RCDIR/nginx_easyfilter.sh;;
	        [Nn]* )
	        	if [ -x $RCDIR/nginx_easyfilter.sh ]; then
	        		rm $RCDIR/nginx_easyfilter.sh
	        	fi
	        	exit;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done
 
   	
}

if [ $USER != "root" ]; then
	echo "You must be root to setup"
	exit 1
fi

if [ ! -x $NAMED ]; then
	echo "bind is not installed."
	echo "try apt-get instal bind9 before for pfSense use"
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

