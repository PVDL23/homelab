variable "airflow_postgres" {
  description = "Airflow Postgres connection string (e.g. postgresql://user:password@host:port/dbname)"
  type        = string
  ephemeral   = true
  sensitive   = true
}
