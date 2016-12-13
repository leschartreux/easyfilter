#!/bin/bash


DIR_CONF="/opt/dnsmasq-filter"
[ ! -d $DIR_CONF ] && mkdir -p $DIR_CONF
CONF_FILE="$DIR_CONF/alcasar.conf"
private_ip_mask=`grep PRIVATE_IP= $CONF_FILE|cut -d"=" -f2`
private_ip_mask=${private_ip_mask:=192.168.182.1/24}
PRIVATE_IP=`echo $private_ip_mask | cut -d"/" -f1`			# ALCASAR LAN IP address
DIR_tmp="/tmp/blacklists"
FILE_tmp="/tmp/blacklists/filesfilter.txt"
FILE_ip_tmp="/tmp/blacklists/filesipfilter.txt"
DIR_DG="/opt/dnsmasq-filter/lists"
[ ! -d $DIR_DG ] && mkdir -p $DIR_DG
DIR_DG_BL="$DIR_DG/blacklists"
[ ! -d $DIR_DG_BL ] && mkdir -p $DIR_DG_BL
BL_CATEGORIES="$DIR_CONF/bl-categories"				# list of names of the 	BL categories
WL_CATEGORIES="$DIR_CONF/wl-categories"				#'	'		WL	'
BL_CATEGORIES_ENABLED="$DIR_CONF/bl-categories-enabled"		#	'	'	BL enabled categories
WL_CATEGORIES_ENABLED="$DIR_CONF/wl-categories-enabled"		#	'	'	WL enabled categories
DIR_SHARE="/opt/dnsmasq-filter/share"
[ ! -d $DIR_SHARE ] && mkdir -p $DIR_SHARE
DIR_DNS_BL="$DIR_SHARE/dnsmasq-bl"					# all the BL in the DNSMASQ format
DIR_DNS_WL="$DIR_SHARE/dnsmasq-wl"					# all the WL	'	'	'
DIR_DNS_BL_ENABLED="$DIR_SHARE/dnsmasq-bl-enabled"			# symbolic link to the dnsmasq	BL (only enabled categories)
DIR_DNS_WL_ENABLED="$DIR_SHARE/dnsmasq-wl-enabled"			#	'	'	'	WL	'	'	'
DNSMASQ_BL_CONF="/opt/dnsmasq-filter/dnsmasq-blackhole.conf"				# conf file of dnsmasq-blackhole
BL_SERVER="dsi.ut-capitole.fr"
SED="/bin/sed -i"

# enable/disable the BL & WL categories
function cat_choice (){
	rm -rf $DIR_DNS_BL_ENABLED $DIR_DNS_WL_ENABLED $DIR_IP_BL_ENABLED # cleaning for dnsmasq and iptables
	#$SED "/\.Include/d" $DIR_DG/bannedsitelist $DIR_DG/bannedurllist # cleaning for DG
	$SED "s?^[^#]?#&?g" $BL_CATEGORIES $WL_CATEGORIES # cleaning BL & WL categories file (comment all lines)
	mkdir $DIR_DNS_BL_ENABLED $DIR_DNS_WL_ENABLED $DIR_IP_BL_ENABLED 
	# process the file $BL_CATEGORIES with the choice of categories 
	for ENABLE_CATEGORIE in `cat $BL_CATEGORIES_ENABLED` 
	do
		$SED "/\/$ENABLE_CATEGORIE$/d" $BL_CATEGORIES 
		#$SED "1i\/etc\/dansguardian\/lists\/blacklists\/$ENABLE_CATEGORIE" $BL_CATEGORIES
		ln -s $DIR_DNS_BL/$ENABLE_CATEGORIE.conf $DIR_DNS_BL_ENABLED/$ENABLE_CATEGORIE
		# echo ".Include<$DIR_DG_BL/$ENABLE_CATEGORIE/domains>" >> $DIR_DG/bannedsitelist  # Blacklisted domains are managed by dnsmasq
		# echo ".Include<$DIR_DG_BL/$ENABLE_CATEGORIE/urls>" >> $DIR_DG/bannedurllist
	done
	sort +0.0 -0.2 $BL_CATEGORIES -o $FILE_tmp
	mv $FILE_tmp $BL_CATEGORIES
	# process the file $WL_CATEGORIES with the choice of categories 
	for ENABLE_CATEGORIE in `cat $WL_CATEGORIES_ENABLED` 
	do
		$SED "/\/$ENABLE_CATEGORIE$/d" $WL_CATEGORIES 
		#$SED "1i\/etc\/dansguardian\/lists\/blacklists\/$ENABLE_CATEGORIE" $WL_CATEGORIES
		ln -s $DIR_DNS_WL/$ENABLE_CATEGORIE.conf $DIR_DNS_WL_ENABLED/$ENABLE_CATEGORIE
	done
	sort +0.0 -0.2 $WL_CATEGORIES -o $FILE_tmp
	mv $FILE_tmp $WL_CATEGORIES
}
function bl_enable (){
	$SED "s/^reportinglevel =.*/reportinglevel = 3/g" /etc/dansguardian/dansguardian.conf
	if [ "$PARENT_SCRIPT" != "alcasar-conf.sh" ] # don't launch on install stage
	then
		service dansguardian restart
		service dnsmasq restart
		/usr/local/bin/alcasar-iptables.sh
	fi
}

