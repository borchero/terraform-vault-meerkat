#--------------------------------------------------------------------------------------------------
# VAULT

variable "vault_address" {
  type        = string
  default     = "http://localhost:8200"
  description = "The endpoint where Vault is reachable for obtaing CRLs for the running Meerkat."
}

variable "vault_pki_path" {
  type        = string
  default     = "pki/meerkat"
  description = "The path for the Meerkat PKI."
}

variable "vault_kv_path" {
  type        = string
  default     = "kv/meerat"
  description = "The path for the KV V2 engine used to store the 'dh-params' and 'tls-auth' keys."
}

variable "vault_policy_prefix" {
  type        = string
  default     = "meerkat"
  description = "The prefix of the name of the policies created for Meerkat."
}

#--------------------------------------------------------------------------------------------------
# PKI

variable "pki_common_name" {
  type        = string
  description = "The common name to use for the CA."
}

variable "pki_organization" {
  type        = string
  description = "The name of the organization issuing certificates."
}

variable "pki_country" {
  type        = string
  default     = "DE"
  description = "The 2-letter country code to use for the CA."
}

variable "pki_locality" {
  type        = string
  default     = "Munich"
  description = "The city of the organization issuing certificates."
}

variable "pki_organization_unit" {
  type        = string
  default     = "IT"
  description = "The organization unit responsible for the CA."
}
