resource "kubernetes_namespace_v1" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "config.gatewayAPI.enabled"
      value = "true"
    }
  ]
}

resource "kubernetes_manifest" "vault_acme_issuer" {
  depends_on = [
    helm_release.cert_manager
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "vault-acme"
    }

    spec = {
      acme = {
        email    = "admin@homelab.lan"
        server   = "https://10.23.1.30:8200/v1/pki_int/acme/directory"
        caBundle = filebase64("${path.module}/files/vault-tls.crt")

        privateKeySecretRef = {
          name = "vault-acme-account-key"
        }

        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [
                  {
                    name      = "traefik-gateway"
                    namespace = "traefik"
                    kind      = "Gateway"
                  }
                ]
              }
            }
          }
        ]
      }
    }
  }
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
            username = "admin"
            password = "admin"
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
