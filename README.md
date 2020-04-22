# Vault Certificate Authority

This project contains a setup of Vault as a Certificate Authority. It utilizes [Keybase](https://keybase.io) to safely store the **Vault Unseal Keys** and the **Vault Initial Root Token**.

## Prerequisites

- [Keybase](https://keybase.io/download)
- [Vault](https://www.vaultproject.io/downloads)

### MacOS

```bash
brew cask install keybase
brew install vault
vault -autocomplete-install && exec $SHELL
```

Then ensure you create your useraccount and have keybase started. It will allow access to the encrypted Keybase volumes where we will store this secret information. The init script will need your keybase username.

## Run Vault Server using docker-compose

```bash
docker-compose up -d
docker-compose logs -f
```

## Initializing the Vault

To initialize the Vault the `init.sh` script utilizes keybase to safely store the initial cluster setup secrets like the unseal keys and the root token. This script utilizes this to automate the setup as well to store these details in a safe manner for later use.

Now you can initialize vault, by running `init.sh`, providing our keybase username.

```bash
./init.sh marcofranssen
```

## References

- [Vault Getting Started](https://learn.hashicorp.com/vault/getting-started/install)
- [Vault Build Your Own Certificate Authority (CA)](https://learn.hashicorp.com/vault/secrets-management/sm-pki-engine)
