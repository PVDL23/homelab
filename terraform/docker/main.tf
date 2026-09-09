data "docker_registry_image" "ubuntu" {
  name = "ubuntu:precise"
}

resource "docker_image" "ubuntu" {
  name          = data.docker_registry_image.ubuntu.name
  pull_triggers = [data.docker_registry_image.ubuntu.sha256_digest]
  keep_locally  = false
}

resource "docker_container" "ubuntu" {
  name  = "foo"
  image = docker_image.ubuntu.image_id
}
