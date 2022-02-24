variable "name" {

}

variable "alias" {
  default = ""
}

variable "description" {
  default = ""
}

variable "tenant_dn" {

}

variable "vrf_dn" {

}

variable "l3dom_dn" {

}

variable "ospf" {
  type = object({
    enabled   = bool
    area_id   = optional(string)
    area_type = optional(string)
    area_cost = optional(string)
    area_ctrl = optional(string)
  })
  default = { enabled = false }
}

variable "bgp" {
  type = object({
    enabled = bool
    bgp_peers = optional(map(object({
      peer_ip_addr          = string
      peer_asn              = string
      weight                = optional(string)
      addr_family_ctrl      = optional(string)
      bgp_ctrl              = optional(string)
      peer_ctrl             = optional(string)
      allowed_self_as_count = optional(string)
      local_asn             = optional(string)
      local_asn_propagate   = optional(string)
      private_as_ctrl       = optional(string)
      ttl                   = optional(string)
    })))
  })
  default = { enabled = false }
}


variable "nodes" {
  type = map(object({
    pod_id             = optional(string)
    node_id            = string
    router_id          = string
    router_id_loopback = optional(string)
    loopbacks          = optional(list(string))

    static_routes = optional(map(object({
      prefix     = string
      preference = optional(string)
      bfd        = optional(bool)
      next_hops  = optional(list(string))
    })))
  }))
}

variable "interfaces" {
  type = map(object({
    l2_port_type     = string
    l3_port_type     = string
    pod_id           = string
    node_a_id        = string
    node_b_id        = optional(string)
    interface_id     = string
    ip_addr_a        = string
    ip_addr_b        = optional(string)
    ip_addr_shared   = optional(string)
    vlan_encap       = optional(string)
    vlan_encap_scope = optional(string)
    mode             = optional(string)
    mtu              = optional(string)

    bgp_peers = optional(map(object({
      peer_ip_addr          = string
      peer_asn              = string
      weight                = optional(string)
      addr_family_ctrl      = optional(string)
      bgp_ctrl              = optional(string)
      peer_ctrl             = optional(string)
      allowed_self_as_count = optional(string)
      local_asn             = optional(string)
      local_asn_propagate   = optional(string)
      private_as_ctrl       = optional(string)
      ttl                   = optional(string)
    })))

    ospf_interface_policy_dn = optional(string)
  }))
}

variable "external_l3epg" {
  type = map(object({
    name         = string
    pref_gr_memb = optional(string)
    subnets = map(object({
      prefix    = string
      scope     = optional(list(string))
      aggregate = optional(string)
    }))
    prov_contracts          = optional(set(string))
    cons_contracts          = optional(set(string))
    cons_imported_contracts = optional(set(string))
  }))
}