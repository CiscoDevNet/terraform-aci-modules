terraform {
  experiments = [module_variable_optional_attrs]

  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">= 2.0.0"
    }
  }

  required_version = "> 0.14"
}

locals {
  # Loopbacks under nodes
  loopbacks = flatten([
    for node_key, node_value in local.nodes : [
      for loopback in node_value.loopbacks : {
        node_key      = node_key
        loopback_key  = "${node_key}_${loopback}"
        loopback_addr = loopback
      }
    ]
    if node_value.loopbacks != null
  ])

  # Static routes under nodes
  static_routes = flatten([
    for node_key, node_value in local.nodes : [
      for strt_key, strt_value in node_value.static_routes : {
        node_key            = node_key
        static_route_key    = "${node_key}_${strt_key}"
        static_route_config = strt_value
      }
    ]
    #if node_value.static_routes != null
  ])

  # Static routes next hops
  strt_next_hops = flatten([
    for node_key, node_value in local.nodes : [
      for strt_key, strt_value in node_value.static_routes : [
        for nh in strt_value.next_hops : {
          node_key         = node_key
          static_route_key = "${node_key}_${strt_key}"
          next_hop_key     = "${node_key}_${strt_key}_${nh}"
          next_hop_addr    = nh
        }
      ]
      if strt_value.next_hops != null
    ]
    #if node_value.static_routes != null
  ])

  # Interface BGP Peers
  if_bgp_peers = flatten([
    for if_key, if_value in local.interfaces : [
      for peer_key, peer_value in if_value.bgp_peers : {
        interface_key     = if_key
        interface_l2_type = if_value.l2_port_type
        bgp_peer_key      = "${if_key}_${peer_key}"
        bgp_peer_config   = peer_value
      }
    ]
    if if_value.bgp_peers != null
  ])

  # L3InstP (L3 EPG) Subnets
  l3epg_subnets = flatten([
    for l3epg_key, l3epg_value in local.external_l3epg : [
      for subnet_key, subnet_value in l3epg_value.subnets : {
        l3epg_key  = l3epg_key
        subnet_key = "${l3epg_key}_${subnet_key}"
        subnet     = subnet_value
      }
    ]
  ])
}

# L3Out Definition
resource "aci_l3_outside" "l3out" {
  tenant_dn                    = var.tenant_dn
  name                         = var.name
  name_alias                   = var.alias
  description                  = var.description
  relation_l3ext_rs_ectx       = var.vrf_dn
  relation_l3ext_rs_l3_dom_att = var.l3dom_dn
}

resource "aci_l3out_ospf_external_policy" "ospf" {
  count = local.ospf.enabled ? 1 : 0

  l3_outside_dn = aci_l3_outside.l3out.id
  area_id       = local.ospf.area_id
  area_type     = local.ospf.area_type
  area_cost     = local.ospf.area_cost
  # Doing split as defaults() is not working as expected with list of strings
  area_ctrl = compact(split(",", local.ospf.area_ctrl))
}

resource "aci_l3out_bgp_external_policy" "bgp" {
  count = local.bgp.enabled ? 1 : 0

  l3_outside_dn = aci_l3_outside.l3out.id
}

resource "aci_bgp_peer_connectivity_profile" "node_bgp_peer" {
  for_each = local.bgp.bgp_peers

  parent_dn = aci_logical_node_profile.l3np.id

  addr                = each.value.peer_ip_addr
  as_number           = each.value.peer_asn
  weight              = each.value.weight
  addr_t_ctrl         = compact(split(",", each.value.addr_family_ctrl))
  ctrl                = compact(split(",", each.value.bgp_ctrl))
  peer_ctrl           = compact(split(",", each.value.peer_ctrl))
  allowed_self_as_cnt = each.value.allowed_self_as_count
  local_asn           = each.value.local_asn
  local_asn_propagate = each.value.local_asn_propagate
  private_a_sctrl     = compact(split(",", each.value.private_as_ctrl))
  ttl                 = each.value.ttl
}

# Nodes Section

resource "aci_logical_node_profile" "l3np" {
  l3_outside_dn = aci_l3_outside.l3out.id

  name = "${var.name}_nodeProfile"
}

resource "aci_logical_node_to_fabric_node" "l3np_node" {
  for_each = local.nodes

  logical_node_profile_dn = aci_logical_node_profile.l3np.id
  tdn                     = "topology/pod-${each.value.pod_id}/node-${each.value.node_id}"
  rtr_id                  = each.value.router_id
  rtr_id_loop_back        = each.value.router_id_loopback
}

resource "aci_l3out_loopback_interface_profile" "loopback" {
  for_each = {
    for loopback in local.loopbacks : loopback.loopback_key => loopback
  }

  fabric_node_dn = aci_logical_node_to_fabric_node.l3np_node[each.value.node_key].id
  addr           = each.value.loopback_addr
}

resource "aci_l3out_static_route" "static" {
  for_each = {
    for strt in local.static_routes : strt.static_route_key => strt
  }

  fabric_node_dn = aci_logical_node_to_fabric_node.l3np_node[each.value.node_key].id
  ip             = each.value.static_route_config.prefix
  aggregate      = "no"
  pref           = each.value.static_route_config.preference
  rt_ctrl        = each.value.static_route_config.bfd ? "bfd" : "unspecified"
}

resource "aci_l3out_static_route_next_hop" "nh" {
  for_each = {
    for nh in local.strt_next_hops : nh.next_hop_key => nh
  }

  static_route_dn      = aci_l3out_static_route.static[each.value.static_route_key].id
  nh_addr              = each.value.next_hop_addr
  pref                 = "unspecified"
  nexthop_profile_type = "prefix"
}

