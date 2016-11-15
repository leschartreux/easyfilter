#build RPZ zone with bl enabled categories
tmpdir="/tmp/blacklists"
blfile="$tmpdir/blacklists.tar.gz"
confdir="/etc/easyfilter"
conf_file="$confdir/bind-filter.conf"
bl_categories_enabled="$confdir/bl-categories-enabled"
zone_file="/var/cache/bind/db.easyfilter";
FILE_tmp="$tmpdir/categ.conf"
SED="sed -i"
bind_dir="/usr/share/easyfilter/bind-filter"

echo "\$TTL 1D" >  $zone_file
echo "@	SOA	easyfilter.localdomain.org.	root.localdomain.org ( 1 2h 3m 30d 1h)" >> $zone_file
echo "	NS easyfilter.leschartreux.org." >> $zone_file

cd $tmpdir
tar xzf $blfile
. $conf_file

for categ in `cat $bl_categories_enabled`;
do
	echo $categ	
	if [ -f blacklists/$categ/domains ] && [ ! -f $bind_dir/$categ.conf ]; then
		egrep  -v "^([0-9]{1,3}\.){3}[0-9]{1,3}$" blacklists/$categ/domains > $FILE_tmp
                $SED "/[äâëêïîöôüû_]/d" $FILE_tmp
                $SED "/^#.*/d" $FILE_tmp
                $SED "s?.*?& A $PRIVATE_IP \n*.& A $PRIVATE_IP?g" $FILE_tmp
		mv $FILE_tmp $bind_dir/$categ.conf
	fi

	echo "\$INCLUDE $bind_dir/$categ.conf" >> $zone_file
	

done

if [ -f $bind_dir/safesearch.conf ]
then
	echo "\$INCLUDE $bind_dir/safesearch.conf" >> $zone_file
fi

chown bind:bind $zone_file
chown -R bind:bind $bind_dir

