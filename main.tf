################
### PROVIDER ###
################

provider "vault" {
  address = var.local_vault_address
}

#################
### PKI MOUNT ###
#################

resource "vault_mount" "pki" {
  type = "pki"
  path = var.vault_pki

  default_lease_ttl_seconds = 63072000  # 2 years
  max_lease_ttl_seconds     = 315360000 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "pki" {
  backend = vault_mount.pki.path

  type               = "internal"
  common_name        = var.common_name
  ttl                = "315360000" # 10 years
  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 4096

  exclude_cn_from_sans = false

  country      = var.country
  locality     = var.locality
  organization = var.organization
  ou           = var.organization_unit
}

resource "vault_pki_secret_backend_config_urls" "pki" {
  backend = vault_mount.pki.path

  issuing_certificates = [
    "${var.vault_address}/v1/${vault_mount.pki.path}/ca"
  ]
  crl_distribution_points = [
    "${var.vault_address}/v1/${vault_mount.pki.path}/crl"
  ]
}

#################
### PKI ROLES ###
#################

resource "vault_pki_secret_backend_role" "server" {
  backend = vault_mount.pki.path

  name     = "server"
  key_type = "rsa"
  key_bits = 2048
  ttl      = 63072000 # 2 years
  max_ttl  = 63072000 # 2 years

  require_cn         = true
  allow_any_name     = true
  allow_localhost    = false
  allow_bare_domains = false
  enforce_hostnames  = false
  allow_ip_sans      = false
  allow_glob_domains = false

  server_flag           = true
  client_flag           = false
  code_signing_flag     = false
  email_protection_flag = false
  key_usage = [
    "digitalSignature",
    "keyAgreement",
    "keyEncipherment"
  ]
  ext_key_usage = [
    "TLS Web Server Authentication"
  ]

  country      = [var.country]
  locality     = [var.locality]
  organization = [var.organization]
}

resource "vault_pki_secret_backend_role" "client" {
  backend = vault_mount.pki.path

  name     = "client"
  key_type = "rsa"
  key_bits = 2048
  ttl      = 63072000 # 2 years
  max_ttl  = 63072000 # 2 years

  require_cn         = true
  allow_any_name     = true
  allow_localhost    = false
  allow_bare_domains = false
  enforce_hostnames  = false
  allow_ip_sans      = false
  allow_glob_domains = false

  server_flag           = false
  client_flag           = true
  code_signing_flag     = false
  email_protection_flag = false
  key_usage = [
    "digitalSignature",
    "keyAgreement",
    "keyEncipherment"
  ]
  ext_key_usage = [
    "TLS Web Client Authentication"
  ]

  country      = [var.country]
  locality     = [var.locality]
  organization = [var.organization]
}

#####################
### DATABASE ROLE ###
#####################

resource "vault_database_secret_backend_role" "api" {
  name    = var.postgres_role
  backend = var.postgres_vault_path
  db_name = var.postgres_database

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT * ON ALL TABLES IN SCHEMA ${var.postgres_schema} TO \"{{name}}\";"
  ]

  default_ttl = 3600
  max_ttl     = 86400
}

########################
### KUBERNETES ROLES ###
########################

resource "vault_kubernetes_auth_backend_role" "vpn" {
  backend   = var.vault_kubernetes_auth
  role_name = var.vault_role_vpn

  bound_service_account_names      = [var.kubernetes_sa_vpn]
  bound_service_account_namespaces = [var.kubernetes_namespace]

  token_ttl      = 3600
  token_policies = ["default", vault_policy.vpn.name]
}

resource "vault_kubernetes_auth_backend_role" "api" {
  backend   = var.vault_kubernetes_auth
  role_name = var.vault_role_api

  bound_service_account_names      = [var.kubernetes_sa_api]
  bound_service_account_namespaces = [var.kubernetes_namespace]

  token_ttl      = 3600
  token_policies = ["default", vault_policy.api.name]
}

################
### POLICIES ###
################

resource "vault_policy" "vpn" {
  name   = "${var.vault_policy_prefix}.vpn"
  policy = <<EOT
# Allow reading shared keys (DH params and TLS Auth)
path "${var.vault_kv_store}" {
  capabilities = ["read"]
}

# Allow reading the CRL
path "${var.vault_pki}/crl/pem" {
  capabilities = ["read"]
}

# Allow issuing server certificates
path "${var.vault_pki}/issue/server" {
  capabilities = ["read", "create", "update"]
}
EOT
}

resource "vault_policy" "api" {
  name   = "${var.vault_policy_prefix}.api"
  policy = <<EOT
# Allow reading shared TLS Auth
path "${var.vault_kv_store}/tls-auth" {
  capabilities = ["read"]
}

# Allow issuing client certificates
path "${var.vault_pki}/issue/client" {
  capabilities = ["read", "create", "update"]
}

# Allow revoking certificates
path "${var.vault_pki}/revoke" {
  capabilities = ["read", "create", "update"]
}

# Allow accessing the database with the configured role
path "${var.postgres_vault_path}/creds/${var.postgres_role}" {
  capabilities = ["read"]
}
EOT
}
