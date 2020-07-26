#--------------------------------------------------------------------------------------------------
# PKI MOUNT

resource "vault_mount" "pki" {
  type = "pki"
  path = var.vault_pki_path

  default_lease_ttl_seconds = 63072000  # 2 years
  max_lease_ttl_seconds     = 315360000 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "pki" {
  backend = vault_mount.pki.path

  type               = "internal"
  common_name        = var.pki_common_name
  ttl                = "315360000" # 10 years
  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 4096

  exclude_cn_from_sans = false

  country      = var.pki_country
  locality     = var.pki_locality
  organization = var.pki_organization
  ou           = var.pki_organization_unit
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

#--------------------------------------------------------------------------------------------------
# PKI ROLES

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
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment"
  ]
  ext_key_usage = [
    "TLS Web Server Authentication"
  ]

  country      = [var.pki_country]
  locality     = [var.pki_locality]
  organization = [var.pki_organization]
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
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment"
  ]
  ext_key_usage = [
    "TLS Web Client Authentication"
  ]

  country      = [var.pki_country]
  locality     = [var.pki_locality]
  organization = [var.pki_organization]
}

#--------------------------------------------------------------------------------------------------
# POLICIES

resource "vault_policy" "vpn" {
  name   = "${var.vault_policy_prefix}.vpn"
  policy = <<-EOT
    # Allow reading shared keys (DH params and TLS Auth)
    path "${var.vault_kv_path}/*" {
      capabilities = ["read"]
    }

    # Allow reading the CRL
    path "${vault_mount.pki.path}/crl/pem" {
      capabilities = ["read"]
    }

    # Allow issuing server certificates
    path "${vault_mount.pki.path}/issue/server" {
      capabilities = ["read", "create", "update"]
    }
  EOT
}

resource "vault_policy" "api" {
  name   = "${var.vault_policy_prefix}.api"
  policy = <<-EOT
    # Allow reading shared TLS Auth
    path "${var.vault_kv_path}/tls-auth" {
      capabilities = ["read"]
    }

    # Allow issuing client certificates
    path "${vault_mount.pki.path}/issue/client" {
      capabilities = ["read", "create", "update"]
    }

    # Allow revoking certificates
    path "${vault_mount.pki.path}/revoke" {
      capabilities = ["read", "create", "update"]
    }
  EOT
}
