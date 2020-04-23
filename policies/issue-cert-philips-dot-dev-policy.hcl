# Enable secrets engine
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List enabled secrets engine
path "sys/mounts" {
  capabilities = ["read", "list"]
}

# Work with pki_int secrets engine
path "pki_int" {
  capabilities = ["read", "list"]
}

# Work with pki_int secrets engine
path "pki_int/issue/philips-dot-dev" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
