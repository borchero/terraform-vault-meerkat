output "policy_vpn" {
  value       = vault_policy.vpn.name
  description = "The name of the policy that should be assigned to Meerkat's VPN component."
}

output "policy_api" {
  value       = vault_policy.api.name
  description = "The name of the policy that should be assigned to Meerkat's API component."
}

output "policy_cron" {
  value       = vault_policy.vpn_cron.name
  description = "The name of the policy that should be assigned to Meerkat's Cron component."
}
