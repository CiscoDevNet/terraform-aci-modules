locals {

  external_epg_route_control_profiles = {
    for external_epg in var.external_epgs : external_epg.name => external_epg.route_control_profiles
    if external_epg.route_control_profiles != null
  }

  external_epg_subnets = (flatten([
    for external_epg in var.external_epgs : [
      for subnet in(external_epg.subnets == null) ? [] : external_epg.subnets : {
        external_epg_name  = external_epg.name
        subnet_placeholder = "[${subnet.ip}]_${external_epg.name}"
        subnet             = subnet
      }
    ]
  ]))

  external_epg_subnet_route_control_profiles = {
    for subnet in local.external_epg_subnets : subnet.subnet.ip => subnet.subnet.route_control_profiles
    if subnet.subnet.route_control_profiles != null
  }

  route_control_contexts = (flatten([
    for profile in var.route_map_control_profiles : [
      for context in(profile.contexts == null) ? [] : profile.contexts : {
        profile_name        = profile.name
        context_placeholder = context.name
        context             = context
      }
    ]
  ]))

  route_control_context_match_rules_dn = {
    for context in local.route_control_contexts : context.context.name => context.context.match_rules_dn
    if context.context.match_rules_dn != null
  }

  logical_nodes = (flatten([
    for profile in var.logical_node_profiles : [
      for node in(profile.nodes == null) ? [] : profile.nodes : {
        profile_name     = profile.name
        node_placeholder = "[pod-${node.pod_id}/node-${node.node_id}]"
        node             = node
      }
    ]
  ]))

  bgp_peers_nodes = (flatten([
    for profile in var.logical_node_profiles : [
      for bgp_peer in(profile.bgp_peers_nodes == null) ? [] : profile.bgp_peers_nodes : {
        bgp_peer_id          = profile.name
        bgp_peer_placeholder = "[${bgp_peer.ip_address}]"
        bgp_peer             = bgp_peer
      }
    ]
  ]))

  bgp_peer_nodes_route_control_profiles = (flatten([
    for bgp in local.bgp_peers_nodes : [
      for control in(bgp.bgp_peer.route_control_profiles == null) ? [] : bgp.bgp_peer.route_control_profiles : {
        control_id           = bgp.bgp_peer.ip_address
        control_placeholder  = "[${control.target_dn}]_[${control.direction}]_${bgp.bgp_peer_placeholder}"
        bgp_peer_placeholder = bgp.bgp_peer_placeholder
        control              = control
      }
    ]
  ]))

  logical_nodes_loopback_addresses = (flatten([
    for node in local.logical_nodes : [
      for loopback_address in(node.node.loopback_address == null) ? [] : [node.node.loopback_address] : {
        address_node_dn     = "[pod-${node.node.pod_id}/node-${node.node.node_id}]"
        address_placeholder = loopback_address
        ip                  = loopback_address
      }
    ]
  ]))

  logical_nodes_static_routes = (flatten([
    for node in local.logical_nodes : [
      for static_route in(node.node.static_routes == null) ? [] : node.node.static_routes : {
        address_node_dn   = "[pod-${node.node.pod_id}/node-${node.node.node_id}]"
        route_placeholder = "[${static_route.ip}]_[pod-${node.node.pod_id}/node-${node.node.node_id}]"
        route             = static_route
      }
    ]
  ]))

  static_route_next_hops = (flatten([
    for static_routes in local.logical_nodes_static_routes : [
      for hop in(static_routes.route.next_hop_addresses == null) ? [] : static_routes.route.next_hop_addresses : {
        static_ip            = static_routes.route_placeholder
        next_hop_placeholder = "[${hop.next_hop_ip}]_[${static_routes.route.ip}]_${static_routes.address_node_dn}"
        next_hop             = hop
      }
    ]
  ]))

  logical_interfaces = (flatten([
    for profile in var.logical_node_profiles : [
      for interface in(profile.interfaces == null) ? [] : profile.interfaces : {
        profile_name          = profile.name
        interface_placeholder = interface.name
        interface             = interface
      }
    ]
  ]))

  hsrp_groups = (flatten([
    for interface in local.logical_interfaces : [
      for hsrp in(interface.interface.hsrp == null) ? [] : [interface.interface.hsrp] : [
        for group in(hsrp.hsrp_groups == null) ? [] : hsrp.hsrp_groups : {
          hsrp_group_id          = interface.interface.name
          hsrp_group_placeholder = "[${group.name}]_[${interface.interface.name}]"
          hsrp_group             = group
        }
      ]
    ]
  ]))

  hsrp_secondary_vips = (flatten([
    for group in local.hsrp_groups : [
      for vip in(group.hsrp_group.secondary_virtual_ips == null) ? [] : group.hsrp_group.secondary_virtual_ips : {
        vip_id          = group.hsrp_group_placeholder
        vip_placeholder = "[${vip}]_[${group.hsrp_group.name}]"
        vip             = vip
      }
    ]
  ]))

  paths = (flatten([
    for interface in local.logical_interfaces : [
      for path in(interface.interface.paths == null) ? [] : interface.interface.paths : {
        path_id          = interface.interface.name
        path_placeholder = "[${path.interface_type}]_[${path.path_type}]_[${path.ip_address}]_[${interface.interface.name}]"
        path             = path
      }
    ]
  ]))

  bgp_peers = (flatten([
    for elements in local.paths : [
      for bgp_peer in(elements.path.bgp_peers == null) ? [] : elements.path.bgp_peers : {
        bgp_peer_id          = elements.path_placeholder
        bgp_peer_placeholder = "[${bgp_peer.ip_address}]_${elements.path_placeholder}"
        bgp_peer             = bgp_peer
      }
    ]
  ]))

  bgp_peer_route_control_profiles = (flatten([
    for bgp in local.bgp_peers : [
      for control in(bgp.bgp_peer.route_control_profiles == null) ? [] : bgp.bgp_peer.route_control_profiles : {
        control_id           = bgp.bgp_peer.ip_address
        control_placeholder  = "[${control.target_dn}]_[${control.direction}]_${bgp.bgp_peer_placeholder}"
        bgp_peer_placeholder = bgp.bgp_peer_placeholder
        control              = control
      }
    ]
  ]))

  secondary_address = (flatten([
    for elements in local.paths : [
      for secondary_address in(elements.path.secondary_addresses == null) ? [] : elements.path.secondary_addresses : {
        secondary_address_id          = elements.path_placeholder
        secondary_address_placeholder = "[${secondary_address.ip_address}]_[${elements.path.ip_address}]"
        secondary_address             = secondary_address
      }
    ]
  ]))

  address_A = (flatten([
    for elements in local.paths : [
      for address in(elements.path.side_A == null) ? [] : [elements.path.side_A] : {
        address_A_id          = elements.path_placeholder
        address_A_placeholder = "[${address.ip_address}]_[${elements.path.ip_address}]_[${elements.path_id}]"
        address_A             = address
      }
    ]
  ]))

  address_B = (flatten([
    for elements in local.paths : [
      for address in(elements.path.side_B == null) ? [] : [elements.path.side_B] : {
        address_B_id          = elements.path_placeholder
        address_B_placeholder = "[${address.ip_address}]_[${elements.path.ip_address}]_[${elements.path_id}]"
        address_B             = address
      }
    ]
  ]))

  secondary_address_A = (flatten([
    for elements in local.address_A : [
      for secondary_address in(elements.address_A.secondary_addresses == null) ? [] : elements.address_A.secondary_addresses : {
        secondary_address_A_id          = elements.address_A_placeholder
        secondary_address_A_placeholder = "[${secondary_address.ip_address}]_${elements.address_A_placeholder}"
        secondary_address_A             = secondary_address
      }
    ]
  ]))

  secondary_address_B = (flatten([
    for elements in local.address_B : [
      for secondary_address in(elements.address_B.secondary_addresses == null) ? [] : elements.address_B.secondary_addresses : {
        secondary_address_B_id          = elements.address_B_placeholder
        secondary_address_B_placeholder = "[${secondary_address.ip_address}]_${elements.address_B_placeholder}"
        secondary_address_B             = secondary_address
      }
    ]
  ]))

  floating_svi = (flatten([
    for interface in local.logical_interfaces : [
      for float in(interface.interface.floating_svi == null) ? [] : interface.interface.floating_svi : {
        float_id          = interface.interface.name
        float_placeholder = "[${float.ip_address}]_[${float.pod_id}/${float.node_id}]_[${interface.interface.name}]"
        float             = float
      }
    ]
  ]))

  bgp_peers_floating_svi = (flatten([
    for elements in local.floating_svi : [
      for bgp_peer in(elements.float.bgp_peers == null) ? [] : elements.float.bgp_peers : {
        bgp_peer_id          = elements.float_placeholder
        bgp_peer_placeholder = "[${bgp_peer.ip_address}]_${elements.float_placeholder}"
        bgp_peer             = bgp_peer
      }
    ]
  ]))

  bgp_peer_floating_svi_route_control_profiles = (flatten([
    for bgp in local.bgp_peers_floating_svi : [
      for control in(bgp.bgp_peer.route_control_profiles == null) ? [] : bgp.bgp_peer.route_control_profiles : {
        control_id           = bgp.bgp_peer.ip_address
        control_placeholder  = "[${control.target_dn}]_[${control.direction}]_${bgp.bgp_peer_placeholder}"
        bgp_peer_placeholder = bgp.bgp_peer_placeholder
        control              = control
      }
    ]
  ]))

  floating_svi_path = (flatten([
    for float in local.floating_svi : [
      for svi in(float.float.path_attributes == null) ? [] : float.float.path_attributes : {
        svi_id            = float.float.ip_address
        svi_placeholder   = "[${svi.floating_address}]_${float.float_placeholder}"
        float_placeholder = float.float_placeholder
        svi               = svi
        tdn               = svi.target_dn
      }
    ]
  ]))

  floating_svi_path_secondary_address = (flatten([
    for path in local.floating_svi_path : [
      for secondary_address in(path.svi.secondary_addresses == null) ? [] : path.svi.secondary_addresses : {
        secondary_address_id          = path.float_placeholder
        secondary_address_placeholder = "[${secondary_address}]_${path.svi_placeholder}"
        secondary_address             = secondary_address
        tdn                           = path.tdn
      }
    ]
  ]))
}

