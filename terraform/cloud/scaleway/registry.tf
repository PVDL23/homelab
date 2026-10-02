resource "scaleway_registry_namespace" "data-engineering" {
  name        = "data-engineering-cr"
  description = "Data Engineering container registry"
  is_public   = true
  region      = "nl-ams"
}
