# https://developer.hashicorp.com/vault/tutorials/pki/pki-engine

# step 1.1 and 1.2
resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "This is an example PKI mount"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000
}

# 1.3
# vault write -field=certificate pki/root/generate/internal \
#   common_name="homelab.lan" \
#   issuer_name="root-2026" \
#   ttl=87600h > root_2026_ca.crt

resource "vault_pki_secret_backend_root_cert" "root_2026" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "homelab.lan"
  ttl         = 315360000 # 10 years
  issuer_name = "root-2026"
}

# output "vault_pki_secret_backend_root_cert_root_2026" {
#   value = vault_pki_secret_backend_root_cert.root_2026.certificate
# }

resource "local_sensitive_file" "root_2026_cert" {
  content  = vault_pki_secret_backend_root_cert.root_2026.certificate
  filename = "root_2026_ca.crt"
}

# used to update name and properties
# manages lifecycle of existing issuer
resource "vault_pki_secret_backend_issuer" "root_2026" {
  backend                        = vault_mount.pki.path
  issuer_ref                     = vault_pki_secret_backend_root_cert.root_2026.issuer_id
  issuer_name                    = vault_pki_secret_backend_root_cert.root_2026.issuer_name
  revocation_signature_algorithm = "SHA256WithRSA"
}

# 1.6
# vault write pki/roles/2026-servers allow_any_name=true

resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_mount.pki.path
  name             = "2026-servers-role"
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allow_subdomains = true
  allow_any_name   = true
}

# 1.7
resource "vault_pki_secret_backend_config_urls" "config-urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["http://localhost:8200/v1/pki/ca"]
  crl_distribution_points = ["http://localhost:8200/v1/pki/crl"]
}

# step 2 - 2.1 and 2.2
# vault secrets enable -path=pki_int pki
# vault secrets tune -max-lease-ttl=43800h pki_int

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

# 2.3 - generate intermediate and save csr
# vault write -format=json pki_int/intermediate/generate/internal \
#      common_name="homelab.lan Intermediate Authority" \
#      issuer_name="homelab-dot-lan-intermediate" \
#      | jq -r '.data.csr' > pki_intermediate.csr

resource "vault_pki_secret_backend_intermediate_cert_request" "csr-request" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "homelab.lan Intermediate Authority"
}

resource "local_sensitive_file" "csr_request_cert" {
  content  = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr
  filename = "pki_intermediate.csr"
}

# step 2.4
# vault write -format=json pki/root/sign-intermediate \
#      issuer_ref="root-2026" \
#      csr=@pki_intermediate.csr \
#      format=pem_bundle ttl="43800h" \
#      | jq -r '.data.certificate' > intermediate.cert.pem

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend     = vault_mount.pki.path
  common_name = "new_intermediate"
  csr         = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr
  format      = "pem_bundle"
  ttl         = 15480000 # 5 years
  issuer_ref  = vault_pki_secret_backend_root_cert.root_2026.issuer_id
}

resource "local_sensitive_file" "intermediate_ca_cert" {
  content  = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
  filename = "intermediate.cert.pem"
}

# step 2.5
# vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

# manage the issuer created for the set signed
resource "vault_pki_secret_backend_issuer" "intermediate" {
  backend     = vault_mount.pki_int.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate.imported_issuers[0]
  issuer_name = "homelab-dot-lan-intermediate"
}

# vault list pki_int_example/issuer

# step 3
# vault write pki_int/roles/homelab-dot-lan \
#      issuer_ref="$(vault read -field=default pki_int/config/issuers)" \
#      allowed_domains="homelab.lan" \
#      allow_subdomains=true \
#      max_ttl="720h"

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

#  step4: request new cert for URL
#  vault write pki_int/issue/homelab-dot-lan common_name="test.homelab.lan" ttl="24h"

resource "vault_pki_secret_backend_cert" "postgres-dot-lan" {
  issuer_ref  = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  backend     = vault_pki_secret_backend_role.intermediate_role.backend
  name        = vault_pki_secret_backend_role.intermediate_role.name
  common_name = "postgres.homelab.lan"
  alt_names   = ["docker.homelab.lan"]
  ttl         = 2592000
  revoke      = true
}

resource "vault_pki_secret_backend_cert" "airflow-dot-lan" {
  issuer_ref  = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  backend     = vault_pki_secret_backend_role.intermediate_role.backend
  name        = vault_pki_secret_backend_role.intermediate_role.name
  common_name = "airflow.homelab.lan"
  ttl         = 2592000
  revoke      = true
}

# Wildcard certificate for homelab.lan domain
resource "vault_pki_secret_backend_cert" "wildcard-homelab-lan" {
  issuer_ref  = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  backend     = vault_pki_secret_backend_role.intermediate_role.backend
  name        = vault_pki_secret_backend_role.intermediate_role.name
  common_name = "*.homelab.lan"
  alt_names   = ["*.homelab.lan"]
  ttl         = 2592000
  revoke      = true
}

resource "local_sensitive_file" "wildcard_homelab_lan_cert" {
  content = join("\n", [
    vault_pki_secret_backend_cert.wildcard-homelab-lan.certificate,
    vault_pki_secret_backend_cert.wildcard-homelab-lan.ca_chain,
  ])
  filename        = "${path.module}/../kubernetes/files/traefik.crt"
  file_permission = "0644"
}

