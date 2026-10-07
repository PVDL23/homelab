variable "unifi_api_url" {
  description = "Unifi API URL (e.g. https://unifi:8443)"
  type        = string
  # Credentials read from env: UNIFI_USERNAME and UNIFI_PASSWORD
}

variable "airflow_postgres" {
  description = "Airflow Postgres connection string (e.g. postgresql://user:password@host:port/dbname)"
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "traefik_username" {
  description = "Traefik dashboard username"
  type        = string
  sensitive   = true
}

variable "traefik_password" {
  description = "Traefik dashboard password"
  type        = string
  sensitive   = true
}
