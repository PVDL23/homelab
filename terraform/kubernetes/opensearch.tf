resource "kubernetes_namespace_v1" "opensearch" {
  metadata {
    name = "opensearch"
  }
}

ephemeral "vault_kv_secret_v2" "opensearch" {
  mount = "kvv2"
  name  = "opensearch"
}

resource "kubernetes_secret_v1" "opensearch" {
  metadata {
    name      = "opensearch-password"
    namespace = kubernetes_namespace_v1.opensearch.metadata[0].name
  }
  type = "generic"
  data_wo = {
    password = ephemeral.vault_kv_secret_v2.opensearch.data.password
  }
  data_wo_revision = 1
}


resource "helm_release" "opensearch" {
  name       = "opensearch"
  repository = "https://opensearch-project.github.io/helm-charts/"
  chart      = "opensearch"
  namespace  = kubernetes_namespace_v1.opensearch.metadata[0].name
  wait       = true

  values = [yamlencode({
    config = {
      cluster = {
        name = "opensearch-cluster"
      }
      network = {
        host = "0.0.0.0"
      }
    }
    replicaCount = 1
    resources = {
      requests = {
        cpu    = "1"
        memory = "4Gi"
      }
      limits = {
        cpu    = "2"
        memory = "8Gi"
      }
    }
    jvmOptions = "-Xms2g -Xmx2g"
    volumeSize = "20Gi"
    extraEnvs = [
      {
        name = "OPENSEARCH_INITIAL_ADMIN_PASSWORD"
        valueFrom = {
          secretKeyRef = {
            namespace = kubernetes_secret_v1.opensearch.metadata[0].namespace
            name      = kubernetes_secret_v1.opensearch.metadata[0].name
            key       = "password"
          }
        }
      }
    ]
    })
  ]
}

resource "helm_release" "opensearch-dashboard" {
  name       = "opensearch-dashboards"
  repository = "https://opensearch-project.github.io/helm-charts/"
  chart      = "opensearch-dashboards"
  namespace  = kubernetes_namespace_v1.opensearch.metadata[0].name
  wait       = true

  values = [yamlencode({
    resources = {
      requests = {
        cpu    = "200m"
        memory = "512Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "1Gi"
      }
    }
  })]
}
