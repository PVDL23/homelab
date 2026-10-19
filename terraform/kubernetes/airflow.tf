# resource "kubernetes_namespace_v1" "airflow" {
#   metadata {
#     name = "airflow"
#   }
# }

# ephemeral "vault_kv_secret_v2" "airflow_db" {
#   mount = "kvv2"
#   name  = "airflow"
# }

# ephemeral "vault_kv_secret_v2" "inat-s3-credentials" {
#   mount = "kvv2"
#   name  = "scaleway"
# }

# resource "kubernetes_secret_v1" "airflow_db" {
#   metadata {
#     name      = "airflow-postgres"
#     namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#   }
#   type = "generic"
#   data_wo = {
#     connection = tostring(ephemeral.vault_kv_secret_v2.airflow_db.data.connection)
#   }
#   data_wo_revision = 1
# }

# resource "kubernetes_secret_v1" "airflow_secret_key" {
#   metadata {
#     name      = "airflow-api-secret"
#     namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#   }
#   type = "generic"
#   data_wo = {
#     webserver-secret-key = ephemeral.vault_kv_secret_v2.airflow_db.data.webserver-secret-key
#   }
#   data_wo_revision = 1
# }

# resource "kubernetes_secret_v1" "airflow_fernet_key" {
#   metadata {
#     name      = "airflow-fernet-key"
#     namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#   }
#   type = "generic"
#   data_wo = {
#     fernet-key = ephemeral.vault_kv_secret_v2.airflow_db.data.fernet-key
#   }
#   data_wo_revision = 1
# }

# resource "kubernetes_secret_v1" "inat-s3-credentials" {
#   metadata {
#     name      = "inat-s3-credentials"
#     namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#   }
#   type = "generic"
#   data_wo = {
#     SCW_ACCESS_KEY = ephemeral.vault_kv_secret_v2.inat-s3-credentials.data.scw_access_key
#     SCW_SECRET_KEY = ephemeral.vault_kv_secret_v2.inat-s3-credentials.data.scw_secret_key
#   }
#   data_wo_revision = 1
# }

# resource "kubernetes_persistent_volume_claim_v1" "airflow" {
#   metadata {
#     name      = "apache-airflow-data"
#     namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#   }
#   spec {
#     access_modes = ["ReadWriteMany"]
#     resources {
#       requests = {
#         storage = "10Gi"
#       }
#     }
#     storage_class_name = "nfs"
#   }
# }

# resource "helm_release" "airflow" {
#   name       = "apache-airflow"
#   repository = "https://airflow.apache.org"
#   chart      = "airflow"
#   namespace  = kubernetes_namespace_v1.airflow.metadata[0].name
#   wait       = true
#   depends_on = [kubernetes_persistent_volume_claim_v1.airflow]

#   values = [
#     yamlencode({
#       images = {
#         airflow = {
#           repository = "rg.nl-ams.scw.cloud/data-engineering-cr/airflow-dags"
#           tag        = "251017"
#           # pullPolicy = "IfNotPresent"
#           pullPolicy = "Always"
#         }
#       }

#       airflow = {
#         executor               = "CeleryExecutor"
#         apiSecretKeySecretName = kubernetes_secret_v1.airflow_secret_key.metadata[0].name
#         fernetKeySecretName    = kubernetes_secret_v1.airflow_fernet_key.metadata[0].name
#       }

#       postgresql = {
#         enabled = false
#       }

#       data = {
#         metadataSecretName = kubernetes_secret_v1.airflow_db.metadata[0].name
#       }

#       databaseCleanup = {
#         enabled       = true
#         retentionDays = 90
#       }

#       createUserJob = {
#         useHelmHooks   = false
#         applyCustomEnv = false
#       }
#       migrateDatabaseJob = {
#         useHelmHooks   = false
#         applyCustomEnv = false
#       }

#       config = {
#         core = {
#           load_examples = "False"
#           dags_folder   = "/opt/airflow/dags"
#         }
#         api = {
#           expose_config = "True"
#         }
#       }

