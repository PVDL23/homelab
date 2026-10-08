resource "kubernetes_namespace_v1" "airflow" {
  metadata {
    name = "airflow"
  }
}

ephemeral "vault_kv_secret_v2" "airflow_db" {
  mount = "kvv2"
  name  = "postgres-airflow"
}

resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name      = "airflow-postgres"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
  }
  type = "generic"
  data_wo = {
    connection = tostring(ephemeral.vault_kv_secret_v2.airflow_db.data.connection)
  }
  data_wo_revision = 1
}


resource "kubernetes_persistent_volume_claim_v1" "airflow" {
  metadata {
    name      = "apache-airflow-data"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "nfs"
  }
}

resource "helm_release" "airflow" {
  name       = "apache-airflow"
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  namespace  = kubernetes_namespace_v1.airflow.metadata[0].name
  wait       = true
  depends_on = [kubernetes_persistent_volume_claim_v1.airflow]

  values = [
    yamlencode({
      images = {
        airflow = {
          repository = "rg.nl-ams.scw.cloud/data-engineering-cr/airflow-dags"
          tag        = "251008"
          pullPolicy = "IfNotPresent"
        }
      }

      airflow = {
        executor = "CeleryExecutor"
      }

      postgresql = {
        enabled = false
      }

      data = {
        metadataSecretName = kubernetes_secret_v1.postgres.metadata[0].name
      }

      databaseCleanup = {
        enabled       = true
        retentionDays = 90
      }

      createUserJob = {
        useHelmHooks   = false
        applyCustomEnv = false
      }
      migrateDatabaseJob = {
        useHelmHooks   = false
        applyCustomEnv = false
      }

      config = {
        core = {
          load_examples = "False"
          dags_folder   = "/opt/airflow/dags"
        }
        api = {
          expose_config = "True"
        }
      }

      workers = {
        extraVolumeMounts = [
          {
            name      = "airflow-data"
            mountPath = "/opt/airflow/data"
          }
        ]
        extraVolumes = [
          {
            name = "airflow-data"
            persistentVolumeClaim = {
              claimName = "apache-airflow-data"
            }
          }
        ]
      }

      apiServer = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
}

data "kubernetes_service_v1" "airflow" {
  metadata {
    name      = "apache-airflow-api-server"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
  }
  depends_on = [helm_release.airflow]
}

output "airflow_ip" {
  description = "MetalLB IP address for the Airflow API server."
  value       = try(data.kubernetes_service_v1.airflow.status[0].load_balancer[0].ingress[0].ip, null)
}

resource "kubernetes_manifest" "airflow_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "airflow-gateway"
      namespace = kubernetes_namespace_v1.airflow.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name      = "traefik-gateway"
          namespace = "traefik" # Add this line
        }
      ]
      hostnames = ["airflow.homelab.lan"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name      = "apache-airflow-api-server"
              namespace = kubernetes_namespace_v1.airflow.metadata[0].name
              port      = 8080
            }
          ]
        }
      ]
    }
  }
}
