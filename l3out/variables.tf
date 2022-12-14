terraform {
  experiments = [module_variable_optional_attrs]
}

variable "tenant_dn" {
  type = string
}

variable "name" {
  type = string
}

variable "alias" {
  type    = string
  default = ""
}

variable "annotation" {
  type    = string
  default = "orchestrator:terraform"
}

variable "description" {
  default = ""
}

variable "vrf_dn" {
  type    = string
  default = ""
}

variable "l3_domain_dn" {
  type    = string
  default = ""
}

variable "route_profile_for_interleak_dn" {
  type    = string
  default = ""
}

variable "route_control_for_dampening" {
  type = list(object({
    address_family = optional(string) # choose between ipv4 and v6
    route_map_dn   = optional(string)
  }))
  validation {
    condition     = contains(["ipv4", "ipv6"], var.route_control_for_dampening[0].address_family)
    error_message = "Valid values for route_control_for_dampening are (ipv4, ipv6)"
  }
}

variable "route_control_enforcement" {
  type = bool
}

variable "route_profiles_for_redistribution" {
  type = list(object({
    source       = optional(string)
    route_map_dn = optional(string)
  }))
}

variable "multicast" {
  type = object({
    annotation       = optional(string)
    address_families = optional(list(string))
  })
}

variable "target_dscp" {
  type    = string
  default = "unspecified"
  validation {
    condition     = contains(["CS0", "CS1", "AF11", "AF12", "AF13", "CS2", "AF21", "AF22", "AF23", "CS3", "CS4", "CS5", "CS6", "CS7", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "VA", "EF", "unspecified"], var.target_dscp)
    error_message = "Valid values for target_dscp are (CS0, CS1, AF11, AF12, AF13, CS2, AF21, AF22, AF23, CS3, CS4, CS5, CS6, CS7, AF31, AF32, AF33, AF41, AF42, AF43, VA, EF, unspecified)"
  }
}

############## Variable for  "aci_l3out_bgp_external_policy" ######## 
variable "external_bgp_name_alias" {
  default = ""
}

############## Variable for  "aci_external_epgs" ####################
variable "external_epgs" {
  type = list(object({
    annotation             = optional(string)
    description            = optional(string)
    exception_tag          = optional(string)
    flood_on_encapsulation = optional(string)
    label_match_criteria   = optional(string)
    alias                  = optional(string)
    name                   = string
    preferred_group_member = optional(bool)
    qos_class              = optional(string)
    target_dscp            = optional(string)
    route_control_profiles = optional(list(object({
      direction    = string
      route_map_dn = string
    })))
    subnets = optional(list(object({
      ip        = string
      aggregate = optional(string)
      alias     = optional(string)
      scope     = list(string)
      route_control_profiles = optional(list(object({
        direction    = string
        route_map_dn = string
      })))
    })))
  }))
  validation {
    condition     = alltrue([for criteria in var.external_epgs : contains(["All", "AtleastOne", "AtmostOne", "None"], criteria["label_match_criteria"])])
    error_message = "Valid values for label_match_criteria in external_epgs are (All, AtleastOne, AtmostOne, None)"
  }
  validation {
    condition     = alltrue([for index, class in var.external_epgs : contains(["unspecified", "level6", "level5", "level4", "level3", "level2", "level1"], var.external_epgs[index].qos_class)])
    error_message = "Valid values for qos_class in external_epgs are (unspecified, level6, level5, level4, level3, level2, level1)"
  }
  validation {
    condition     = alltrue([for dscp in var.external_epgs : contains(["CS0", "CS1", "AF11", "AF12", "AF13", "CS2", "AF21", "AF22", "AF23", "CS3", "CS4", "CS5", "CS6", "CS7", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "VA", "EF", "unspecified"], dscp["target_dscp"])])
    error_message = "Valid values for target_dscp in external_epgs are (CS0, CS1, AF11, AF12, AF13, CS2, AF21, AF22, AF23, CS3, CS4, CS5, CS6, CS7, AF31, AF32, AF33, AF41, AF42, AF43, VA, EF, unspecified)"
  }
  validation {
    condition = alltrue([for aggregate in(flatten([
      for external_epg in var.external_epgs : [
        for subnet in(external_epg.subnets == null) ? [] : external_epg.subnets : [
          subnet.aggregate
        ]
      ]
    ])) : contains(["import-rtctrl", "export-rtctrl", "shared-rtctrl", "none"], aggregate)])
    error_message = "Valid values for aggregate in subnets of external_epgs are (import-rtctrl, export-rtctrl, shared-rtctrl, none)"
  }
  validation {
    condition = alltrue([for scope in(flatten([
      for external_epg in var.external_epgs : [
        for subnet in(external_epg.subnets == null) ? [] : external_epg.subnets : [
          subnet.scope
        ]
      ]
    ])) : contains(["import-rtctrl", "export-rtctrl", "shared-rtctrl", "none"], scope)])
    error_message = "Valid values for scope in subnets of external_epgs are (import-rtctrl, export-rtctrl, shared-rtctrl, import-security, shared-security)"
  }
  validation {
    condition = alltrue([for direction in(flatten([
      for external_epg in var.external_epgs : [
        for profile in(external_epg.route_control_profiles == null) ? [] : external_epg.route_control_profiles : [
          profile.direction
        ]
      ]
    ])) : contains(["export", "import"], direction)])
    error_message = "Valid values for direction in route_control_profiles of external_epgs are (export, import)"
  }
}

