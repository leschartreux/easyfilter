echo ";safesearch for google" > safesearch.conf
for i in `cat googlecountry`
do
	g=`echo $i | sed 's/^.//'`
	echo $g CNAME forcesafesearch.google.com. >> safesearch.conf;
	echo "*.$g" CNAME forcesafesearch.google.com. >> safesearch.conf 
done
