#!/bin/sh
CONFDIR="/usr/local/etc/easyfilter"
. "$CONFDIR/settings.freebsd"
echo confid=$CONFDIR $BLTMPDIR

download_bl()	
{	
	mkdir $BLTMPDIR
	curl -o $BLTMPDIR/blacklists.tar.gz http://$BL_SERVER/blacklists/download/blacklists.tar.gz 
	md5 $BLTMPDIR/blacklists.tar.gz | cut -d" " -f4 > $BLTMPDIR/md5sum
}		

get_categ()
{

	curdir=$1
	cd $BLTMPDIR
	tar xzf blacklists.tar.gz
	cat /dev/null > $TMPCATEG
	cat /dev/null > $BLCATEGORIES
	for f in `ls blacklists`
	do
		if [ -d blacklists/$f ]; then
			
			n=$(basename $f)
			#rewrite categories list
			echo $n >> $BLCATEGORIES
			#pepare checkbox doialog.
			#pre_check already selected categories from previous launch
			grep $n $BLCATEGORIES_E >/dev/null 2>&1
			if [ $? -eq 0 ]
			then
				#echo "$n trouver"
				echo -n " $n $n on" >> $TMPCATEG
			else
				echo -n " $n $n off" >> $TMPCATEG
			fi
		fi
	done
	cd $curdir
	cat $TMPCATEG
}

get_sl()
{
	cat /dev/null > $TMPCATEG
	while read l
	do
		se=`echo $l | cut -d" " -f1`
		grep $se $SAFESEARCH_ENABLED >/dev/null 2>&1
		if [ $? -eq 0 ]
		then
			echo -n "$l on " >> $TMPCATEG
		else
			echo -n "$l off " >> $TMPCATEG
		fi
	done < $SEARCHENGINE_LIST 
	cat $TMPCATEG
}

echo "Downloading categories...."
cd $INSTALLDIR
if [ ! -f $BLTMPDIR/blacklists.tar.gz ]; then
	download_bl
fi
echo "OK"

echo "***************************************************************************"
echo "Build categories list"
dir=`pwd`
CATEG=$(get_categ $dir)
echo $CATEG

 dialog --no-cancel --checklist "Please choose categories to filter :" 20 78 13 $CATEG 2>  $TMPCATEG_CHECKED
 cat /dev/null > $BLCATEGORIES_E
 for b in `cat $TMPCATEG_CHECKED`
 do
 	echo $b | sed -e 's/^"//' -e 's/"$//'  >> $BLCATEGORIES_E
 done
 
 
echo "***************************************************************************"
echo "Build safesearch engines list"
SLL=$(get_sl)

dialog --no-cancel --checklist "Please choose search engines :" 20 75 10 $SLL 2>$TMPSE_CHECKED 
cat /dev/null > $SAFESEARCH_ENABLED
for b in `cat $TMPSE_CHECKED`
do
 	echo $b | sed -e 's/^"//' -e 's/"$//'  >> $SAFESEARCH_ENABLED
done
 