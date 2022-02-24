locals {
  ospf = defaults(var.ospf, {
    area_id   = "0.0.0.1"
    area_type = "nssa"
    area_cost = "1"
    area_ctrl = "redistribute,summary"
  })

  bgp = defaults(var.bgp, {
    bgp_peers = {
      weight                = "0"
      addr_family_ctrl      = "af-ucast"
      bgp_ctrl              = ""
      peer_ctrl             = ""
      allowed_self_as_count = "3"
      private_as_ctrl       = ""
      ttl                   = "1"
    }
  })

  nodes = defaults(var.nodes, {
    pod_id             = "1"
    router_id_loopback = "yes"
    static_routes = {
      preference = "1"
      bfd        = false
    }
  })

  interfaces = defaults(var.interfaces, {
    vlan_encap       = "unknown"
    vlan_encap_scope = "local"
    mode             = "regular"
    mtu              = "inherit"

    bgp_peers = {
      weight                = "0"
      addr_family_ctrl      = "af-ucast"
      bgp_ctrl              = ""
      peer_ctrl             = ""
      allowed_self_as_count = "3"
      private_as_ctrl       = ""
      ttl                   = "1"
    }
  })

  external_l3epg = defaults(var.external_l3epg, {
    pref_gr_memb = "exclude"
    subnets = {
      scope = "import-security"
    }
  })

}