resource "aci_l3_outside" "l3out" {
  tenant_dn                       = var.tenant_dn
  name                            = var.name
  name_alias                      = var.alias
  description                     = var.description
  annotation                      = var.annotation
  enforce_rtctrl                  = var.route_control_enforcement == true ? ["export", "import"] : ["export"]
  target_dscp                     = var.target_dscp
  relation_l3ext_rs_ectx          = var.vrf_dn
  relation_l3ext_rs_l3_dom_att    = var.l3_domain_dn
  relation_l3ext_rs_interleak_pol = var.route_profile_for_interleak_dn

  dynamic "relation_l3ext_rs_dampening_pol" {
    for_each = var.route_control_for_dampening
    content {
      af                     = "${relation_l3ext_rs_dampening_pol.value.address_family}-ucast"
      tn_rtctrl_profile_name = relation_l3ext_rs_dampening_pol.value.route_map_dn
    }
  }
}

resource "aci_l3out_bgp_external_policy" "external_bgp" {
  l3_outside_dn = aci_l3_outside.l3out.id
  annotation    = var.annotation
  name_alias    = var.external_bgp_name_alias
}

resource "aci_external_network_instance_profile" "l3out_external_epgs" {
  for_each = { for ext_epg in var.external_epgs : ext_epg.name => ext_epg }

  l3_outside_dn  = aci_l3_outside.l3out.id
  annotation     = each.value.annotation
  description    = each.value.description
  exception_tag  = each.value.exception_tag
  flood_on_encap = each.value.flood_on_encapsulation
  match_t        = each.value.label_match_criteria
  name_alias     = each.value.alias
  name           = each.value.name
  pref_gr_memb   = each.value.preferred_group_member == true ? "include" : "exclude"
  prio           = each.value.qos_class
  target_dscp    = each.value.target_dscp

  dynamic "relation_l3ext_rs_inst_p_to_profile" {
    for_each = contains(keys(local.external_epg_route_control_profiles), each.value.name) ? local.external_epg_route_control_profiles[each.value.name] : []
    content {
      direction              = relation_l3ext_rs_inst_p_to_profile.value.direction
      tn_rtctrl_profile_name = relation_l3ext_rs_inst_p_to_profile.value.route_map_dn
    }
  }
}

