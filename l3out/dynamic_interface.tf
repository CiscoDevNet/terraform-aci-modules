resource "aci_logical_node_profile" "dynamic_logical_node_profile" {
  for_each = { for node in var.nodes : node.node_id => node if node.node_id != null }

  l3_outside_dn = aci_l3_outside.l3out.id
  name          = "pod_${each.value.pod_id}_node_${each.value.node_id}"
}

resource "aci_bgp_peer_connectivity_profile" "node_bgp_peers" {
  for_each = { for bgp_peer in local.bgp_peers_node : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_logical_node_profile.dynamic_logical_node_profile[each.value.node_id].id
  addr                = each.value.bgp_peer.ip_address != null ? each.value.bgp_peer.ip_address : each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_node : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_logical_node_to_fabric_node" "dynamic_fabric_nodes" {
  for_each = { for node in var.nodes : node.node_id => node if node.node_id != null }

  logical_node_profile_dn = aci_logical_node_profile.dynamic_logical_node_profile["${each.key}"].id
  tdn                     = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  rtr_id                  = each.value.router_id
  rtr_id_loop_back        = each.value.router_id_loopback
}

resource "aci_l3out_loopback_interface_profile" "dynamic_loopback_interfaces" {
  for_each = { for node in var.nodes : node.node_id => node if node.node_id != null }

  fabric_node_dn = aci_logical_node_to_fabric_node.dynamic_fabric_nodes["${each.key}"].id
  addr           = each.value.loopback_address
}

resource "aci_l3out_static_route" "dynamic_static_routes" {
  for_each = { for static_route in local.static_routes : static_route.route_placeholder => static_route }

  fabric_node_dn             = aci_logical_node_to_fabric_node.dynamic_fabric_nodes["${each.value.node_id}"].id
  ip                         = each.value.route.prefix
  pref                       = each.value.route.fallback_preference
  rt_ctrl                    = each.value.route.route_control == true ? "bfd" : "unspecified"
  relation_ip_rs_route_track = each.value.route.track_policy
}

resource "aci_l3out_static_route_next_hop" "dynamic_next_hop_addresses" {
  for_each = { for next_hop in local.next_hops : next_hop.next_hop_placeholder => next_hop }

  static_route_dn                    = aci_l3out_static_route.dynamic_static_routes[each.value.static_ip].id
  nh_addr                            = each.value.next_hop.next_hop_ip
  pref                               = each.value.next_hop.preference
  nexthop_profile_type               = each.value.next_hop.next_hop_profile_type
  relation_ip_rs_nexthop_route_track = each.value.next_hop.track_policy
  relation_ip_rs_nh_track_member     = each.value.next_hop.track_member
}

resource "aci_logical_interface_profile" "dynamic_logical_interface_profile_ip" {
  for_each                = { for idx, interface in var.nodes : idx => interface if contains([for nd_id in local.ip : nd_id.node_id == var.nodes[idx].node_id], true) }
  logical_node_profile_dn = aci_logical_node_profile.dynamic_logical_node_profile["${each.value.node_id}"].id
  name                    = "pod_${each.value.pod_id}_node_${each.value.node_id}_ipv4"
}

resource "aci_logical_interface_profile" "dynamic_logical_interface_profile_ipv6" {
  for_each                = { for idx, interface in var.nodes : idx => interface if contains([for nd_id in local.ipv6 : nd_id.node_id == var.nodes[idx].node_id], true) }
  logical_node_profile_dn = aci_logical_node_profile.dynamic_logical_node_profile["${each.value.node_id}"].id
  name                    = "pod_${each.value.pod_id}_node_${each.value.node_id}_ipv6"
}

resource "aci_l3out_path_attachment" "dynamic_l3out_path_ip" {
  for_each = { for idx, path in local.ip : idx => path }

  logical_interface_profile_dn = compact([for id in range(length(var.nodes)) : (each.value.node_id == var.nodes[id].node_id) ? aci_logical_interface_profile.dynamic_logical_interface_profile_ip[id].id : ""])[0]
  target_dn                    = (each.value.path.port != null || each.value.path.channel != null) ? join("", ["topology/pod-${each.value.pod_id}/paths-${each.value.node_id}/pathep-[", split("_${each.value.node_id}", "${each.value.path_placeholder}")[0], "]"]) : "topology/pod-${each.value.pod_id}/protpaths-${each.value.node_id}-${each.value.node2_id}/pathep-[${each.key}]"
  if_inst_t                    = (each.value.path.vlan == null) ? "l3-port" : ((each.value.path.svi == true) ? "ext-svi" : "sub-interface")
  addr                         = each.value.path.ip
  encap                        = each.value.path.vlan != null ? "vlan-${each.value.path.vlan}" : null
}

resource "aci_l3out_path_attachment" "dynamic_l3out_path_ipv6" {
  for_each = { for idx, path in local.ipv6 : idx => path }

  logical_interface_profile_dn = compact([for id in range(length(var.nodes)) : (each.value.node_id == var.nodes[id].node_id) ? aci_logical_interface_profile.dynamic_logical_interface_profile_ipv6[id].id : ""])[0]
  target_dn                    = (each.value.path.port != null || each.value.path.channel != null) ? join("", ["topology/pod-${each.value.pod_id}/paths-${each.value.node_id}/pathep-[", split("_${each.value.node_id}", "${each.value.path_placeholder}")[0], "]"]) : "topology/pod-${each.value.pod_id}/protpaths-${each.value.node_id}-${each.value.node2_id}/pathep-[${each.key}]"
  if_inst_t                    = (each.value.path.vlan == null) ? "l3-port" : ((each.value.path.svi == true) ? "ext-svi" : "sub-interface")
  addr                         = each.value.path.ipv6
  encap                        = each.value.path.vlan != null ? "vlan-${each.value.path.vlan}" : null
}

resource "aci_l3out_path_attachment_secondary_ip" "secondary_ip_address" {
  for_each = { for addr in local.secondary_address_interface_ip : addr.address_placeholder => addr }

  l3out_path_attachment_dn = compact([for id, path in local.ip : (each.value.address_id == path.path_placeholder) ? aci_l3out_path_attachment.dynamic_l3out_path_ip[id].id : ""])[0]
  addr                     = each.value.address
}

resource "aci_l3out_path_attachment_secondary_ip" "secondary_ipv6_address" {
  for_each = { for addr in local.secondary_address_interface_ipv6 : addr.address_placeholder => addr }

  l3out_path_attachment_dn = compact([for id, path in local.ipv6 : (each.value.address_id == path.path_placeholder) ? aci_l3out_path_attachment.dynamic_l3out_path_ipv6[id].id : ""])[0]
  addr                     = each.value.address
  ipv6_dad                 = "disabled"
}

resource "aci_bgp_peer_connectivity_profile" "node_bgp_peers_global" {
  for_each = { for bgp_peer in local.bgp_peer_global_to_node : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_logical_node_profile.dynamic_logical_node_profile[each.value.node_id].id
  addr                = each.value.bgp_peer.ip_address != null ? each.value.bgp_peer.ip_address : each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_global_to_node : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "interfaces_bgp_peer_from_global_ip" {
  for_each = { for bgp_peer in local.bgp_peer_global_to_interface_ip : bgp_peer.bgp_peer_dn.dn => bgp_peer if bgp_peer.bgp_peer_dn != null }

  parent_dn           = aci_l3out_path_attachment.dynamic_l3out_path_ip[each.key].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_global_route_control_profiles_interface_ip : control.control_placeholder => control.control if each.value.bgp_peer_dn == control.bgp_peer_dn }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "interfaces_bgp_peer_from_global_ipv6" {
  for_each = { for bgp_peer in local.bgp_peer_global_to_interface_ipv6 : bgp_peer.bgp_peer_dn.dn => bgp_peer if bgp_peer.bgp_peer_dn != null }

  parent_dn           = aci_l3out_path_attachment.dynamic_l3out_path_ipv6[each.key].id
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_global_route_control_profiles_interface_ipv6 : control.control_placeholder => control.control if each.value.bgp_peer_dn == control.bgp_peer_dn }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "interfaces_bgp_peer_from_node_ip" {
  for_each = { for bgp_peer in local.bgp_peers_node_to_interface_ip : bgp_peer.bgp_peer_dn.dn => bgp_peer if bgp_peer.bgp_peer_dn != null }

  parent_dn           = aci_l3out_path_attachment.dynamic_l3out_path_ip[each.key].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_node_to_interface_ip : control.control_placeholder => control.control if each.value.bgp_peer_dn == control.bgp_peer_dn }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "interfaces_bgp_peer_from_node_ipv6" {
  for_each = { for bgp_peer in local.bgp_peers_node_to_interface_ipv6 : bgp_peer.bgp_peer_dn.dn => bgp_peer if bgp_peer.bgp_peer_dn != null }

  parent_dn           = aci_l3out_path_attachment.dynamic_l3out_path_ipv6[each.key].id
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_node_to_interface_ipv6 : control.control_placeholder => control.control if each.value.bgp_peer_dn == control.bgp_peer_dn }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "interface_bgp_peer_ip" {
  for_each = { for bgp_peer in local.bgp_peers_interface_ip : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = compact([for id, path in local.ip : (each.value.bgp_peer_id == path.path_placeholder) ? aci_l3out_path_attachment.dynamic_l3out_path_ip[id].id : ""])[0]
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_interface_ip : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "interface_bgp_peer_ipv6" {
  for_each = { for bgp_peer in local.bgp_peers_interface_ipv6 : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = compact([for id, path in local.ipv6 : (each.value.bgp_peer_id == path.path_placeholder) ? aci_l3out_path_attachment.dynamic_l3out_path_ipv6[id].id : ""])[0]
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_interface_ipv6 : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_logical_node_profile" "dynamic_logical_node_profile_floating" {
  count = (var.floating_svi.floating_ip != null || var.floating_svi.floating_ipv6 != null) ? 1 : 0

  l3_outside_dn = aci_l3_outside.l3out.id
  name          = "floating_svi"
}

resource "aci_logical_interface_profile" "dynamic_logical_interface_profile_floating_ip" {
  count = var.floating_svi.floating_ip != null ? 1 : 0

  logical_node_profile_dn = aci_logical_node_profile.dynamic_logical_node_profile_floating[0].id
  name                    = "floating_svi_ipv4"
}

resource "aci_logical_interface_profile" "dynamic_logical_interface_profile_floating_ipv6" {
  count = var.floating_svi.floating_ipv6 != null ? 1 : 0

  logical_node_profile_dn = aci_logical_node_profile.dynamic_logical_node_profile_floating[0].id
  name                    = "floating_svi_ipv6"
}

resource "aci_l3out_floating_svi" "floating_svi_ip" {
  for_each = { for path in var.floating_svi.anchor_nodes : path.ip_address => path if path.ip_address != null }

  logical_interface_profile_dn = aci_logical_interface_profile.dynamic_logical_interface_profile_floating_ip[0].id
  node_dn                      = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  encap                        = "vlan-${each.value.vlan}"
  addr                         = each.key
  if_inst_t                    = "ext-svi"
  annotation                   = each.value.annotation
  description                  = each.value.description
  autostate                    = each.value.autostate
  encap_scope                  = each.value.encap_scope
  #ipv6_dad                     = each.value.ipv6_dad
  #ll_addr                      = each.value.link_local_address
  mac         = each.value.mac
  mode        = each.value.mode
  mtu         = each.value.mtu
  target_dscp = each.value.target_dscp

  relation_l3ext_rs_dyn_path_att {
    tdn              = var.floating_svi.domain_dn
    floating_address = var.floating_svi.floating_ip
    # encap = "vlan-${var.floating_svi.vlan}"
    forged_transmit  = var.floating_svi.forged_transmit == true ? "Enabled" : "Disabled"
    mac_change       = var.floating_svi.mac_change == true ? "Enabled" : "Disabled"
    promiscuous_mode = var.floating_svi.promiscuous_mode == true ? "Enabled" : "Disabled"
  }
}

resource "aci_l3out_floating_svi" "floating_svi_ipv6" {
  for_each = { for path in var.floating_svi.anchor_nodes : path.ipv6_address => path if path.ipv6_address != null }

  logical_interface_profile_dn = aci_logical_interface_profile.dynamic_logical_interface_profile_floating_ipv6[0].id
  node_dn                      = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  encap                        = "vlan-${each.value.vlan}"
  addr                         = each.key
  if_inst_t                    = "ext-svi"
  annotation                   = each.value.annotation
  description                  = each.value.description
  autostate                    = each.value.autostate
  encap_scope                  = each.value.encap_scope
  ipv6_dad                     = each.value.ipv6_dad
  ll_addr                      = each.value.link_local_address
  mac                          = each.value.mac
  mode                         = each.value.mode
  mtu                          = each.value.mtu
  target_dscp                  = each.value.target_dscp

  relation_l3ext_rs_dyn_path_att {
    tdn              = var.floating_svi.domain_dn
    floating_address = var.floating_svi.floating_ipv6
    # encap = "vlan-${var.floating_svi.vlan}"
    forged_transmit  = var.floating_svi.forged_transmit == true ? "Enabled" : "Disabled"
    mac_change       = var.floating_svi.mac_change == true ? "Enabled" : "Disabled"
    promiscuous_mode = var.floating_svi.promiscuous_mode == true ? "Enabled" : "Disabled"
  }
}

resource "aci_l3out_path_attachment_secondary_ip" "floating_svi_secondary_ip_address" {
  for_each = { for addr in local.floating_svi_secondary_ip_address : addr.secondary_address_placeholder => addr }

  l3out_path_attachment_dn = "${aci_l3out_floating_svi.floating_svi_ip[each.value.secondary_address_id].id}/rsdynPathAtt-[${var.floating_svi.domain_dn}]"
  addr                     = each.value.secondary_address
}

resource "aci_l3out_path_attachment_secondary_ip" "floating_svi_secondary_ipv6_address" {
  for_each = { for addr in local.floating_svi_secondary_ipv6_address : addr.secondary_address_placeholder => addr }

  l3out_path_attachment_dn = "${aci_l3out_floating_svi.floating_svi_ipv6[each.value.secondary_address_id].id}/rsdynPathAtt-[${var.floating_svi.domain_dn}]"
  addr                     = each.value.secondary_address
  ipv6_dad                 = "disabled"
}

resource "aci_l3out_path_attachment_secondary_ip" "floating_svi_anchor_node_secondary_ip_address" {
  for_each = { for addr in local.anchor_node_secondary_ip_address : addr.secondary_address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_floating_svi.floating_svi_ip[each.value.secondary_address_id].id
  addr                     = each.value.secondary_address
}

resource "aci_l3out_path_attachment_secondary_ip" "floating_svi_anchor_node_secondary_ipv6_address" {
  for_each = { for addr in local.anchor_node_secondary_ipv6_address : addr.secondary_address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_floating_svi.floating_svi_ipv6[each.value.secondary_address_id].id
  addr                     = each.value.secondary_address
}

resource "aci_bgp_peer_connectivity_profile" "bgp_peer_anchor_node_ip" {
  for_each = { for bgp_peer in local.anchor_node_bgp_peer_ip_address : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_floating_svi.floating_svi_ip[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.anchor_node_bgp_peer_route_control_profiles_ip : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "bgp_peer_anchor_node_ipv6" {
  for_each = { for bgp_peer in local.anchor_node_bgp_peer_ipv6_address : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_floating_svi.floating_svi_ipv6[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.anchor_node_bgp_peer_route_control_profiles_ipv6 : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_logical_node_profile" "vpc_dynamic_logical_node_profile" {
  for_each = { for vpc in local.vpc_logical_nodes : vpc.logical_node_name => vpc if vpc.logical_node_name != null }

  l3_outside_dn = aci_l3_outside.l3out.id
  name          = each.key
}

resource "aci_logical_node_to_fabric_node" "vpc_dynamic_fabric_nodes" {
  for_each = { for node in local.vpc_nodes : node.node_id => node }

  logical_node_profile_dn = aci_logical_node_profile.vpc_dynamic_logical_node_profile[each.value.logical_node_name].id
  tdn                     = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  rtr_id                  = each.value.node.router_id
  rtr_id_loop_back        = each.value.node.router_id_loopback
}

resource "aci_l3out_loopback_interface_profile" "vpc_dynamic_loopback_interfaces" {
  for_each = { for node in local.vpc_nodes : node.node_id => node if node.node.loopback_address != null }

  fabric_node_dn = aci_logical_node_to_fabric_node.vpc_dynamic_fabric_nodes[each.key].id
  addr           = each.value.node.loopback_address
}

resource "aci_l3out_static_route" "vpc_dynamic_static_routes" {
  for_each = { for static_route in local.vpc_static_routes : static_route.route_placeholder => static_route }

  fabric_node_dn             = aci_logical_node_to_fabric_node.vpc_dynamic_fabric_nodes[each.value.node_id].id
  ip                         = each.value.route.prefix
  pref                       = each.value.route.fallback_preference
  rt_ctrl                    = each.value.route.route_control == true ? "bfd" : "unspecified"
  relation_ip_rs_route_track = each.value.route.track_policy
}

resource "aci_l3out_static_route_next_hop" "vpc_dynamic_next_hop_addresses" {
  for_each = { for next_hop in local.vpc_next_hops : next_hop.next_hop_placeholder => next_hop }

  static_route_dn                    = aci_l3out_static_route.vpc_dynamic_static_routes[each.value.route_placeholder].id
  nh_addr                            = each.value.hop.next_hop_ip
  pref                               = each.value.hop.preference
  nexthop_profile_type               = each.value.hop.next_hop_profile_type
  relation_ip_rs_nexthop_route_track = each.value.hop.track_policy
  relation_ip_rs_nh_track_member     = each.value.hop.track_member
}

resource "aci_logical_interface_profile" "vpc_dynamic_logical_interface_profile_ip" {
  for_each = { for interface in local.vpc_ip : interface.logical_node_name => interface }

  logical_node_profile_dn = aci_logical_node_profile.vpc_dynamic_logical_node_profile[each.value.logical_node_name].id
  name                    = "${each.value.logical_node_name}_ipv4"
}

resource "aci_logical_interface_profile" "vpc_dynamic_logical_interface_profile_ipv6" {
  for_each = { for interface in local.vpc_ipv6 : interface.logical_node_name => interface }

  logical_node_profile_dn = aci_logical_node_profile.vpc_dynamic_logical_node_profile[each.value.logical_node_name].id
  name                    = "${each.value.logical_node_name}_ipv6"
}

resource "aci_l3out_path_attachment" "vpc_l3out_path_ip" {
  for_each = { for interface in local.vpc_logical_interfaces_ip : interface.interface_placeholder => interface }

  logical_interface_profile_dn = aci_logical_interface_profile.vpc_dynamic_logical_interface_profile_ip[each.value.logical_node_name].id
  target_dn                    = "topology/pod-${each.value.pod_id}/protpaths-${each.value.node_ids}/pathep-[${each.value.interface.channel}]"
  if_inst_t                    = "ext-svi"
  addr                         = "0.0.0.0"
  encap                        = each.value.interface.vlan != null ? "vlan-${each.value.interface.vlan}" : null
}

resource "aci_l3out_path_attachment" "vpc_l3out_path_ipv6" {
  for_each = { for interface in local.vpc_logical_interfaces_ipv6 : interface.interface_placeholder => interface }

  logical_interface_profile_dn = aci_logical_interface_profile.vpc_dynamic_logical_interface_profile_ipv6[each.value.logical_node_name].id
  target_dn                    = "topology/pod-${each.value.pod_id}/protpaths-${each.value.node_ids}/pathep-[${each.value.interface.channel}]"
  if_inst_t                    = "ext-svi"
  addr                         = "0.0.0.0"
  encap                        = each.value.interface.vlan != null ? "vlan-${each.value.interface.vlan}" : null
}

resource "aci_l3out_vpc_member" "vpc_side_A_ip" {
  for_each = { for path in local.vpc_logical_interfaces_ip : path.interface_placeholder => path }

  leaf_port_dn = aci_l3out_path_attachment.vpc_l3out_path_ip[each.key].id
  side         = "A"
  addr         = each.value.interface.side_a.ip
}

resource "aci_l3out_vpc_member" "vpc_side_B_ip" {
  for_each = { for path in local.vpc_logical_interfaces_ip : path.interface_placeholder => path }

  leaf_port_dn = aci_l3out_path_attachment.vpc_l3out_path_ip[each.key].id
  side         = "B"
  addr         = each.value.interface.side_b.ip
}

resource "aci_l3out_vpc_member" "vpc_side_A_ipv6" {
  for_each = { for path in local.vpc_logical_interfaces_ipv6 : path.interface_placeholder => path }

  leaf_port_dn = aci_l3out_path_attachment.vpc_l3out_path_ipv6[each.key].id
  side         = "A"
  addr         = each.value.interface.side_a.ipv6
  ll_addr      = each.value.interface.side_a.link_local_address
}

resource "aci_l3out_vpc_member" "vpc_side_B_ipv6" {
  for_each = { for path in local.vpc_logical_interfaces_ipv6 : path.interface_placeholder => path }

  leaf_port_dn = aci_l3out_path_attachment.vpc_l3out_path_ipv6[each.key].id
  side         = "B"
  addr         = each.value.interface.side_b.ipv6
  ll_addr      = each.value.interface.side_b.link_local_address
}

resource "aci_l3out_path_attachment_secondary_ip" "vpc_secondary_ip_addr_A" {
  for_each = { for addr in local.vpc_secondary_ip_a : addr.address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_vpc_member.vpc_side_A_ip[each.value.interface_placeholder].id
  addr                     = each.value.address
}

resource "aci_l3out_path_attachment_secondary_ip" "vpc_secondary_ip_addr_B" {
  for_each = { for addr in local.vpc_secondary_ip_b : addr.address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_vpc_member.vpc_side_B_ip[each.value.interface_placeholder].id
  addr                     = each.value.address
}

resource "aci_l3out_path_attachment_secondary_ip" "vpc_secondary_ipv6_addr_A" {
  for_each = { for addr in local.vpc_secondary_ipv6_a : addr.address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_vpc_member.vpc_side_A_ipv6[each.value.interface_placeholder].id
  addr                     = each.value.address
}

resource "aci_l3out_path_attachment_secondary_ip" "vpc_secondary_ipv6_addr_B" {
  for_each = { for addr in local.vpc_secondary_ipv6_b : addr.address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_vpc_member.vpc_side_B_ipv6[each.value.interface_placeholder].id
  addr                     = each.value.address
}

resource "aci_bgp_peer_connectivity_profile" "vpc_interface_bgp_peer_ip" {
  for_each = { for bgp_peer in local.vpc_bgp_peers_interface_ip : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.vpc_l3out_path_ip[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.vpc_bgp_peer_route_control_profiles_interface_ip : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "vpc_interface_bgp_peer_ipv6" {
  for_each = { for bgp_peer in local.vpc_bgp_peers_interface_ipv6 : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.vpc_l3out_path_ipv6[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.vpc_bgp_peer_route_control_profiles_interface_ipv6 : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "vpc_node_bgp_peers" {
  for_each = { for bgp_peer in local.vpc_bgp_peer_global_to_node : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_logical_node_profile.vpc_dynamic_logical_node_profile[each.value.logical_node_name].id
  addr                = each.value.bgp_peer.ip_address != null ? each.value.bgp_peer.ip_address : each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.vpc_bgp_peer_route_control_profiles_global_to_node : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "vpc_interfaces_bgp_peer_from_global_ip" {
  for_each = { for bgp_peer in local.vpc_bgp_peers_global_to_interface_ip : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.vpc_l3out_path_ip[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.vpc_bgp_peer_route_control_profiles_global_to_interface_ip : control.control_placeholder => control.control if each.value.bgp_peer_placeholder == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "vpc_interfaces_bgp_peer_from_global_ipv6" {
  for_each = { for bgp_peer in local.vpc_bgp_peers_global_to_interface_ipv6 : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.vpc_l3out_path_ipv6[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.vpc_bgp_peer_route_control_profiles_global_to_interface_ipv6 : control.control_placeholder => control.control if each.value.bgp_peer_placeholder == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "global_vpc_node_bgp_peers" {
  for_each = { for bgp_peer in local.bgp_peer_global_to_vpc_nodes : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_logical_node_profile.vpc_dynamic_logical_node_profile[each.value.logical_node_name].id
  addr                = each.value.bgp_peer.ip_address != null ? each.value.bgp_peer.ip_address : each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_global_to_vpc_nodes : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "global_vpc_interfaces_bgp_peer_ip" {
  for_each = { for bgp_peer in local.bgp_peer_global_to_interface_ip_vpc : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.vpc_l3out_path_ip[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_global_route_control_profiles_interface_ip_vpc : control.control_placeholder => control.control if each.value.bgp_peer_placeholder == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "global_vpc_interfaces_bgp_peer_ipv6" {
  for_each = { for bgp_peer in local.bgp_peer_global_to_interface_ipv6_vpc : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.vpc_l3out_path_ipv6[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ipv6_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as_cnt
  annotation          = each.value.bgp_peer.annotation
  ctrl                = [for control in(each.value.bgp_peer.bgp_controls != null) ? keys(each.value.bgp_peer.bgp_controls) : [] : replace(control, "_", "-") if((control != null) ? each.value.bgp_peer.bgp_controls[control] == true : null)]
  name_alias          = each.value.bgp_peer.alias
  password            = each.value.bgp_peer.password
  peer_ctrl           = each.value.bgp_peer.peer_controls
  private_a_sctrl     = each.value.bgp_peer.private_as_control
  ttl                 = each.value.bgp_peer.ebgp_multihop_ttl
  weight              = each.value.bgp_peer.weight
  as_number           = each.value.bgp_peer.as_number
  local_asn           = each.value.bgp_peer.local_asn
  local_asn_propagate = each.value.bgp_peer.local_as_number_config
  admin_state         = each.value.bgp_peer.admin_state

  dynamic "relation_bgp_rs_peer_to_profile" {
    for_each = { for control in local.bgp_peer_route_control_profiles_global_to_interface_ipv6_vpc : control.control_placeholder => control.control if each.value.bgp_peer_placeholder == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}