resource "local_sensitive_file" "wildcard_homelab_lan_key" {
  content         = vault_pki_secret_backend_cert.wildcard-homelab-lan.private_key
  filename        = "${path.module}/../kubernetes/files/traefik.key"
  file_permission = "0600"
}

# output "vault_pki_secret_backend_cert_homelab-dot-lan_cert" {
#   value = vault_pki_secret_backend_cert.homelab-dot-lan.certificate
# }

# output "vault_pki_secret_backend_cert_homelab-dot-lan_issuring_ca" {
#   value = vault_pki_secret_backend_cert.homelab-dot-lan.issuing_ca
# }

# output "vault_pki_secret_backend_cert_homelab-dot-lan_serial_number" {
#   value = vault_pki_secret_backend_cert.homelab-dot-lan.serial_number
#   #   sensitive = true
# }

# output "vault_pki_secret_backend_cert_homelab-dot-lan_private_key_type" {
#   value = vault_pki_secret_backend_cert.homelab-dot-lan.private_key_type
# }

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

# # step 5, expain the revoke = true

# # 6 not possible via TF
# # step 8 is part of demo

# # step 7 create a second root instead of rotate

# # vault write pki/root/rotate/internal \
# #     common_name="homelab.lan" \
# #     issuer_name="root-2024"
# #
# # Method	Path
# # POST	/pki/root/generate/:type
# # POST	/pki/issuers/generate/root/:type
# # POST	/pki/root/rotate/:type

# resource "vault_pki_secret_backend_root_cert" "root_2024" {
#   backend     = vault_mount.pki.path
#   type        = "internal"
#   common_name = "homelab.lan"
#   ttl         = "315360000"
#   issuer_name = "root-2024"
#   key_name    = "root_2024"
# }

# # used to update name and properties
# # manages lifecycle of existing issuer
# resource "vault_pki_secret_backend_issuer" "root_2024" {
#   backend                        = vault_mount.pki.path
#   issuer_ref                     = vault_pki_secret_backend_root_cert.root_2024.issuer_id
#   issuer_name                    = vault_pki_secret_backend_root_cert.root_2024.issuer_name
#   revocation_signature_algorithm = "SHA256WithRSA"
# }

# # vault write pki/roles/2024-servers allow_any_name=true
# resource "vault_pki_secret_backend_role" "role_2024" {
#   backend        = vault_mount.pki.path
#   name           = "2024-servers"
#   allow_any_name = true
# }

# # 8.1 - creates a new cross-signed intermediate CSR
# # uses key from new root in step 7
# # vault write -format=json pki/intermediate/cross-sign \
# #       common_name="homelab.lan" \
# #       key_ref="$(vault read pki/issuer/root-2024 \
# #       | grep -i key_id | awk '{print $2}')" \
# #       | jq -r '.data.csr' \
# #       | tee cross-signed-intermediate.csr
# # pki/intermediate/cross-sign == pki/issuers/generate/intermediate/existing

# resource "vault_pki_secret_backend_intermediate_cert_request" "new_csr" {
#   backend     = vault_mount.pki.path
#   type        = "existing"
#   common_name = "homelab.lan"
#   key_ref     = vault_pki_secret_backend_root_cert.root_2024.key_name
# }

# ## write to file
# resource "local_sensitive_file" "new_csr_file" {
#   content  = vault_pki_secret_backend_intermediate_cert_request.new_csr.csr
#   filename = "cross-signed-intermediate.csr"
# }

# # 8.2 - sign csr with older root CA
# # vault write -format=json pki/issuer/root-2026/sign-intermediate \
# #       common_name="homelab.lan" \
# #       csr=@cross-signed-intermediate.csr \
# #       | jq -r '.data.certificate' | tee cross-signed-intermediate.crt

# resource "vault_pki_secret_backend_root_sign_intermediate" "root_2024" {
#   backend     = vault_mount.pki.path
#   csr         = vault_pki_secret_backend_intermediate_cert_request.new_csr.csr
#   common_name = "homelab.lan"
#   ttl         = 43800
#   issuer_ref  = vault_pki_secret_backend_root_cert.root_2026.issuer_id
# }

# # 8.3
# # vault write pki/intermediate/set-signed \
# #       certificate=@cross-signed-intermediate.crt

# resource "vault_pki_secret_backend_intermediate_set_signed" "root_2024" {
#   backend     = vault_mount.pki.path
#   certificate = vault_pki_secret_backend_root_sign_intermediate.root_2024.certificate
# }

# # 8.4 - print 
# # vault read pki/issuer/root-2024
# output "vault_pki_secret_backend_root_sign_intermediate_root_2024_ca_chain" {
#   value = vault_pki_secret_backend_root_sign_intermediate.root_2024.ca_chain
# }

# # # step 9
# # # Set new default issuer
# # resource "vault_pki_secret_backend_config_issuers" "config" {
# #   backend                       = vault_mount.pki.path
# #   default                       = vault_pki_secret_backend_issuer.root_2024.issuer_id
# #   default_follows_latest_issuer = true
# # }


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