resource "aci_rest_managed" "l3out_route_profiles_for_redistribution" {
  for_each   = { for redistribution in var.route_profiles_for_redistribution : redistribution.source => redistribution }
  dn         = "${aci_l3_outside.l3out.id}/rsredistributePol-[${split("prof-", each.value.route_map_dn)[1]}]-${each.value.source}"
  class_name = "l3extRsRedistributePol"
  content = {
    src = each.value.source
    tDn = each.value.route_map_dn
  }
}

resource "aci_rest_managed" "l3out_multicast" {
  dn         = "${aci_l3_outside.l3out.id}/pimextp"
  class_name = "pimExtP"
  content = {
    enabledAf = join(",", formatlist("%s-mcast", var.multicast.address_families))
  }
}

resource "aci_rest_managed" "l3out_consumer_label" {
  dn         = "${aci_l3_outside.l3out.id}/conslbl-hcloudGolfLabel"
  class_name = "l3extConsLbl"
  content = {
    name = "hcloudGolfLabel"
  }
}

resource "aci_l3_ext_subnet" "external_epg_subnets" {
  for_each = { for subnet in local.external_epg_subnets : subnet.subnet_placeholder => subnet }

  external_network_instance_profile_dn = aci_external_network_instance_profile.l3out_external_epgs[each.value.external_epg_name].id
  ip                                   = each.value.subnet.ip
  scope                                = each.value.subnet.scope
  aggregate                            = each.value.subnet.aggregate

  dynamic "relation_l3ext_rs_subnet_to_profile" {
    for_each = contains(keys(local.external_epg_subnet_route_control_profiles), each.value.subnet.ip) ? local.external_epg_subnet_route_control_profiles[each.value.subnet.ip] : []
    content {
      direction            = relation_l3ext_rs_subnet_to_profile.value.direction
      tn_rtctrl_profile_dn = relation_l3ext_rs_subnet_to_profile.value.route_map_dn
    }
  }
}