function build_list()
{
	
	if [ ! -r $DIR_CONF/dnsmasq-filter.conf ]; then
		echo "Can't read $DIR_CONF/dnsmasq-filter.conf";
		exit 1;
	fi

	. $DIR_CONF/dnsmasq-filter.conf
	
	echo "Serveur de redirection : $PRIVATE_IP"

	echo -n "Toulouse BlackList migration process. Please wait : "
	if [ -f $DIR_tmp/blacklists.tar.gz ]
	then
		[ -d $DIR_DG_BL/ossi ] && mv -f $DIR_DG_BL/ossi $DIR_tmp
		rm -rf $DIR_DG_BL
		mkdir $DIR_DG_BL
		tar zxf $DIR_tmp/blacklists.tar.gz --directory=$DIR_DG/
		[ -d $DIR_tmp/ossi ] && mv -f $DIR_tmp/ossi $DIR_DG_BL/
	#			rm -rf $DIR_tmp
	fi
	rm -f $BL_CATEGORIES $WL_CATEGORIES $WL_CATEGORIES_ENABLED
	rm -rf $DIR_DNS_BL $DIR_DNS_WL $DIR_IP_BL
	touch $BL_CATEGORIES $WL_CATEGORIES $WL_CATEGORIES_ENABLED
	mkdir $DIR_DNS_BL $DIR_DNS_WL $DIR_IP_BL
	#		chown -R dansguardian:apache $DIR_DG $BL_CATEGORIES $WL_CATEGORIES $BL_CATEGORIES_ENABLED $WL_CATEGORIES_ENABLED
	#		chmod -R g+w $DIR_DG $BL_CATEGORIES $WL_CATEGORIES $BL_CATEGORIES_ENABLED $WL_CATEGORIES_ENABLED
	find $DIR_DG_BL/ -type f -name domains > $FILE_tmp # retrieve directory name where a domain file exist
	$SED "s?\/domains??g" $FILE_tmp # remove "/domains" suffix
	for dir_categorie in `cat $FILE_tmp` # create the blacklist and the whitelist files
	do
		categorie=`echo $dir_categorie|cut -d "/" -f6`
		categorie_type=`grep -A1 ^NAME:[$' '$'\t']*$categorie $DIR_DG_BL/global_usage | grep ^DEFAULT_TYPE | cut -d":" -f2 | tr -d " \t"`
		if [ "$categorie_type" == "white" ]
		then
			echo "$dir_categorie" >> $WL_CATEGORIES 
			echo `basename $dir_categorie` >> $WL_CATEGORIES_ENABLED  # by default all WL are enabled 
		else
			echo "$dir_categorie" >> $BL_CATEGORIES
		fi
	done

	#		rm -f $FILE_tmp
	# Verify that the enabled categories are effectively in the BL (need after an update of the BL)
	for ENABLE_CATEGORIE in `cat $BL_CATEGORIES_ENABLED` 
	do
		ok=`grep /$ENABLE_CATEGORIE$ $BL_CATEGORIES|wc -l`
		if [ $ok != "1" ] 
		then
			$SED "/^$ENABLE_CATEGORIE$/d" $BL_CATEGORIES_ENABLED
		fi
	done
	# Creation of DNSMASQ and Iptables BL and WL
	for LIST in $BL_CATEGORIES $WL_CATEGORIES	# for each list (bl and wl)
	do
		for PATH_FILE in `cat $LIST` # for each category
		do
			DOMAINE=`basename $PATH_FILE`
			echo -n "$DOMAINE, "
			if [ ! -f $PATH_FILE/urls ] # create 'urls' file if it doesn't exist
			then
				touch $PATH_FILE/urls
				#chown dansguardian:apache $PATH_FILE/urls
			fi
			$SED "s/\.\{2,10\}/\./g" $PATH_FILE/domains $PATH_FILE/urls # correct some syntax errors
			# retrieve the ip addresses for iptables
			egrep  "^([0-9]{1,3}\.){3}[0-9]{1,3}$" $PATH_FILE/domains > $FILE_ip_tmp
			# for dnsmask, remove IP addesses, accented characters and commented lines.
			egrep  -v "^([0-9]{1,3}\.){3}[0-9]{1,3}$" $PATH_FILE/domains > $FILE_tmp
			$SED "/[äâëêïîöôüû]/d" $FILE_tmp
			$SED "/^#.*/d" $FILE_tmp
			# adapt to the dnsmasq syntax
			$SED "s?.*?address=/&/$PRIVATE_IP?g" $FILE_tmp 
			if [ "$LIST" == "$BL_CATEGORIES" ]
			then
				mv $FILE_tmp $DIR_DNS_BL/$DOMAINE.conf
	#					mv $FILE_ip_tmp $DIR_IP_BL/$DOMAINE
			else
				mv $FILE_tmp $DIR_DNS_WL/$DOMAINE.conf
			fi
		done
	done
}

Usage="Usage : dnsmasq-filter --download | --build | --update"
nb_args=$#
args=$1

case $args in
	-download | --download)
		rm -rf /tmp/con_ok.html
		`/usr/bin/curl $BL_SERVER -# -o /tmp/con_ok.html`
		if [ ! -e /tmp/con_ok.html ]
		then
			echo "Erreur : le serveur de blacklist ($BL_SERVER) n'est pas joignable"
		else 
			rm -rf /tmp/con_ok.html $DIR_tmp
			mkdir $DIR_tmp
			wget -P $DIR_tmp http://$BL_SERVER/blacklists/download/blacklists.tar.gz
			md5sum $DIR_tmp/blacklists.tar.gz | cut -d" " -f1 > $DIR_tmp/md5sum
			chown -R apache:apache $DIR_tmp
		fi
		;;		

	# Adapt Toulouse BL to ALCASAR architecture (dnsmasq + DG + iptables)
	-build | --build)
		build_list
		;;
	
	-update | --update)
		cat_choice
		;;
	
	*)
		echo $Usage
		exit 1;
		;;
esac
#rm -f $FILE_tmp $FILE_ip_tmp
echo

echo 
			
