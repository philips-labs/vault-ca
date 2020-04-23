# Vault Certificate Authority

This project contains a setup of Vault as a Certificate Authority. It utilizes [Keybase](https://keybase.io) to safely store the **Vault Unseal Keys** and the **Vault Initial Root Token**. **jq** is used to interpret json on the cli.

## Prerequisites

- [Keybase](https://keybase.io/download)
- [Vault](https://www.vaultproject.io/downloads)
- [jq](https://stedolan.github.io/jq/)

### MacOS

```bash
brew cask install keybase
brew install vault jq
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

## Issue certificates

To issue a new certificate you can use the `issue-cert.sh` script. This will create 2 files in the current folder.

- your.domain.tld.crt
- your.domain.tld.key

```bash
./issue-cert.sh marcofranssen marco.philips.dev
```

## Verify certificates

To validate if your certificate is valid you can use the `verify-cert.sh` script which will validate the certificate against the CA Issuer and the CRL (Certificate Revocation List). This allows you to very easily check for revoked certificates.

```bash
./verify-cert.sh /Volumes/Keybase/private/marcofranssen/vault/intermediate.cert.pem
./verify-cert.sh marco.philips.dev
```

## References

- [Vault Getting Started](https://learn.hashicorp.com/vault/getting-started/install)
- [Vault Build Your Own Certificate Authority (CA)](https://learn.hashicorp.com/vault/secrets-management/sm-pki-engine)
- [Vault Policies](https://learn.hashicorp.com/vault/identity-access-management/iam-policies)
