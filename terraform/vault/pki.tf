# Root CA
resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "This is an example PKI mount"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000
}

resource "vault_pki_secret_backend_root_cert" "root_2026" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "homelab.lan"
  ttl         = 315360000 # 10 years
  issuer_name = "root-2026"
}

resource "local_sensitive_file" "root_2026_cert" {
  content  = vault_pki_secret_backend_root_cert.root_2026.certificate
  filename = "root_2026_ca.crt"
}

resource "vault_pki_secret_backend_issuer" "root_2026" {
  backend                        = vault_mount.pki.path
  issuer_ref                     = vault_pki_secret_backend_root_cert.root_2026.issuer_id
  issuer_name                    = vault_pki_secret_backend_root_cert.root_2026.issuer_name
  revocation_signature_algorithm = "SHA256WithRSA"
}

# Root CA URLs
resource "vault_pki_secret_backend_config_urls" "config-urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["http://localhost:8200/v1/pki/ca"]
  crl_distribution_points = ["http://localhost:8200/v1/pki/crl"]
}

# Intermediate CA
resource "vault_mount" "pki_int" {
  path        = "pki_int"
  type        = "pki"
  description = "This is an example intermediate PKI mount"
  allowed_response_headers = [
    "Last-Modified",
    "Location",
    "Replay-Nonce",
    "Link"
  ]

  default_lease_ttl_seconds = 86400     # 1 day
  max_lease_ttl_seconds     = 157680000 # 5 years
}

resource "vault_pki_secret_backend_intermediate_cert_request" "csr-request" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "homelab.lan Intermediate Authority"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend     = vault_mount.pki.path
  common_name = "new_intermediate"
  csr         = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr
  format      = "pem_bundle"
  ttl         = 15480000 # 5 years
  issuer_ref  = vault_pki_secret_backend_root_cert.root_2026.issuer_id
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

# Register the imported intermediate issuer.
resource "vault_pki_secret_backend_issuer" "intermediate" {
  backend     = vault_mount.pki_int.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate.imported_issuers[0]
  issuer_name = "homelab-dot-lan-intermediate"
}

resource "vault_pki_secret_backend_role" "intermediate_role" {
  backend          = vault_mount.pki_int.path
  issuer_ref       = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  name             = "homelab-dot-lan"
  ttl              = 86400
  max_ttl          = 2592000
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allowed_domains  = ["homelab.lan"]
  allow_subdomains = true

}

# PostgreSQL certificate
resource "vault_pki_secret_backend_cert" "postgres-dot-lan" {
  issuer_ref  = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  backend     = vault_pki_secret_backend_role.intermediate_role.backend
  name        = vault_pki_secret_backend_role.intermediate_role.name
  common_name = "postgres.homelab.lan"
  alt_names   = ["docker.homelab.lan"]
  ttl         = 2592000 # 30 days
  revoke      = true
}

# PostgreSQL certificate files
resource "local_sensitive_file" "postgres_server_cert" {
  content = join("\n", [
    vault_pki_secret_backend_cert.postgres-dot-lan.certificate,
    vault_pki_secret_backend_cert.postgres-dot-lan.ca_chain,
  ])
  filename        = "${path.module}/../docker/server.crt"
  file_permission = "0644"
}

resource "local_sensitive_file" "postgres_server_key" {
  content         = vault_pki_secret_backend_cert.postgres-dot-lan.private_key
  filename        = "${path.module}/../docker/server.key"
  file_permission = "0600"
}

# ACME
resource "vault_pki_secret_backend_config_cluster" "pki_int_config_cluster" {
  backend  = vault_mount.pki_int.path
  path     = "https://10.23.1.30:8200/v1/pki_int"
  aia_path = "https://10.23.1.30:8200/v1/pki_int"
}

resource "vault_pki_secret_backend_config_acme" "pki_int_config_acme" {
  backend                  = vault_mount.pki_int.path
  enabled                  = true
  allowed_issuers          = ["*"]
  allowed_roles            = ["*"]
  allow_role_ext_key_usage = false
  default_directory_policy = "sign-verbatim"
  dns_resolver             = ""
  eab_policy               = "not-required"
}

resource "vault_pki_secret_backend_config_auto_tidy" "pki_int" {
  backend           = vault_mount.pki_int.path
  enabled           = true
  tidy_cert_store   = true
  interval_duration = "1h"
}

