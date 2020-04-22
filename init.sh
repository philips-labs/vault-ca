#!/usr/bin/env bash

if [ -z "$1" ] ; then
  >&2 echo Please provide your keybase username.
  >&2 echo We will store some super secret stuff in your keybase private files
  exit 1
fi

kb_user=$1
keybase_path=/Volumes/Keybase/private/$kb_user/vault

function unsealKey {
  cat "${keybase_path}/init.txt" | grep "Key $1" | cut -d ':' -f2
}

function initRootToken {
  cat "${keybase_path}/init.txt" | grep "Initial Root Token" | cut -d ':' -f2
}

function tokenCapabilities {
  printf "%-20s | %s\n" "$1" "$(vault token capabilities $VAULT_TOKEN $1)"
}

export VAULT_ADDR=http://127.0.0.1:8200

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

export VAULT_TOKEN=$(initRootToken)

echo
echo Unsealing vault:
vault operator unseal $(unsealKey 1) > /dev/null
vault operator unseal $(unsealKey 2) > /dev/null
vault operator unseal $(unsealKey 3) > /dev/null
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
tokenCapabilities sys/mounts
tokenCapabilities sys/mounts/*
tokenCapabilities pki*
