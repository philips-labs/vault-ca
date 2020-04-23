#!/usr/bin/env bash

cert=$1

function get_issuers_uri {
  echo -e "$1" | openssl x509 -noout -text | grep 'CA Issuers - URI' | cut -d ':' -f2-
}

function get_crl_uri {
  echo -e "$1" | openssl x509 -noout -text | grep -A 4 'X509v3 CRL Distribution Points' | grep URI: | cut -d ':' -f2-
}

function download {
  curl -s $1/pem
}

ca_url=$(get_issuers_uri "$(cat $cert)")
crl_url=$(get_crl_uri "$(cat $cert)")
ca=$(download $ca_url)
crl=$(download $crl_url)

get_crl_uri "$ca"
chain="$crl\n$(download $(get_crl_uri "$ca"))\n$ca\n$(download $(get_issuers_uri "$ca"))"
echo -e "$chain" > chain.pem

openssl verify -crl_check -CAfile chain.pem $cert

rm chain.pem
