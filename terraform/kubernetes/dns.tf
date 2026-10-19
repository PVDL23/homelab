# locals {
#   dns_records = [
#     {
#       name = "*.homelab.lan"
#       ip   = "${data.kubernetes_service_v1.traefik.status[0].load_balancer[0].ingress[0].ip}"
#     }
#   ]
# }


# resource "unifi_dns_record" "a-records" {
#   for_each = { for record in local.dns_records : record.name => record }

#   name        = each.value.name
#   value       = each.value.ip
#   record_type = "A"
#   ttl         = "5m"
# }
