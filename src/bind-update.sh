BLDIR="/tmp/blacklists/"
TMPCATEG="$BLDIR/categories.chk"
CONFDIR="/etc/easyfilter"
BLCATEGORIES="$CONFDIR/bl-categories"
BLCATEGORIES_E="$CONFDIR/bl-categories-enabled"

function get_categ()
{

	curdir=$1
	cd /tmp/blacklists/
	tar xzf blacklists.tar.gz
	cat /dev/null > $TMPCATEG
	cat /dev/null > $BLCATEGORIES
	for f in `ls $BLDIR/blacklists`
	do
		if [ -d $BLDIR/blacklists/$f ]; then
			
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

echo "Downloading categories...."
cd $INSTALLDIR
if [ ! -f /tmp/blacklists/blacklists.tar.gz ]; then
	./dnsmasq-filter.sh  --download
fi
echo "OK"

echo "***************************************************************************"
echo "Build categories list"
dir=`pwd`
CATEG=$(get_categ $dir)
echo $CATEG

 BL=$(whiptail --checklist "Please choose categories to filter :" 20 78 13 $CATEG 3>&1 1>&2 2>&3)
 cat /dev/null > $BLCATEGORIES_E
 for b in $BL
 do
 	sed -e 's/^"//' -e 's/"$//' <<<"$b" >> $BLCATEGORIES_E
 done
 
