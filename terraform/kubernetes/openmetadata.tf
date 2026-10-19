# resource "kubernetes_namespace_v1" "openmetadata" {
#   metadata {
#     name = "openmetadata"
#   }
# }

# ephemeral "vault_kv_secret_v2" "openmetadata_db" {
#   mount = "kvv2"
#   name  = "postgres-openmetadata"
# }

# resource "kubernetes_secret_v1" "openmetadata_db" {
#   metadata {
#     name      = "openmetadata-postgres"
#     namespace = kubernetes_namespace_v1.openmetadata.metadata[0].name
#   }
#   type = "generic"
#   data_wo = {
#     connection = tostring(ephemeral.vault_kv_secret_v2.openmetadata_db.data.connection)
#   }
#   data_wo_revision = 1
# }
