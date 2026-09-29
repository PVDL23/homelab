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
}
