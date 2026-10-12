resource "helm_release" "nfs_subdir" {
  name       = "nfs-subdir-external-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"
  namespace  = "kube-system"
  wait       = true

  values = [yamlencode({
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
  })]

  set = [
    {
      name  = "nfs.server"
      value = "10.23.1.11"
    },
    {
      name  = "nfs.path"
      value = "/volume1/k8s"
    },
    {
      name  = "storageClass.defaultClass"
      value = "false"
    },
    {
      name  = "storageClass.name"
      value = "nfs"
    },
    {
      name  = "storageClass.reclaimPolicy"
      value = "Retain"
    }
  ]
}

resource "kubernetes_namespace_v1" "local_path_storage" {
  metadata {
    name = "local-path-storage"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

data "kubectl_file_documents" "local_path_storage" {
  content = file("${path.module}/files/local-path-storage.yaml")
}

resource "kubectl_manifest" "local_path_storage" {
  for_each   = data.kubectl_file_documents.local_path_storage.manifests
  yaml_body  = each.value
  depends_on = [kubernetes_namespace_v1.local_path_storage]
}
