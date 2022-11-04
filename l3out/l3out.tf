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
  #config_issues = each.value.config_issues
  name_alias  = each.value.alias
  tag         = each.value.tag
  target_dscp = each.value.target_dscp
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
