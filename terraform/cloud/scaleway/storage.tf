# Object Storage
resource "scaleway_object_bucket" "nas_backup" {
  name          = var.object_storage_bucket_name
  region        = "fr-par"
  force_destroy = false
  project_id    = scaleway_account_project.homelab.id
  tags = {
    managed-by = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "scaleway_object_bucket_acl" "nas_backup" {
  bucket     = scaleway_object_bucket.nas_backup.id
  acl        = "private"
  project_id = scaleway_account_project.homelab.id
}

resource "scaleway_object_bucket" "inat_lake" {
  name          = "inat-lake"
  region        = "fr-par"
  force_destroy = true
  project_id    = scaleway_account_project.homelab.id
  tags = {
    managed-by = "terraform"
  }
}