# Interfaces Section

resource "aci_logical_interface_profile" "l3ip" {
  for_each = local.interfaces

  logical_node_profile_dn = aci_logical_node_profile.l3np.id
  name                    = "${each.key}_intProfile"
}

resource "aci_l3out_path_attachment" "path" {
  for_each = {
    for if_key, if_value in local.interfaces : if_key => if_value
    if if_value.l2_port_type != "vpc"
  }

  logical_interface_profile_dn = aci_logical_interface_profile.l3ip[each.key].id
  target_dn                    = "topology/pod-${each.value.pod_id}/paths-${each.value.node_a_id}/pathep-[${each.value.interface_id}]"
  if_inst_t                    = each.value.l3_port_type
  addr                         = each.value.ip_addr_a
  mtu                          = each.value.mtu
  encap                        = each.value.vlan_encap
  encap_scope                  = each.value.vlan_encap_scope
  mode                         = each.value.mode
}

resource "aci_l3out_path_attachment" "protpath" {
  for_each = {
    for if_key, if_value in local.interfaces : if_key => if_value
    if if_value.l2_port_type == "vpc"
  }

  logical_interface_profile_dn = aci_logical_interface_profile.l3ip[each.key].id
  target_dn                    = "topology/pod-${each.value.pod_id}/protpaths-${each.value.node_a_id}-${each.value.node_b_id}/pathep-[${each.value.interface_id}]"
  if_inst_t                    = each.value.l3_port_type
  addr                         = "0.0.0.0"
  mtu                          = each.value.mtu
  encap                        = each.value.vlan_encap
  encap_scope                  = each.value.vlan_encap_scope
  mode                         = each.value.mode
  autostate                    = "enabled"
}

resource "aci_l3out_vpc_member" "vpc_member_a" {
  for_each = {
    for if_key, if_value in local.interfaces : if_key => if_value
    if if_value.l2_port_type == "vpc"
  }

  leaf_port_dn = aci_l3out_path_attachment.protpath[each.key].id
  side         = "A"
  addr         = each.value.ip_addr_a
}

resource "aci_l3out_vpc_member" "vpc_member_b" {
  for_each = {
    for if_key, if_value in local.interfaces : if_key => if_value
    if if_value.l2_port_type == "vpc"
  }

  leaf_port_dn = aci_l3out_path_attachment.protpath[each.key].id
  side         = "B"
  addr         = each.value.ip_addr_b
}

resource "aci_l3out_path_attachment_secondary_ip" "vpc_secondary_addr" {
  for_each = {
    for if_key, if_value in local.interfaces : if_key => if_value
    if if_value.l2_port_type == "vpc" && if_value.ip_addr_shared != null
  }

  l3out_path_attachment_dn = aci_l3out_path_attachment.protpath[each.key].id
  addr                     = each.value.ip_addr_shared
}

# OSPF Interface Policies

resource "aci_l3out_ospf_interface_profile" "ifProf" {
  for_each = {
    for if_key, if_value in local.interfaces : if_key => if_value
    if local.ospf.enabled
  }

  logical_interface_profile_dn = aci_logical_interface_profile.l3ip[each.key].id
  auth_type                    = "none"
  auth_key                     = ""
  relation_ospf_rs_if_pol      = each.value.ospf_interface_policy_dn
}

# BGP Peers under Interface
resource "aci_bgp_peer_connectivity_profile" "if_bgp_peer" {
  for_each = {
    for peer in local.if_bgp_peers : peer.bgp_peer_key => peer
  }

  # Here we are using the BGP Peer under node profile for configuring it under logical interface. Class and atttributes are the same so hopping it works well
  parent_dn = (each.value.interface_l2_type == "vpc" ?
  aci_l3out_path_attachment.protpath[each.value.interface_key].id : aci_l3out_path_attachment.path[each.value.interface_key].id)

  addr                = each.value.bgp_peer_config.peer_ip_addr
  as_number           = each.value.bgp_peer_config.peer_asn
  weight              = each.value.bgp_peer_config.weight
  addr_t_ctrl         = compact(split(",", each.value.bgp_peer_config.addr_family_ctrl))
  ctrl                = compact(split(",", each.value.bgp_peer_config.bgp_ctrl))
  peer_ctrl           = compact(split(",", each.value.bgp_peer_config.peer_ctrl))
  allowed_self_as_cnt = each.value.bgp_peer_config.allowed_self_as_count
  local_asn           = each.value.bgp_peer_config.local_asn
  local_asn_propagate = each.value.bgp_peer_config.local_asn_propagate
  private_a_sctrl     = compact(split(",", each.value.bgp_peer_config.private_as_ctrl))
  ttl                 = each.value.bgp_peer_config.ttl
}

# External Network Instance Profiles
resource "aci_external_network_instance_profile" "l3epg" {
  for_each = local.external_l3epg

  l3_outside_dn          = aci_l3_outside.l3out.id
  name                   = each.value.name
  pref_gr_memb           = each.value.pref_gr_memb
  relation_fv_rs_prov    = each.value.prov_contracts
  relation_fv_rs_cons    = each.value.cons_contracts
  relation_fv_rs_cons_if = each.value.cons_imported_contracts
}

resource "aci_l3_ext_subnet" "l3ext_subnet_default" {
  for_each = {
    for subnet in local.l3epg_subnets : subnet.subnet_key => subnet
  }
  external_network_instance_profile_dn = aci_external_network_instance_profile.l3epg[each.value.l3epg_key].id
  ip                                   = each.value.subnet.prefix
  scope                                = each.value.subnet.scope
  aggregate                            = each.value.subnet.aggregate
}
