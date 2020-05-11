# Meerkat Vault Configuration

[Meerkat](github.com/borchero/meerkat) is a collection of components to deploy OpenVPN easily in
Kubernetes. This repository contains the required configuration for Vault which manages all required
secrets.

## Prerequisites

Before running the configuration provided via this module, make sure that Kubernetes authentication
for Vault is set up and a connection for the database being referenced by this module has already
been created.

Additionally, Meerkat requires shared secrets that have to be generated on the client and pushed to
a Vault key-value store. Specifically, OpenVPN requires Diffie-Hellman parameters as well as a
shared key to prevent DoS attacks. For this, you should run the following steps:

```bash
# Generate Keys
openssl dhparam -out dh.pem 2048
openvpn --genkey --secret ta.key

# Create v2 stores
export KV_STORE=meerkat/kv
vault secrets enable -version=2 -path ${KV_STORE} kv

# Add generated secrets
cat dh.pem | vault kv put ${KV_STORE}/dh-params value=-
cat ta.key | vault kv put ${KV_STORE}/tls-auth value=-

# Delete secrets from client
rm dh.pem ta.key
```

Note that the `KV_STORE` variable needs to match the `vault_kv_store` variable exposed by this
module.

## Components

These Terraform configurations deploy a number of components, namely:

- It establishes a secure PKI to issue server and client certificates
- It sets up Kubernetes roles and policies for Meerkat's OpenVPN component and API
- It sets up Postgres role for Meerkat's API