#       defaultAirflowRepo = "apache/airflow"
#       defaultAirflowTag  = "2.10.0"

#       web = {
#         replicas = 1
#         resources = {
#           requests = {
#             cpu    = "500m"
#             memory = "1Gi"
#           }
#           limits = {
#             cpu    = "2"
#             memory = "2Gi"
#           }
#         }
#       }

#       scheduler = {
#         replicas = 1
#         resources = {
#           requests = {
#             cpu    = "500m"
#             memory = "1Gi"
#           }
#           limits = {
#             cpu    = "2"
#             memory = "2Gi"
#           }
#         }
#       }

#       workers = {
#         replicas = 1
#         resources = {
#           requests = {
#             cpu    = "1"
#             memory = "2Gi"
#           }
#           limits = {
#             cpu    = "4"
#             memory = "4Gi"
#           }
#         }
#         extraVolumeMounts = [
#           {
#             name      = "airflow-data"
#             mountPath = "/opt/airflow/data"
#           }
#         ]
#         extraVolumes = [
#           {
#             name = "airflow-data"
#             persistentVolumeClaim = {
#               claimName = "apache-airflow-data"
#             }
#           }
#         ]
#       }

#       triggerer = {
#         replicas = 1
#         resources = {
#           requests = {
#             cpu    = "200m"
#             memory = "512Mi"
#           }
#           limits = {
#             cpu    = "1"
#             memory = "1Gi"
#           }
#         }
#       }

#       redis = {
#         enabled = true
#         resources = {
#           requests = {
#             cpu    = "200m"
#             memory = "512Mi"
#           }
#           limits = {
#             cpu    = "500m"
#             memory = "1Gi"
#           }
#         }
#       }

#       statsd = {
#         enabled = true
#         resources = {
#           requests = {
#             cpu    = "100m"
#             memory = "128Mi"
#           }
#           limits = {
#             cpu    = "200m"
#             memory = "256Mi"
#           }
#         }
#       }

#       apiServer = {
#         service = {
#           type = "LoadBalancer"
#         }
#         resources = {
#           requests = {
#             cpu    = "500m"
#             memory = "1Gi"
#           }
#           limits = {
#             cpu    = "2"
#             memory = "2Gi"
#           }
#         }
#       }

#       dagProcessor = {
#         resources = {
#           requests = {
#             cpu    = "500m"
#             memory = "1Gi"
#           }
#           limits = {
#             cpu    = "2"
#             memory = "2Gi"
#           }
#         }
#       }

#       databaseCleanup = {
#         enabled       = true
#         retentionDays = 90
#         resources = {
#           requests = {
#             cpu    = "100m"
#             memory = "128Mi"
#           }
#           limits = {
#             cpu    = "200m"
#             memory = "256Mi"
#           }
#         }
#       }
#     })
#   ]
# }

# data "kubernetes_service_v1" "airflow" {
#   metadata {
#     name      = "apache-airflow-api-server"
#     namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#   }
#   depends_on = [helm_release.airflow]
# }

# output "airflow_ip" {
#   description = "MetalLB IP address for the Airflow API server."
#   value       = try(data.kubernetes_service_v1.airflow.status[0].load_balancer[0].ingress[0].ip, null)
# }

# resource "kubernetes_manifest" "airflow_gateway" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind       = "HTTPRoute"
#     metadata = {
#       name      = "airflow-gateway"
#       namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#     }
#     spec = {
#       parentRefs = [
#         {
#           name      = "traefik-gateway"
#           namespace = "traefik" # Add this line
#         }
#       ]
#       hostnames = ["airflow.homelab.lan"]
#       rules = [
#         {
#           matches = [
#             {
#               path = {
#                 type  = "PathPrefix"
#                 value = "/"
#               }
#             }
#           ]
#           backendRefs = [
#             {
#               name      = "apache-airflow-api-server"
#               namespace = kubernetes_namespace_v1.airflow.metadata[0].name
#               port      = 8080
#             }
#           ]
#         }
#       ]
#     }
#   }
# }
