#!/usr/bin/env bash

set -e

source ${BASH_SOURCE%/*}/functions.sh

keybase_path=$(get_keybase_path $1)

export VAULT_TOKEN=$(get_root_token $keybase_path)

echo Unsealing vault:
echo
vault operator unseal $(get_unseal_key $keybase_path 1) > /dev/null
vault operator unseal $(get_unseal_key $keybase_path 2) > /dev/null
vault operator unseal $(get_unseal_key $keybase_path 3) > /dev/null
vault status
