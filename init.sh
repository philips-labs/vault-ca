#!/usr/bin/env bash

set -e

source ${BASH_SOURCE%/*}/functions.sh

keybase_path=$(get_keybase_path $1)

export VAULT_ADDR=http://127.0.0.1:8200

function enable_pki {
  if [ -z "$(vault secrets list | grep $1/)" ] ; then
    vault secrets enable -max-lease-ttl=$2 -path=$1 -description="$3" pki
  fi
}

echo "Using '$keybase_path' for secret storage"

mkdir -p ${keybase_path}
if [ ! -f "${keybase_path}/init.txt" ] ; then
  echo Initializing
  vault operator init \
        -key-shares=6 -key-threshold=3 > "${keybase_path}/init.txt"
else
  echo Your Vault cluster was already initialized.
fi
echo See ${keybase_path}/init.txt for the keys and root token.

export VAULT_TOKEN=$(get_root_token $keybase_path)

echo
echo Unsealing vault:
vault operator unseal $(get_unseal_key $keybase_path 1) > /dev/null
vault operator unseal $(get_unseal_key $keybase_path 2) > /dev/null
vault operator unseal $(get_unseal_key $keybase_path 3) > /dev/null
vault status

echo
echo Apply policies:
vault policy write ca policies/ca-policy.hcl

echo
echo Use ca policy enabled token:
export VAULT_TOKEN=$(vault token create -policy=ca -format=json -ttl=5m | jq .auth.client_token | cut -d '"' -f2)
echo Token capabilities:
printf "%-20s | Capabilities\n" Path
printf "%-20s | --------------------\n" --------------------
print_token_capabilities sys/mounts
print_token_capabilities sys/mounts/*
print_token_capabilities pki*

echo
echo Enabling pki engine:
enable_pki pki 87600h "Root CA"             # 10 years for root certificate
enable_pki pki_int 43800h "Intermediate CA" # 5 years for intermediate certificates

vault write -field=certificate pki/root/generate/internal \
      common_name="Vault Certificate Authority" \
      ttl=87600h > ${keybase_path}/CA_cert.crt

vault write pki_int/intermediate/generate/internal \
        common_name="Vault Intermediate Authority" \
        -format=json | jq -r '.data.csr' > ${keybase_path}/pki_intermediate.csr
vault write pki/root/sign-intermediate csr=@${keybase_path}/pki_intermediate.csr \
        format=pem_bundle ttl=43800h \
        -format=json | jq -r '.data.certificate' > ${keybase_path}/intermediate.cert.pem
vault write pki_int/intermediate/set-signed certificate=@${keybase_path}/intermediate.cert.pem

vault write pki/config/urls \
      issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
      crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
