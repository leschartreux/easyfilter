scripts to manipulate content filter on debian distrib

1) verify settings variables suit your distro
2) launch setup.sh
3) launch bind-update.sh in INSTALLDIR
4) launch bind-build.sh in INSTALLDIR


modify your named.conf :

add in option

check-names response ignore;
response-policy { zone "easyfilter.localdomain.org"; };

add zone in your view

zone "easyfilter.localdomain.org" {
   type master;
   file "db.easyfilter";
   allow-query { none; };
};
