resource "kubernetes_namespace_v1" "traefik" {
  metadata {
    name = "traefik"
  }
}

data "vault_kv_secret_v2" "traefik" {
  mount = "kvv2"
  name  = "traefik-dashboard"
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = kubernetes_namespace_v1.traefik.metadata[0].name
  wait       = true

  values = [
    yamlencode({
      ports = {
        web = {
          port     = 80
          nodePort = 30080
        }
        websecure = {
          port     = 443
          nodePort = 30001
        }
      }
      api = {
        dashboard = true
        insecure  = false
      }
      ingressRoute = {
        dashboard = {
          enabled     = true
          matchRule   = "Host(`traefik.homelab.lan`)"
          entryPoints = ["websecure"]
          middlewares = [
            { name = "dashboard-auth" }
          ]
        }
      }
      extraObjects = [
        {
          apiVersion = "v1"
          kind       = "Secret"
          metadata = {
            name = "dashboard-auth-secret"
          }
          type = "kubernetes.io/basic-auth"
          stringData = {
            username = data.vault_kv_secret_v2.traefik.data.username
            password = data.vault_kv_secret_v2.traefik.data.password
          }
        },
        {
          apiVersion = "traefik.io/v1alpha1"
          kind       = "Middleware"
          metadata = {
            name = "dashboard-auth"
          }
          spec = {
            basicAuth = {
              secret = "dashboard-auth-secret"
            }
          }
        }
      ]
      ingressClass = {
        enabled = false
      }
      providers = {
        kubernetesIngress = {
          enabled = false
        }
        kubernetesGateway = {
          enabled = true
        }
      }
      gateway = {
        enabled = true
        name    = "traefik-gateway"
        listeners = {
          web = {
            port     = 80
            protocol = "HTTP"
            namespacePolicy = {
              from = "All"
            }
          }
          websecure = {
            port     = 443
            protocol = "HTTPS"
            namespacePolicy = {
              from = "All"
            }
            mode = "Terminate"
            certificateRefs = [
              {
                kind  = "Secret"
                name  = "homelab-tls"
                group = ""
              }
            ]
          }
        }
      }
      log = {
        level = "INFO"
      }
      accessLog = {
        enabled = true
      }
      metrics = {
        prometheus = {
          enabled = true
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "homelab_certificate" {
  depends_on = [
    kubernetes_manifest.vault_acme_issuer,
    helm_release.traefik
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "homelab-tls"
      namespace = "traefik"
    }

    spec = {
      secretName = "homelab-tls"

      issuerRef = {
        name = "vault-acme"
        kind = "ClusterIssuer"
      }

      dnsNames = [
        "traefik.homelab.lan",
        "airflow.homelab.lan"
      ]
    }
  }
}


data "kubernetes_service_v1" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace_v1.traefik.metadata[0].name
  }

  depends_on = [helm_release.traefik]
}

output "traefik_loadbalancer_ip" {
  description = "Traefik LoadBalancer external IP address"
  value       = data.kubernetes_service_v1.traefik.status[0].load_balancer[0].ingress[0].ip
}
