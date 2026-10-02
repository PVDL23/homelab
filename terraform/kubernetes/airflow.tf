resource "helm_release" "airflow" {
  name             = "apache-airflow"
  repository       = "https://airflow.apache.org"
  chart            = "airflow"
  namespace        = "airflow"
  create_namespace = true
  wait             = true

  values = [
    yamlencode({
      createUserJob = {
        useHelmHooks   = false
        applyCustomEnv = false
      }
      migrateDatabaseJob = {
        useHelmHooks   = false
        applyCustomEnv = false
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
    namespace = "airflow"
  }

  depends_on = [helm_release.airflow]
}

output "airflow_ip" {
  description = "MetalLB IP address for the Airflow API server."
  value       = try(data.kubernetes_service_v1.airflow.status[0].load_balancer[0].ingress[0].ip, null)
}
