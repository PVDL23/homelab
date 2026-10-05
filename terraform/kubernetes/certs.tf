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
