resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.10.5"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  wait       = true

  values = [yamlencode({
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    extraObjects = [{
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "Application"
      metadata = {
        name      = "homelab"
        namespace = "argocd"
      }
      spec = {
        project = "default"
        source = {
          repoURL        = "https://codeberg.org/PvdL/homelab-gitops.git"
          targetRevision = "main"
          path           = "infrastructure/argocd"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }]
  })]
}
