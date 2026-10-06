variable "unifi_api_url" {
  description = "Unifi API URL (e.g. https://unifi:8443)"
  type        = string
  # Credentials read from env: UNIFI_USERNAME and UNIFI_PASSWORD
}

variable "airflow_postgres" {
  description = "Airflow Postgres connection string (e.g. postgresql://user:password@host:port/dbname)"
  type        = string
  default     = "postgresql://user:pass@host:5432/db"
  ephemeral   = true
  sensitive   = true
}