resource "aci_route_control_profile" "l3out_route_control" {
  for_each = { for profile in var.route_map_control_profiles : profile.name => profile }

  parent_dn                  = aci_l3_outside.l3out.id
  name                       = each.value.name
  annotation                 = each.value.annotation
  description                = each.value.description
  name_alias                 = each.value.alias
  route_control_profile_type = each.value.route_control_profile_type
}

resource "aci_route_control_context" "route_control_context" {
  for_each = { for context in local.route_control_contexts : context.context_placeholder => context }

  route_control_profile_dn           = aci_route_control_profile.l3out_route_control[each.value.profile_name].id
  name                               = each.value.context.name
  action                             = each.value.context.action
  order                              = each.value.context.order
  set_rule                           = each.value.context.set_rule_dn
  relation_rtctrl_rs_ctx_p_to_subj_p = contains(keys(local.route_control_context_match_rules_dn), each.value.context.name) ? local.route_control_context_match_rules_dn[each.value.context.name] : []
}

resource "aci_logical_node_profile" "logical_node_profile" {
  for_each = { for profile in var.logical_node_profiles : profile.name => profile }

  l3_outside_dn = aci_l3_outside.l3out.id
  description   = each.value.description
  name          = each.value.name
  annotation    = each.value.annotation
  name_alias    = each.value.alias
  tag           = each.value.tag
  target_dscp   = each.value.target_dscp
}

resource "aci_l3out_bgp_protocol_profile" "bgp_protocol" {
  for_each = { for bgp_profile in var.logical_node_profiles : bgp_profile.name => bgp_profile if bgp_profile.bgp_protocol_profile != null }

  logical_node_profile_dn            = aci_logical_node_profile.logical_node_profile[each.key].id
  relation_bgp_rs_best_path_ctrl_pol = each.value.bgp_protocol_profile.as_path_policy
  relation_bgp_rs_bgp_node_ctx_pol   = each.value.bgp_protocol_profile.bgp_timers
}

