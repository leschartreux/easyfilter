# easyfilter

This set of scripts is intended to build a RPZ zone for bind server.
It adds DNS filtering based on categorized blacklists.

It also adds safesearch capabilities for most popluar search engines.

Bind is best suited for performance. it uses much less CPU than dnsmasq.
for adult filter (the biggest category) your server need at least 2Gb of RAM.

For now, settings are specific to PFsense's bind DNS package

1) verify settings variables suit your distro 
2) launch setup.sh
3) launch bind-update.sh in INSTALLDIR
4) launch bind-build.sh in INSTALLDIR

5)
modify your named.conf :

add in option

check-names response ignore;
response-policy { zone "easyfilter.localdomain.org"; };

add this zone in your view

zone "easyfilter.localdomain.org" {
   type master;
   file "easyfilter.db";
   allow-query { none; };
};


6) restart your named server and check for errors.
