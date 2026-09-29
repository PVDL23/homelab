locals {
  dns_records = [
    {
      name = "docker.homelab.lan"
      ip   = "${module.alma_vms["docker-01"].ip_address}"
    },
    {
      name = "vault.homelab.lan"
      ip   = "${module.alma_vms["vault-01"].ip_address}"
    }
  ]
}


resource "unifi_dns_record" "a-records" {
  for_each = { for record in local.dns_records : record.name => record }

  name        = each.value.name
  value       = each.value.ip
  record_type = "A"
  ttl         = "5m"
}
