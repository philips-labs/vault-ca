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
${BASH_SOURCE%/*}/unseal.sh $1

echo
echo Apply policies:
vault policy write ca policies/ca-policy.hcl
vault policy write issue-cert-philips-dot-dev policies/issue-cert-philips-dot-dev-policy.hcl

echo
echo Use ca policy enabled token:
export VAULT_TOKEN=$(vault token create -policy=ca -format=json -ttl=5m | jq -r .auth.client_token)
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

ca=$(curl -s $VAULT_ADDR/v1/pki/ca/pem)
if [ -z "$ca" ] ; then
  echo Generating root CA.
  ca=$(vault write -field=certificate pki/root/generate/internal \
        common_name="Vault Certificate Authority" \
        ttl=87600h)
else
  echo Using existing root CA.
fi

vault write pki/config/urls \
      issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
      crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

intermediate=$(curl -s $VAULT_ADDR/v1/pki_int/ca/pem)
if [ -z "$intermediate" ] ; then
  echo Generating intermediate CA.
  vault write pki_int/intermediate/generate/internal \
          common_name="Vault Intermediate Authority" \
          -format=json | jq -r '.data.csr' > ${keybase_path}/pki_intermediate.csr
  vault write pki/root/sign-intermediate csr=@${keybase_path}/pki_intermediate.csr \
          format=pem_bundle ttl=43800h \
          -format=json | jq -r '.data.certificate' > ${keybase_path}/intermediate.crt

  vault write pki_int/intermediate/set-signed certificate=@${keybase_path}/intermediate.crt
else
  echo Using existing intermediate CA.
fi

vault write pki_int/config/urls \
      issuing_certificates="$VAULT_ADDR/v1/pki_int/ca" \
      crl_distribution_points="$VAULT_ADDR/v1/pki_int/crl"

vault write pki_int/roles/philips-dot-dev \
        allowed_domains="philips.dev" \
        allow_subdomains=true \
        max_ttl=720h

VAULT_TOKEN=$(get_root_token $keybase_path) vault operator seal
