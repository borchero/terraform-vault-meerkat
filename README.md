# Meerkat Vault Configuration

[Meerkat](github.com/borchero/meerkat) is a collection of components to deploy OpenVPN easily in
Kubernetes. This repository contains the required configuration for Vault which manages all required
secrets.

## Prerequisites

Before running the configuration provided via this module, make sure that Kubernetes authentication
for Vault is set up and a connection for the database being referenced by this module has already
been created.

## Components

These Terraform configurations deploy a number of components, namely:

- It establishes a secure PKI to issue server and client certificates
- It sets up Kubernetes roles and policies for Meerkat's OpenVPN component and API
- It sets up Postgres role for Meerkat's API
