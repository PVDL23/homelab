variable "airflow_postgres" {
  description = "Airflow Postgres connection string (e.g. postgresql://user:password@host:port/dbname)"
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "traefik_username" {
  description = "Traefik dashboard username"
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "traefik_password" {
  description = "Traefik dashboard password"
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "opensearch_password" {
  description = "Opensearch DB password"
  type        = string
  ephemeral   = true
  sensitive   = true
}
