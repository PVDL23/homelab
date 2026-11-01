resource "kubernetes_namespace_v1" "flux_system" {
  metadata {
    name = "flux-system"
  }
}

resource "helm_release" "flux" {
  name       = "flux"
  repository = "https://fluxcd.io/charts"
  chart      = "flux"
  version    = "2.10.1"
  namespace  = kubernetes_namespace_v1.flux_system.metadata[0].name
  wait       = true

  values = [yamlencode({
    git = {
      url = "ssh://git@codeberg.org/PvdL/homelab-gitops.git"
      secretName = "flux-system"
      secretNamespace = "flux-system"
    }
  })]
}
