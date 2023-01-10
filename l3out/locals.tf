locals {
  external_epg_route_control_profiles = {
    for external_epg in var.external_epgs : external_epg.name => external_epg.route_control_profiles
    if external_epg.route_control_profiles != null
  }

  external_epg_contract_masters = (flatten([
    for external_epg in var.external_epgs : [
      for contract in(external_epg.contract_masters == null) ? [] : external_epg.contract_masters : {
        external_epg_name = external_epg.name
        contract          = contract
      }
    ]
  ]))

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

  logical_interfaces_netflow_monitor = (flatten([
    for interface in local.logical_interfaces : [
      for netflow in(interface.interface.netflow_monitor_policies == null) ? [] : interface.interface.netflow_monitor_policies : {
        netflow_id          = interface.interface.name
        netflow_placeholder = netflow.filter_type
        netflow             = netflow
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
