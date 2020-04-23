#!/usr/bin/env bash

cert=$1

ca_url=$(openssl x509 -noout -text -in $cert | grep 'CA Issuers - URI' | cut -d ':' -f2-)
crl_url=$(openssl x509 -noout -text -in $cert | grep -A 4 'X509v3 CRL Distribution Points' | grep URI: | cut -d ':' -f2-)
ca=$(curl -s $ca_url/pem)
crl=$(curl -s $crl_url/pem)
echo -e "$crl\n$ca" > chain.pem

openssl verify -crl_check -CAfile chain.pem $cert

rm chain.pem
