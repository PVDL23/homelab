resource "proxmox_virtual_environment_firewall_options" "alma_vms" {
  for_each   = local.alma_nodes
  depends_on = [module.alma_vms]

  node_name     = var.proxmox_node
  vm_id         = module.alma_vms[each.key].vm_id
  enabled       = true
  input_policy  = "DROP"
  output_policy = "ACCEPT"
}

resource "proxmox_virtual_environment_firewall_rules" "alma_vms" {
  for_each   = local.alma_nodes
  depends_on = [proxmox_virtual_environment_firewall_options.alma_vms]

  node_name = var.proxmox_node
  vm_id     = module.alma_vms[each.key].vm_id

  dynamic "rule" {
    for_each = each.value.firewall_rules
    content {
      type    = "in"
      action  = "ACCEPT"
      comment = rule.value.comment
      dport   = rule.value.dport
      proto   = rule.value.proto
    }
  }
}
