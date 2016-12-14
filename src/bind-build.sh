#!/bin/sh
#build RPZ zone with bl enabled categories
CONFDIR="/usr/local/etc/easyfilter"
. $CONFDIR/settings.freebsd

make_categ() {
	egrep  -v "^([0-9]{1,3}\.){3}[0-9]{1,3}$" blacklists/$1/domains > $FILE_TMP
	$SED "/[äâëêïîöôüû_]/d" $FILE_TMP
	$SED "/^#.*/d" $FILE_TMP
	$SED "s/^\.//g" $FILE_TMP
	$SED "s/^\*\.\./*./g" $FILE_TMP
	$SED "s?.*?& A $PRIVATE_IP \\${CR}*.& A $PRIVATE_IP?g" $FILE_TMP
	mv $FILE_TMP $BIND_ROOT$BIND_DIR/$1.conf
}


#get private IP to redirect
. $BIND_REDIR
cd $BLTMPDIR
DB_FILE="$BIND_ROOT$ZONE_FILE"
DB_DIR="$BIND_ROOT$BIND_DIR"

if [ "X$1" = "X--force" ]; then
	rm -rf $DB_DIR
fi
if [ ! -d $DB_DIR ]; then
	mkdir -p $DB_DIR
fi


echo "\$TTL 1D" >  $DB_FILE
echo "@	SOA	easyfilter.local.	root.easyfilter.local ( 1 2h 3m 30d 1h)" >>  $DB_FILE
echo "	NS easyfilter.local." >>  $DB_FILE
echo "easyfilter.local. IN A $PRIVATE_IP" >>  $DB_FILE
echo "" >>  $DB_FILE
echo "$CNAME_REDIR A $PRIVATE_IP" >> $DB_FILE

for categ in `cat $BLCATEGORIES_E`;
do
	echo $categ	
	if [ -f blacklists/$categ/domains ] && [ ! -f $DB_DIR/$categ.conf ]; then
		make_categ $categ
	fi
	

	echo "\$INCLUDE $BIND_DIR/$categ.conf" >> $DB_FILE
	

done

cat /dev/null > $BIND_ROOT/$BIND_SAFESEARCH
cat /dev/null > $BIND_SAFESEARCH_TMP
for se in `cat $SAFESEARCH_ENABLED`
do
	echo $se
	$INSTALLDIR/safesearch.sh $se
done

if [ -f $BIND_SAFESEARCH_TMP ]
then
	cp $BIND_SAFESEARCH_TMP $BIND_ROOT/$BIND_SAFESEARCH
	echo "\$INCLUDE $BIND_SAFESEARCH" >> $DB_FILE
fi

chown bind $DB_FILE
chown -R bind $DB_DIR