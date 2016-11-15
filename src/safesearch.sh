#!/bin/bash
bind_dir="/usr/share/easyfilter/bind-filter"

if [ ! -f supported_comains ]; then
	wget https://www.google.com/supported_domains
fi

echo ";safesearch for google" > safesearch.conf
for i in `cat supported_domains`
do
	g=`echo $i | sed 's/^.//'`
	echo $g CNAME forcesafesearch.google.com. >> safesearch.conf;
	echo "*.$g" CNAME forcesafesearch.google.com. >> safesearch.conf 
done

echo >> safesearch.conf
echo ";safe search for Youtube" >> safesearch.conf
for i in `cat youtube_domains`
do
    echo $i CNAME restrictmoderate.youtube.com. >> safesearch.conf
done

echo >> safesearch.conf
echo ";safe search for Qwant" >> safesearch.conf
echo "api.qwant.com CNAME safeapi.qwant.com." >> safesearch.conf

echo >> safesearch.conf
echo ";safesearch for Bing" >> safesearch.conf
echo "www.bing.com CNAME strict.bing.com." >> safesearch.conf

cp safesearch.conf $bind_dir
    
