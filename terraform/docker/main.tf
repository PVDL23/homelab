data "docker_registry_image" "postgres" {
  name = "postgres:18"
}

resource "docker_image" "postgres" {
  name          = data.docker_registry_image.postgres.name
  pull_triggers = [data.docker_registry_image.postgres.sha256_digest]
  keep_locally  = false
}

resource "docker_container" "postgres" {
  name  = "postgres"
  image = docker_image.postgres.image_id

  volumes {
    host_path      = "/etc/certs/server.crt"
    container_path = "/var/lib/postgresql/server.crt"
    read_only      = true
  }
  volumes {
    host_path      = "/etc/certs/server.key"
    container_path = "/var/lib/postgresql/server.key"
    read_only      = true
  }

  ports {
    external = 5432
    internal = 5432
  }

  env = [
    "POSTGRES_PASSWORD=postgres"
  ]

  command = [
    "-c", "ssl=on",
    "-c", "ssl_cert_file=/var/lib/postgresql/server.crt",
    "-c", "ssl_key_file=/var/lib/postgresql/server.key",
  ]
}
