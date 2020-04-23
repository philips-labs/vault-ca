#!/usr/bin/env bash

set -e

source ${BASH_SOURCE%/*}/functions.sh

keybase_path=$(get_keybase_path $1)

if [ -z "$2" ] ; then
  >&2 echo please provide the certificate you would like to request
  >&2 echo e.g. marco.philips.dev
  exit 1
fi

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=$(get_root_token $keybase_path)
export VAULT_TOKEN=$(vault token create -policy=issue-cert-philips-dot-dev -format=json -ttl=5m | jq -r .auth.client_token)

cert_data=$(vault write pki_int/issue/philips-dot-dev common_name="$2" ttl="24h" format="pem" -format=json | jq .data)

echo $cert_data | jq -r '.certificate' > $2.crt
echo $cert_data | jq -r '.issuing_ca' >> $2.crt
echo $cert_data | jq -r '.private_key' > $2.key