############## Variable for  "aci_route_control_profile" ####################
variable "route_map_control_profiles" {
  type = list(object({
    annotation                 = optional(string)
    description                = optional(string)
    alias                      = optional(string)
    name                       = string
    route_control_profile_type = optional(string)
    contexts = optional(list(object({
      name           = string
      action         = optional(string)
      order          = optional(string)
      set_rule_dn    = optional(string)
      match_rules_dn = optional(list(string))
    })))
  }))
  validation {
    condition     = alltrue([for control in var.route_map_control_profiles : contains(["global", "combinable"], control["route_control_profile_type"])])
    error_message = "Valid values for route_control_profile_type are (global, combinable)"
  }
}

############## Variable for  "aci_logical_node_profile" ####################
variable "logical_node_profiles" {
  type = list(object({
    annotation  = optional(string)
    description = optional(string)
    alias       = optional(string)
    name        = string
    tag         = optional(string)
    target_dscp = optional(string)
    bgp_peers_nodes = optional(list(object({
      ip_address             = string
      address_control        = optional(list(string))
      allowed_self_as        = optional(string)
      annotation             = optional(string)
      bgp_controls           = optional(list(string))
      alias                  = optional(string)
      password               = optional(string)
      peer_controls          = optional(list(string))
      private_as_control     = optional(list(string))
      ebgp_multihop_ttl      = optional(string)
      weight                 = optional(string)
      as_number              = optional(string)
      local_asn              = optional(string)
      local_as_number_config = optional(string)
      admin_state            = optional(string)
      route_control_profiles = optional(list(object({
        direction = string
        target_dn = string
      })))
    })))
    bgp_protocol_profile = optional(object({
      bgp_timers     = optional(string)
      as_path_policy = optional(string)
    }))
    nodes = optional(list(object({
      node_id            = string
      pod_id             = string
      router_id          = optional(string)
      router_id_loopback = optional(string)
      loopback_address   = optional(string)
      static_routes = optional(list(object({
        ip                  = string
        aggregate           = optional(string)
        alias               = optional(string)
        description         = optional(string)
        fallback_preference = optional(string)
        route_control       = optional(string)
        track_policy        = optional(string)
        next_hop_addresses = optional(list(object({
          next_hop_ip          = string
          annotation           = optional(string)
          alias                = optional(string)
          preference           = optional(string)
          nexthop_profile_type = optional(string)
          description          = optional(string)
          track_member         = optional(string)
          track_policy         = optional(string)
        })))
      })))
    })))
    interfaces = optional(list(object({
      name = string
      bfd = optional(object({
        authentication_key     = optional(string)
        authentication_key_id  = optional(string)
        interface_profile_type = optional(string)
        description            = optional(string)
        annotation             = optional(string)
        bfd_interface_policy   = optional(string)
      }))
      hsrp = optional(object({
        annotation = optional(string)
        alias      = optional(string)
        version    = optional(string)
        hsrp_groups = optional(list(object({
          name                  = string
          annotation            = optional(string)
          description           = optional(string)
          address_family        = optional(string)
          group_id              = optional(string)
          ip                    = optional(string)
          ip_obtain_mode        = optional(string)
          mac                   = optional(string)
          alias                 = optional(string)
          secondary_virtual_ips = optional(list(string))
          }
        )))
      }))
      netflow_monitor_policies = optional(list(object({
        filter_type               = string
        netflow_monitor_policy_dn = string
      })))
      egress_data_policy_dn   = optional(string)
      ingress_data_policy_dn  = optional(string)
      custom_qos_policy_dn    = optional(string)
      arp_interface_policy_dn = optional(string)
      nd_policy_dn            = optional(string)
      paths = optional(list(object({
        interface_type  = string
        path_type       = string
        pod_id          = string
        node_id         = string
        node2_id        = optional(string)
        interface_id    = string
        ip_address      = string
        mtu             = optional(string)
        encap           = optional(string)
        encap_scope     = optional(string)
        mode            = optional(string)
        annotation      = optional(string)
        autostate       = optional(string)
        ipv6_dad        = optional(string)
        link_local_addr = optional(string)
        mac             = optional(string)
        target_dscp     = optional(string)
        bgp_peers = optional(list(object({
          ip_address             = string
          address_control        = optional(list(string))
          allowed_self_as        = optional(string)
          annotation             = optional(string)
          bgp_controls           = optional(list(string))
          alias                  = optional(string)
          password               = optional(string)
          peer_controls          = optional(list(string))
          private_as_control     = optional(list(string))
          ebgp_multihop_ttl      = optional(string)
          weight                 = optional(string)
          as_number              = optional(string)
          local_asn              = optional(string)
          local_as_number_config = optional(string)
          admin_state            = optional(string)
          route_control_profiles = optional(list(object({
            direction = string
            target_dn = string
          })))
        })))
        secondary_addresses = optional(list(object({
          ip_address = string
          ipv6_dad   = string
        })))
        side_A = optional(object({
          ip_address = string
          secondary_addresses = optional(list(object({
            ip_address = string
            ipv6_dad   = string
          })))
        }))
        side_B = optional(object({
          ip_address = string
          secondary_addresses = optional(list(object({
            ip_address = string
            ipv6_dad   = string
          })))
        }))
      })))
      floating_svi = optional(list(object({
        pod_id          = string
        node_id         = string
        ip_address      = string
        description     = optional(string)
        mtu             = optional(string)
        encap           = optional(string)
        encap_scope     = optional(string)
        mode            = optional(string)
        annotation      = optional(string)
        autostate       = optional(string)
        ipv6_dad        = optional(string)
        link_local_addr = optional(string)
        mac             = optional(string)
        target_dscp     = optional(string)
        path_attributes = optional(list(object({
          target_dn           = string
          floating_address    = string
          forged_transmit     = optional(string)
          mac_change          = optional(string)
          promiscuous_mode    = optional(string)
          secondary_addresses = optional(list(string))
        })))
        bgp_peers = optional(list(object({
          ip_address             = string
          address_control        = optional(list(string))
          allowed_self_as        = optional(string)
          annotation             = optional(string)
          bgp_controls           = optional(list(string))
          alias                  = optional(string)
          password               = optional(string)
          peer_controls          = optional(list(string))
          private_as_control     = optional(list(string))
          ebgp_multihop_ttl      = optional(string)
          weight                 = optional(string)
          as_number              = optional(string)
          local_asn              = optional(string)
          local_as_number_config = optional(string)
          admin_state            = optional(string)
          route_control_profiles = optional(list(object({
            direction = string
            target_dn = string
          })))
        })))
      })))
    })))
  }))
  validation {
    condition     = alltrue([for dscp in var.logical_node_profiles : contains(["CS0", "CS1", "AF11", "AF12", "AF13", "CS2", "AF21", "AF22", "AF23", "CS3", "CS4", "CS5", "CS6", "CS7", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "VA", "EF", "unspecified"], dscp["target_dscp"])])
    error_message = "Valid values for target_dscp in logical_node_profiles are (CS0, CS1, AF11, AF12, AF13, CS2, AF21, AF22, AF23, CS3, CS4, CS5, CS6, CS7, AF31, AF32, AF33, AF41, AF42, AF43, VA, EF, unspecified)"
  }
  validation {
    condition = alltrue([for route_control in(flatten([
      for node in var.logical_node_profiles : [
        for static_routes in(node.nodes == null) ? [] : node.nodes : [
          for route in(static_routes.static_routes == null) ? [] : static_routes.static_routes : [
            (route.route_control == null) ? "unspecified" : route.route_control
          ]
        ]
      ]
    ])) : contains(["bfd", "unspecified"], route_control)])
    error_message = "Valid values for route_control in static_routes of nodes in logical_node_profiles are (bfd, unspecified) but got: ${compact([for invalid_value in(flatten([
      for node in var.logical_node_profiles : [
        for static_routes in(node.nodes == null) ? [] : node.nodes : [
          for route in(static_routes.static_routes == null) ? [] : static_routes.static_routes : [
            !contains(["bfd", "unspecified"], (route.route_control == null) ? "unspecified" : route.route_control) ? route.route_control : ""
          ]
        ]
      ]
    ])) : invalid_value == "" ? 0 : invalid_value])[0]}"
  }
  # validation {
  #   condition = alltrue([for path in (flatten([
  #   for profile in var.logical_node_profiles : [
  #     for interface in(profile.interfaces == null) ? [] : profile.interfaces : [
  #       for path in(interface.paths == null) ? [] : interface.paths : [
  #         path
  #     ]
  #   ]
  # ]])): contains(["vpc", "dpc"], path.path_type) && contains([null,""],path.node2_id)])
  #   error_message = "Value for node2_id is required when path_type is in (vpc, dpc)"
  # }
}

output "vars" {
  value = [for y in(flatten([
    for node in var.logical_node_profiles : [
      for static_routes in(node.nodes == null) ? [] : node.nodes : [
        for route in(static_routes.static_routes == null) ? [] : static_routes.static_routes : {
          x = !contains(["bfd", "unspecified"], (route.route_control == null) ? "unspecified" : route.route_control) ? route.route_control : null
        }
      ]
    ]
  ])) : y.x == null ? "k" : y.x][0]
}