resource "aci_bgp_peer_connectivity_profile" "node_bgp_peer" {
  for_each = { for bgp_peer in local.bgp_peers_nodes : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_logical_node_profile.logical_node_profile[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as
  annotation          = each.value.bgp_peer.annotation
  ctrl                = each.value.bgp_peer.bgp_controls
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
    for_each = { for control in local.bgp_peer_nodes_route_control_profiles : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_logical_node_to_fabric_node" "logical_node_fabric" {
  for_each = { for node in local.logical_nodes : node.node_placeholder => node }

  logical_node_profile_dn = aci_logical_node_profile.logical_node_profile[each.value.profile_name].id
  tdn                     = "topology/pod-${each.value.node.pod_id}/node-${each.value.node.node_id}"
  rtr_id                  = each.value.node.router_id
  rtr_id_loop_back        = each.value.node.router_id_loopback
}

resource "aci_l3out_loopback_interface_profile" "loopback_interface" {
  for_each = { for address in local.logical_nodes_loopback_addresses : address.address_placeholder => address }

  fabric_node_dn = aci_logical_node_to_fabric_node.logical_node_fabric[each.value.address_node_dn].id
  addr           = each.value.ip
}

resource "aci_l3out_static_route" "static_route" {
  for_each = { for route in local.logical_nodes_static_routes : route.route_placeholder => route }

  fabric_node_dn             = aci_logical_node_to_fabric_node.logical_node_fabric[each.value.address_node_dn].id
  ip                         = each.value.route.ip
  aggregate                  = each.value.route.aggregate
  pref                       = each.value.route.fallback_preference
  rt_ctrl                    = each.value.route.route_control
  relation_ip_rs_route_track = each.value.route.track_policy
}

resource "aci_l3out_static_route_next_hop" "next_hop_address" {
  for_each = { for next_hop in local.static_route_next_hops : next_hop.next_hop_placeholder => next_hop }

  static_route_dn                    = aci_l3out_static_route.static_route[each.value.static_ip].id
  nh_addr                            = each.value.next_hop.next_hop_ip
  pref                               = each.value.next_hop.preference
  description                        = each.value.next_hop.description
  nexthop_profile_type               = each.value.next_hop.nexthop_profile_type
  annotation                         = each.value.next_hop.annotation
  name_alias                         = each.value.next_hop.alias
  relation_ip_rs_nexthop_route_track = each.value.next_hop.track_policy
  relation_ip_rs_nh_track_member     = each.value.next_hop.track_member
}

resource "aci_logical_interface_profile" "logical_interface_profile" {
  for_each = { for interface in local.logical_interfaces : interface.interface_placeholder => interface }

  logical_node_profile_dn = aci_logical_node_profile.logical_node_profile[each.value.profile_name].id
  name                    = each.value.interface.name
  relation_l3ext_rs_egress_qos_dpp_pol  = each.value.interface.egress_data_policy_dn
  relation_l3ext_rs_ingress_qos_dpp_pol = each.value.interface.ingress_data_policy_dn
  relation_l3ext_rs_l_if_p_cust_qos_pol = each.value.interface.custom_qos_policy_dn
  relation_l3ext_rs_arp_if_pol          = each.value.interface.arp_interface_policy_dn
  relation_l3ext_rs_nd_if_pol           = each.value.interface.nd_policy_dn
}

resource "aci_l3out_bfd_interface_profile" "bfd_interface" {
  for_each = { for interface in local.logical_interfaces : interface.interface_placeholder => interface.interface.bfd if interface.interface.bfd != null }

  logical_interface_profile_dn = aci_logical_interface_profile.logical_interface_profile[each.key].id
  annotation                   = each.value.annotation
  description                  = each.value.description
  key                          = each.value.authentication_key
  key_id                       = each.value.authentication_key_id
  interface_profile_type       = each.value.interface_profile_type
  relation_bfd_rs_if_pol       = each.value.bfd_interface_policy
}

resource "aci_l3out_hsrp_interface_profile" "hsrp_interface" {
  for_each = { for interface in local.logical_interfaces : interface.interface_placeholder => interface.interface.hsrp if interface.interface.hsrp != null }

  logical_interface_profile_dn = aci_logical_interface_profile.logical_interface_profile[each.key].id
  annotation                   = each.value.annotation
  name_alias                   = each.value.alias
  version                      = each.value.version
}

resource "aci_l3out_hsrp_interface_group" "hsrp_group" {
  for_each = { for group in local.hsrp_groups : group.hsrp_group_placeholder => group }

  l3out_hsrp_interface_profile_dn = aci_l3out_hsrp_interface_profile.hsrp_interface[each.value.hsrp_group_id].id
  name                            = each.value.hsrp_group.name
  annotation                      = each.value.hsrp_group.annotation
  description                     = each.value.hsrp_group.description
  group_af                        = each.value.hsrp_group.address_family
  group_id                        = each.value.hsrp_group.group_id
  group_name                      = each.value.hsrp_group.name
  ip                              = each.value.hsrp_group.ip
  ip_obtain_mode                  = each.value.hsrp_group.ip_obtain_mode
  mac                             = each.value.hsrp_group.mac
  name_alias                      = each.value.hsrp_group.alias
}

resource "aci_l3out_hsrp_secondary_vip" "secondary_virtual_ip" {
  for_each = { for vip in local.hsrp_secondary_vips : vip.vip_placeholder => vip }

  l3out_hsrp_interface_group_dn = aci_l3out_hsrp_interface_group.hsrp_group[each.value.vip_id].id
  ip                            = each.value.vip
}


resource "aci_l3out_path_attachment" "l3out_path" {
  for_each = { for path in local.paths : path.path_placeholder => path }

  logical_interface_profile_dn = aci_logical_interface_profile.logical_interface_profile[each.value.path_id].id
  target_dn                    = each.value.path.path_type == "vpc" ? "topology/pod-${each.value.path.pod_id}/protpaths-${each.value.path.node_id}-${each.value.path.node2_id}/pathep-[${each.value.path.interface_id}]" : "topology/pod-${each.value.path.pod_id}/paths-${each.value.path.node_id}/pathep-[${each.value.path.interface_id}]"
  if_inst_t                    = each.value.path.interface_type
  addr                         = each.value.path.ip_address
  mtu                          = each.value.path.mtu
  encap                        = each.value.path.encap
  encap_scope                  = each.value.path.encap_scope
  mode                         = each.value.path.mode
  annotation                   = each.value.path.annotation
  autostate                    = each.value.path.autostate
  ipv6_dad                     = each.value.path.ipv6_dad
  ll_addr                      = each.value.path.link_local_addr
  mac                          = each.value.path.mac
  target_dscp                  = each.value.path.target_dscp
}

resource "aci_l3out_floating_svi" "floating_svi" {
  for_each = { for float in local.floating_svi : float.float_placeholder => float }

  logical_interface_profile_dn = aci_logical_interface_profile.logical_interface_profile[each.value.float_id].id
  node_dn                      = "topology/pod-${each.value.float.pod_id}/node-${each.value.float.node_id}"
  encap                        = each.value.float.encap
  addr                         = each.value.float.ip_address
  annotation                   = each.value.float.annotation
  description                  = each.value.float.description
  autostate                    = each.value.float.autostate
  encap_scope                  = each.value.float.encap_scope
  if_inst_t                    = "ext-svi"
  ipv6_dad                     = each.value.float.ipv6_dad
  ll_addr                      = each.value.float.link_local_addr
  mac                          = each.value.float.mac
  mode                         = each.value.float.mode
  mtu                          = each.value.float.mtu
  target_dscp                  = each.value.float.target_dscp

  dynamic "relation_l3ext_rs_dyn_path_att" {
    for_each = { for path in local.floating_svi_path : path.svi_placeholder => path.svi if each.value.float_placeholder == path.float_placeholder }
    content {
      tdn              = relation_l3ext_rs_dyn_path_att.value.target_dn
      floating_address = relation_l3ext_rs_dyn_path_att.value.floating_address
      forged_transmit  = relation_l3ext_rs_dyn_path_att.value.forged_transmit
      mac_change       = relation_l3ext_rs_dyn_path_att.value.mac_change
      promiscuous_mode = relation_l3ext_rs_dyn_path_att.value.promiscuous_mode
    }
  }
}

resource "aci_bgp_peer_connectivity_profile" "floating_svi_bgp_peer" {
  for_each = { for bgp_peer in local.bgp_peers_floating_svi : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_floating_svi.floating_svi[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as
  annotation          = each.value.bgp_peer.annotation
  ctrl                = each.value.bgp_peer.bgp_controls
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
    for_each = { for control in local.bgp_peer_floating_svi_route_control_profiles : control.control_placeholder => control.control if each.value.bgp_peer_placeholder == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

resource "aci_l3out_path_attachment_secondary_ip" "floating_svi_secondary_ip_addr" {
  for_each = { for addr in local.floating_svi_path_secondary_address : addr.secondary_address_placeholder => addr }

  l3out_path_attachment_dn = "${aci_l3out_floating_svi.floating_svi[each.value.secondary_address_id].id}/rsdynPathAtt-[${each.value.tdn}]"
  addr                     = each.value.secondary_address
}

resource "aci_l3out_path_attachment_secondary_ip" "secondary_ip_addr" {
  for_each = { for addr in local.secondary_address : addr.secondary_address_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_path_attachment.l3out_path[each.value.secondary_address_id].id
  addr                     = each.value.secondary_address.ip_address
  ipv6_dad                 = each.value.secondary_address.ipv6_dad
}

resource "aci_l3out_vpc_member" "side_A" {
  for_each = { for addr in local.address_A : addr.address_A_placeholder => addr }

  leaf_port_dn = aci_l3out_path_attachment.l3out_path[each.value.address_A_id].id
  side         = "A"
  addr         = each.value.address_A.ip_address
}

resource "aci_l3out_vpc_member" "side_B" {
  for_each = { for addr in local.address_B : addr.address_B_placeholder => addr }

  leaf_port_dn = aci_l3out_path_attachment.l3out_path[each.value.address_B_id].id
  side         = "B"
  addr         = each.value.address_B.ip_address
}

resource "aci_l3out_path_attachment_secondary_ip" "secondary_ip_addr_A" {
  for_each = { for addr in local.secondary_address_A : addr.secondary_address_A_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_vpc_member.side_A[each.value.secondary_address_A_id].id
  addr                     = each.value.secondary_address_A.ip_address
  ipv6_dad                 = each.value.secondary_address_A.ipv6_dad
}

resource "aci_l3out_path_attachment_secondary_ip" "secondary_ip_addr_B" {
  for_each = { for addr in local.secondary_address_B : addr.secondary_address_B_placeholder => addr }

  l3out_path_attachment_dn = aci_l3out_vpc_member.side_B[each.value.secondary_address_B_id].id
  addr                     = each.value.secondary_address_B.ip_address
  ipv6_dad                 = each.value.secondary_address_B.ipv6_dad
}

resource "aci_bgp_peer_connectivity_profile" "interface_bgp_peer" {
  for_each = { for bgp_peer in local.bgp_peers : bgp_peer.bgp_peer_placeholder => bgp_peer }

  parent_dn           = aci_l3out_path_attachment.l3out_path[each.value.bgp_peer_id].id
  addr                = each.value.bgp_peer.ip_address
  addr_t_ctrl         = each.value.bgp_peer.address_control
  allowed_self_as_cnt = each.value.bgp_peer.allowed_self_as
  annotation          = each.value.bgp_peer.annotation
  ctrl                = each.value.bgp_peer.bgp_controls
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
    for_each = { for control in local.bgp_peer_route_control_profiles : control.control_placeholder => control.control if each.key == control.bgp_peer_placeholder }
    content {
      direction = relation_bgp_rs_peer_to_profile.value.direction
      target_dn = relation_bgp_rs_peer_to_profile.value.target_dn
    }
  }
}

output "subnets" {
  value = local.external_epg_subnets
}

output "external_epg_route_control_profiles" {
  value = local.external_epg_route_control_profiles
}

output "external_epg_subnet_route_control_profiles" {
  value = local.external_epg_subnet_route_control_profiles
}

output "route_control_context_match_rules_dn" {
  value = local.route_control_context_match_rules_dn
}

output "logical_nodes_loopback_addresses" {
  value = local.logical_nodes_loopback_addresses
}

output "logical_nodes_static_routes" {
  value = local.logical_nodes_static_routes
}

output "static_route_next_hops" {
  value = local.static_route_next_hops
}

output "secondary_address" {
  value = local.secondary_address
}

output "address_A" {
  value = local.address_A
}

output "address_B" {
  value = local.address_B
}

output "secondary_address_A" {
  value = local.secondary_address_A
}

output "secondary_address_B" {
  value = local.secondary_address_B
}

output "secondary_address_hsrp_vip" {
  value = local.hsrp_secondary_vips
}

output "bgp_peers" {
  value = local.bgp_peers
}
