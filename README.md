# easyfilter

This set of scripts is intended to build a RPZ zone for bind server.
It adds DNS filtering based on categorized blacklists.

This is a great alternative over squiguard, as it blocks also SSL sites without client config.
It works with transparent squid proxy.

It also adds safesearch capabilities for most popluar search engines. (Unless yahoo)

Bind from ISC is the server I prefer. it consumes much less CPU than dnsmasq.
for adult (porn) filter (the biggest category), your server need at least 2Gb of RAM.

1) verify settings variables suit your distro.
pfsense needs bind9 package. For Debian : `apt-get install bind9`

2) launch setup.sh
It needs an IP to redirect bad content to.
It could be the pfsense's LAN IP, but need to disable auto redirect web config and change port.
for pfsense : It launches an instance of nginx with same certificates which listen on port 80 and 443. (quick and dirty script in /usr/local/etc/rc.d)

3) launch `bind-update.sh` in INSTALLDIR
check categories and search engines you want to filter

4) launch `bind-build.sh` in INSTALLDIR

5) modify your named config :

add this code in general custom option pfsense's bind package ui. For Debian modify file `/etc/bind9/named.conf.options`

```
check-names response ignore;
response-policy { zone "easyfilter.local"; };
```
pfsense : Decalre this zone in your view's custom settings.
Debian : add this in `/etc/bind/named.conf.local`

```
zone "easyfilter.local" {
   type master;
   file "easyfilter.db";
   allow-query { none; };
};

```

6) restart your named server and check for errors in syslog.
