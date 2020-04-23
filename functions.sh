#!/usr/bin/env bash

function get_keybase_path {
  if [ -z "$1" ] ; then
    >&2 echo Please provide your keybase username.
    >&2 echo We will store some super secret stuff in your keybase private files
    return 1
  fi

  local kb_user=$1
  local keybase_path=/Volumes/Keybase/private/$kb_user/vault

  if [ ! -d ${keybase_path} ] ; then
    >&2 echo ${keybase_path} can not be accessed!
    >&2 echo Are you sure Keybase is running?
    >&2 echo Did you provide the correct Keybase username?
    return 1
  fi
  echo /Volumes/Keybase/private/$1/vault
}

function get_unseal_key {
  cat "${1}/init.txt" | grep "Key $2" | cut -d ':' -f2
}

function get_root_token {
  cat "${1}/init.txt" | grep "Initial Root Token" | cut -d ':' -f2
}

function print_token_capabilities {
  printf "%-20s | %s\n" "$1" "$(vault token capabilities $VAULT_TOKEN $1)"
}
