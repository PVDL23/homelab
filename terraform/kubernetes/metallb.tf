resource "kubernetes_namespace_v1" "metallb" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace_v1.metallb.metadata[0].name
  wait       = true

  values = [yamlencode({
    controller = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "256Mi"
        }
      }
    }
    speaker = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    }
    frr = {
      enabled = true
      resources = {
        requests = {
          cpu    = "200m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    }
  })]
}

resource "kubernetes_manifest" "metallb_ip_pool" {
  depends_on = [helm_release.metallb]
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"

    metadata = {
      name      = "homelab-pool"
      namespace = kubernetes_namespace_v1.metallb.metadata[0].name
    }

    spec = {
      addresses = [
        "10.23.2.30-10.23.2.250"
      ]
    }
  }
}

resource "kubernetes_manifest" "metallb_l2_advert" {
  depends_on = [kubernetes_manifest.metallb_ip_pool]
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"

    metadata = {
      name      = "l2-advert"
      namespace = kubernetes_namespace_v1.metallb.metadata[0].name
    }

    spec = {
      ipAddressPools = [
        "homelab-pool"
      ]
    }
  }
}
