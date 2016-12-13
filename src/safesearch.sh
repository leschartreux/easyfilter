#!/bin/sh
CONFDIR="/usr/local/etc/easyfilter"
. $CONFDIR/settings.freebsd
. $BIND_REDIR


case $1 in
google)
	if [ ! -f $GOOGLE_DOMAINS_TMP ]; then
		curl -o $GOOGLE_DOMAINS_TMP https://www.google.com/supported_domains
	fi

	echo ";safesearch for google" >> $BIND_SAFESEARCH_TMP
	for i in `cat $GOOGLE_DOMAINS_TMP`
	do
		g=`echo $i | sed 's/^.//'`
		echo $g CNAME forcesafesearch.google.com. >> $BIND_SAFESEARCH_TMP;
		echo "*.$g" CNAME forcesafesearch.google.com. >> $BIND_SAFESEARCH_TMP 
	done
	;;
	
youtube)
	echo >> $BIND_SAFESEARCH_TMP
	echo ";safe search for Youtube" >> $BIND_SAFESEARCH_TMP
	for i in `cat $YOUTUBE_DOMAINS`
	do
    	echo $i CNAME restrictmoderate.youtube.com. >> $BIND_SAFESEARCH_TMP
	done
	;;

qwant)
	echo >> $BIND_SAFESEARCH_TMP
	echo ";safe search for Qwant" >> $BIND_SAFESEARCH_TMP
	echo "api.qwant.com CNAME safeapi.qwant.com." >> $BIND_SAFESEARCH_TMP
	;;

bing)
	echo >> $BIND_SAFESEARCH_TMP
	echo ";safesearch for Bing" >> $BIND_SAFESEARCH_TMP
	echo "www.bing.com CNAME strict.bing.com." >> $BIND_SAFESEARCH_TMP
	;;

duckduckgo)
	echo >>$BIND_SAFESEARCH_TMP
	echo ";duckduckgo searchsite" >> $BIND_SAFESEARCH_TMP
	echo "duckduckgo.com CNAME safe.duckduckgo.com" >> $BIND_SAFESEARCH_TMP
	;;


yahoo)
	echo >>$BIND_SAFESEARCH_TMP
	echo ";block yahoo searchsite" >> $BIND_SAFESEARCH_TMP
	echo "search.yahoo.com CNAME $CNAME_REDIR." >> $BIND_SAFESEARCH_TMP
	;;

esac
    
