resource "vault_mount" "kvv2" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "postgres" {
  mount = vault_mount.kvv2.path
  name  = "postgres-airflow"
  data_json_wo = jsonencode(
    {
      connection = var.airflow_postgres
    }
  )
  data_json_wo_version = 1
  custom_metadata {
    max_versions = 5
  }
}

resource "vault_kv_secret_v2" "traefik" {
  mount = vault_mount.kvv2.path
  name  = "traefik-dashboard"
  data_json_wo = jsonencode(
    {
      username = var.traefik_username
      password = var.traefik_password
    }
  )
  data_json_wo_version = 2
  custom_metadata {
    max_versions = 5
  }
}

resource "vault_kv_secret_v2" "opensearch" {
  mount = vault_mount.kvv2.path
  name  = "opensearch"
  data_json_wo = jsonencode(
    {
      password = var.opensearch_password
    }
  )
  data_json_wo_version = 1
  custom_metadata {
    max_versions = 5
  }
}
