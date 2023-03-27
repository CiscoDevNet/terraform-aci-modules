terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = ""
  password = ""
  url      = ""
  insecure = true
}

module "l3out" {
  source               = "../../../l3out"
  tenant_dn            = aci_tenant.tenant.id
  name                 = "module_l3out"
  alias                = "l3out"
  description          = "Created by l3out module"
  import_route_control = true
  target_dscp          = "EF"
  vrf_dn               = aci_vrf.vrf.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

  bgp = {
    alias = "bgp"
  }

  route_control_for_dampening = [
    {
      address_family = "ipv4"
      route_map_dn   = aci_route_control_profile.profile1.id
    },
    {
      address_family = "ipv6"
      route_map_dn   = aci_route_control_profile.profile2.id
    }
  ]

  route_control_for_interleak_redistribution = [
    {
      source       = "static"
      route_map_dn = aci_route_control_profile.profile1.id
    },
    {
      source       = "direct"
      route_map_dn = aci_route_control_profile.profile2.id
    },
    {
      source       = "attached-host"
      route_map_dn = aci_route_control_profile.profile3.id
    },
    {
      source       = "interleak"
      route_map_dn = aci_route_control_profile.profile4.id
    },
  ]

  multicast = {
    address_families = ["ipv4", "ipv6"]
  }

  route_map_control_profiles = [
    {
      name                       = "profile1"
      route_control_profile_type = "global"
      contexts = [
        {
          name        = "control1"
          action      = "permit"
          order       = "0"
          description = "Context created using TF"
          set_rule_dn = aci_action_rule_profile.set_rule2.id
        },
        {
          name           = "control2"
          action         = "deny"
          order          = "1"
          set_rule_dn    = aci_action_rule_profile.set_rule.id
          match_rules_dn = [aci_match_rule.rule2.id, aci_match_rule.rule.id]
        },
      ]
    },
    {
      name                       = "profile2"
      route_control_profile_type = "combinable"
      contexts = [
        {
          name           = "control3"
          action         = "permit"
          order          = "3"
          set_rule_dn    = aci_action_rule_profile.set_rule2.id
          match_rules_dn = [aci_match_rule.rule.id]
        },
      ]
    },
    {
      name                       = "profile3"
      route_control_profile_type = "global"
      contexts = [
        {
          name           = "control4"
          action         = "permit"
          order          = "0"
          set_rule_dn    = aci_action_rule_profile.set_rule.id
          match_rules_dn = [aci_match_rule.rule.id, aci_match_rule.rule2.id, aci_match_rule.rule3.id]
        },
        {
          name           = "control5"
          action         = "deny"
          order          = "1"
          set_rule_dn    = aci_action_rule_profile.set_rule2.id
          match_rules_dn = [aci_match_rule.rule3.id, aci_match_rule.rule2.id]
        },
      ]
    }
  ]

  default_route_leak_policy = {
    always   = "yes"
    criteria = "in-addition"
    scope    = ["ctx", "l3-out"]
  }

  fallback_route_group_dns = [aci_rest_managed.vrf_fallback_route_group1.id, aci_rest_managed.vrf_fallback_route_group2.id]

  external_epgs = [
    {
      name                         = "ext_epg1"
      description                  = "l3out_ext_epg1"
      label_match_criteria         = "All"
      preferred_group_member       = true
      qos_class                    = "level4"
      target_dscp                  = "VA"
      consumed_contract_interfaces = [aci_imported_contract.imported_contract.id]
      provided_contracts           = [aci_contract.rs_prov_contract.id]
      consumed_contracts           = [aci_contract.rs_cons_contract.id]
      taboo_contracts              = [aci_taboo_contract.taboo_contract.id]
      inherited_contracts          = [aci_external_network_instance_profile.l3out_external_epgs.id]
      route_control_profiles = [
        {
          direction    = "export"
          route_map_dn = aci_route_control_profile.profile1.id
        },
        {
          direction    = "import"
          route_map_dn = aci_route_control_profile.profile3.id
        }
      ]
      subnets = [
        {
          ip        = "172.16.0.0/24"
          scope     = ["import-rtctrl"]
          aggregate = "none"

        },
        {
          ip        = "11.0.0.0/24"
          scope     = ["export-rtctrl"]
          aggregate = "none"
          route_control_profiles = [
            {
              direction    = "export"
              route_map_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
      ]
    },
    {
      name                   = "ext_epg2"
      description            = "l3out_ext_epg2"
      label_match_criteria   = "All"
      preferred_group_member = false
      qos_class              = "level1"
      target_dscp            = "CS0"
      route_control_profiles = [
        {
          direction    = "export"
          route_map_dn = aci_route_control_profile.profile2.id
        }
      ]
      subnets = [
        {
          ip        = "173.23.2.0/24"
          scope     = ["import-rtctrl"]
          aggregate = "none"

        },
      ]
    },
    {
      name                        = "ext_epg3"
      description                 = "l3out_ext_epg3"
      label_match_criteria        = "All"
      preferred_group_member      = true
      qos_class                   = "level3"
      target_dscp                 = "CS4"
      consumed_contract_interface = aci_imported_contract.imported_contract.id
      subnets = [
        {
          ip        = "21.1.1.0/24"
          scope     = ["import-rtctrl"]
          aggregate = "none"
          route_control_profiles = [
            {
              direction    = "import"
              route_map_dn = aci_route_control_profile.profile2.id
            }
          ]
        },
        {
          ip        = "33.1.1.0/24"
          scope     = ["export-rtctrl"]
          aggregate = "none"
        }
      ]
    }
  ]

  logical_node_profiles = [
    {
      name        = "node_profile1"
      target_dscp = "VA"
      bgp_protocol_profile = {
        bgp_timers     = aci_bgp_timers.timer.id
        as_path_policy = aci_bgp_best_path_policy.best_path_policy.id
      }
      bfd_multihop_protocol_profile = {
        bfd_multihop_node_policy_name = aci_rest_managed.bfd_multihop_protocol_profile.content.name
      }
      nodes = [
        {
          node_id            = "101"
          pod_id             = "1"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.31.101"
          static_routes = [
            {
              ip                  = "11.0.0.3/24"
              fallback_preference = "1"
              route_control       = true
              next_hop_addresses = [
                {
                  next_hop_ip          = "172.16.31.9"
                  nexthop_profile_type = "prefix"
                },
                {
                  next_hop_ip          = "172.16.31.20"
                  nexthop_profile_type = "prefix"
                },
              ]
            },
            {
              ip                  = "12.0.0.2/24"
              fallback_preference = "3"
              route_control       = false
              next_hop_addresses = [
                {
                  next_hop_ip          = "172.16.31.9"
                  nexthop_profile_type = "prefix"
                },
                {
                  next_hop_ip          = "172.16.31.21"
                  nexthop_profile_type = "prefix"
                },
              ]
            }
          ]
        },
        {
          node_id            = "105"
          pod_id             = "1"
          router_id          = "102.102.102.102"
          router_id_loopback = "no"
        },
      ]
      interfaces = [
        {
          name = "interface1"
          bfd_interface_profile = {
            authentication_key     = "sh1"
            authentication_key_id  = "1"
            interface_profile_type = "sha1"
            bfd_interface_policy   = aci_bfd_interface_policy.bfd.id
          }
          paths = [
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/26"
              path_type      = "port"
              ip_address     = "13.1.1.1/24"
              target_dscp    = "EF"
              bgp_peers = [
                {
                  ip_address          = "10.1.1.2"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    as_override = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                },
                {
                  ip_address          = "10.1.1.49"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  peer_controls       = ["bfd"]
                  private_as_control  = ["remove-all", "remove-exclusive"]
                  admin_state         = "disabled"
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/27"
              path_type      = "port"
              ip_address     = "14.1.1.2/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "103"
              interface_id   = "eth1/28"
              path_type      = "port"
              ip_address     = "11.1.1.3/24"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "11.1.1.5/24"
                  ipv6_dad   = "enabled"
                },
                {
                  ip_address = "11.1.1.6/24"
                  ipv6_dad   = "disabled"
                },
              ]
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "104"
              interface_id   = "eth1/29"
              path_type      = "pc"
              ip_address     = "12.1.1.4/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "106"
              interface_id   = "eth1/30"
              path_type      = "pc"
              ip_address     = "13.1.1.5/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              interface_id   = "eth1/31"
              path_type      = "pc"
              ip_address     = "15.1.1.9/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/31"
              path_type      = "vpc"
              #ip_address     = "0.0.0.0/0"
              target_dscp = "EF"
              side_A = {
                ip_address = "15.1.1.9/24"
                secondary_addresses = [
                  {
                    ip_address = "15.1.1.10/24"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.11/24"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.12/24"
                    ipv6_dad   = "disabled"
                  },
                ]
              }
              side_B = {
                ip_address = "15.1.1.13/24"
                secondary_addresses = [
                  {
                    ip_address = "15.1.1.14/24"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.15/24"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.16/24"
                    ipv6_dad   = "disabled"
                  },
                ]
              }
            },
          ]
          floating_svi = [
            {
              pod_id              = "1"
              node_id             = "106"
              ip_address          = "19.1.1.18/24"
              encap               = "vlan-1"
              mac                 = "00:22:BD:F8:19:FF"
              target_dscp         = "EF"
              secondary_addresses = ["19.1.1.30/24", "19.1.1.31/24", "19.1.1.32/24"]
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "19.1.2.1/24"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["19.1.23.1/24", "19.1.23.2/24", "19.1.23.3/24"]
                }
              ]
              bgp_peers = [
                {
                  ip_address          = "10.1.1.26"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    allow_self_as = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "disabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile1.id
                    },
                  ]

                },
                {
                  ip_address          = "10.1.1.4"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    send_com = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile1.id
                    },
                    {
                      direction = "import"
                      target_dn = aci_route_control_profile.profile1.id
                    }
                  ]
                },
              ]
            },
            {
              pod_id      = "106"
              node_id     = "1"
              ip_address  = "20.1.1.4/24"
              encap       = "vlan-2"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "10.23.2.2/24"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["10.34.23.1/24", "10.34.23.2/24", "10.34.23.3/24"]
                }
              ]
              bgp_peers = [
                {
                  ip_address          = "10.1.1.23"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    send_ext_com = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "disabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile2.id
                    }
                  ]
                },
            ] }
          ]


        },
        {
          name = "interface2"
          netflow_monitor_policies = [
            {
              filter_type                 = "ce"
              netflow_monitor_policy_name = aci_rest_managed.netflow1.id
            },
            {
              filter_type                 = "ipv4"
              netflow_monitor_policy_name = aci_rest_managed.netflow2.id
            }
          ]
          bfd_multihop_interface_profile = {
            authentication_key_id              = "1"
            authentication_type                = "sha1"
            bfd_multihop_interface_policy_name = aci_rest_managed.bfd_multihop_interface_profile1.content.name
          }
          paths = [
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/25"
              path_type      = "port"
              ip_address     = "17.1.1.1/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/26"
              path_type      = "port"
              ip_address     = "18.1.1.2/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "104"
              interface_id   = "eth1/28"
              path_type      = "pc"
              ip_address     = "19.1.1.87/24"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "10.1.1.5/24"
                  ipv6_dad   = "disabled"
                },
                {
                  ip_address = "10.1.1.6/24"
                  ipv6_dad   = "disabled"
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "106"
              interface_id   = "eth1/29"
              path_type      = "pc"
              ip_address     = "20.1.1.76/24"
              target_dscp    = "EF"
            },
          ]
        },
      ]
    },
    {
      name        = "node_profile2"
      target_dscp = "AF11"
      bfd_multihop_protocol_profile = {
        authentication_type           = "sha1"
        authentication_key_id         = "1"
        bfd_multihop_node_policy_name = aci_rest_managed.bfd_multihop_protocol_profile.content.name
      }
      nodes = [
        {
          node_id            = "101"
          pod_id             = "1"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_address   = "175.16.31.101"
          static_routes = [
            {
              ip                  = "16.0.0.3/24"
              fallback_preference = "1"
              route_control       = true
              next_hop_addresses = [
                {
                  next_hop_ip          = "175.16.31.9"
                  nexthop_profile_type = "prefix"
                },
                {
                  next_hop_ip          = "175.16.31.20"
                  nexthop_profile_type = "prefix"
                },
              ]
            },
          ]
        },
      ]
      bgp_peers_nodes = [
        {
          ip_address          = "10.1.1.20"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "1"
          bgp_controls = {
            allow_self_as = true
            nh_self       = true
          }
          peer_controls      = ["bfd"]
          private_as_control = ["remove-all", "remove-exclusive"]
          admin_state        = "disabled"
          route_control_profiles = [
            {
              direction = "import"
              target_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
        {
          ip_address          = "10.1.1.45"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "1"
          bgp_controls = {
            dis_peer_as_check = true
          }
          peer_controls      = ["bfd"]
          private_as_control = ["remove-all", "remove-exclusive"]
          admin_state        = "enabled"
          route_control_profiles = [
            {
              direction = "export"
              target_dn = aci_route_control_profile.profile2.id
            },
            {
              direction = "import"
              target_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
      ]
      interfaces = [
        {
          name = "interface"
          bfd_interface_profile = {
            authentication_key     = "sh1"
            authentication_key_id  = "5"
            interface_profile_type = "sha1"
            bfd_interface_policy   = aci_bfd_interface_policy.bfd.id
          }
          bfd_multihop_interface_profile = {
            authentication_key_id              = "4"
            authentication_type                = "sha1"
            bfd_multihop_interface_policy_name = aci_rest_managed.bfd_multihop_interface_profile2.content.name
          }
        },
      ]
    },
    {
      name        = "node_profile3"
      target_dscp = "EF"
      bgp_peers_nodes = [
        {
          ip_address          = "10.1.1.234"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "1"
          peer_controls       = ["bfd"]
          private_as_control  = ["remove-all", "remove-exclusive"]
          admin_state         = "enabled"
          route_control_profiles = [
            {
              direction = "export"
              target_dn = aci_route_control_profile.profile2.id
            },
            {
              direction = "import"
              target_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
      ]
      bgp_protocol_profile = {
        bgp_timers     = aci_bgp_timers.timer.id
        as_path_policy = aci_bgp_best_path_policy.best_path_policy.id
      }
      nodes = [
        {
          node_id            = "103"
          pod_id             = "1"
          router_id          = "104.104.104.104"
          router_id_loopback = "yes"
          static_routes = [
            {
              ip                  = "10.0.0.3/24"
              fallback_preference = "1"
              route_control       = true
              next_hop_addresses = [
                {
                  next_hop_ip          = "172.16.31.10"
                  nexthop_profile_type = "prefix"
                },
                {
                  next_hop_ip          = "172.16.31.12"
                  nexthop_profile_type = "prefix"
                }
              ]
            },
            {
              ip                  = "10.0.0.2/24"
              fallback_preference = "2"
              route_control       = false
              next_hop_addresses = [
                {
                  next_hop_ip          = "172.16.31.9"
                  nexthop_profile_type = "prefix"
                },
                {
                  next_hop_ip          = "172.16.31.12"
                  nexthop_profile_type = "prefix"
                },
              ]
            },
          ]
        },
        {
          node_id            = "102"
          pod_id             = "1"
          router_id          = "105.105.105.105"
          router_id_loopback = "no"
          loopback_address   = "172.16.31.104"
          static_routes = [
            {
              ip                  = "10.0.0.6/24"
              fallback_preference = "1"
              route_control       = true
            },
            {
              ip                  = "10.0.0.7/24"
              fallback_preference = "2"
              next_hop_addresses = [
                {
                  next_hop_ip          = "172.16.31.9"
                  nexthop_profile_type = "prefix"
                  description          = "hop 1"
                },
                {
                  next_hop_ip          = "172.16.31.13"
                  nexthop_profile_type = "prefix"
                  description          = "hop 2"
                },
                {
                  next_hop_ip = "172.16.31.15"
                  description = "hop 3"
                },
              ]
            }
          ]
        },
      ]
      interfaces = [
        {
          name = "interface5"
          netflow_monitor_policies = [
            {
              filter_type                 = "ipv6"
              netflow_monitor_policy_name = aci_rest_managed.netflow2.id
            },
            {
              filter_type                 = "ce"
              netflow_monitor_policy_name = aci_rest_managed.netflow1.id
            }
          ]
        },
        {
          name = "interface3"
          bfd_interface_profile = {
            authentication_key     = "sh5"
            authentication_key_id  = "1"
            interface_profile_type = "sha1"
            bfd_interface_policy   = aci_bfd_interface_policy.bfd.id
          }
          hsrp = {
            version = "v2"
            hsrp_groups = [
              {
                name                  = "hsrp1"
                address_family        = "ipv4"
                group_id              = "2"
                ip                    = "10.22.30.41"
                ip_obtain_mode        = "admin"
                mac                   = "02:10:45:00:00:57"
                secondary_virtual_ips = ["191.1.1.1", "191.1.1.2"]
              },
              {
                name           = "hsrp2"
                address_family = "ipv4"
                group_id       = "1"
                ip_obtain_mode = "learn"
                mac            = "02:10:45:00:00:56"
              },
            ]
          }
          paths = [
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/25"
              path_type      = "port"
              ip_address     = "17.1.1.1/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/28"
              path_type      = "pc"
              ip_address     = "10.1.1.27/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "103"
              interface_id   = "eth1/29"
              path_type      = "pc"
              ip_address     = "20.1.1.89/24"
              target_dscp    = "EF"
            },
          ]
        },
        {
          name = "interface4"
          paths = [
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/25"
              path_type      = "port"
              ip_address     = "17.1.1.1/24"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "10.1.1.2/24"
                  ipv6_dad   = "disabled"
                },
                {
                  ip_address = "10.1.1.3/24"
                  ipv6_dad   = "disabled"
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/26"
              path_type      = "port"
              ip_address     = "18.1.1.2/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "103"
              interface_id   = "eth1/27"
              path_type      = "port"
              ip_address     = "11.1.1.3/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "104"
              interface_id   = "eth1/28"
              path_type      = "pc"
              ip_address     = "19.1.1.87/24"
              target_dscp    = "EF"
              bgp_peers = [
                {
                  ip_address          = "10.1.1.20"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    allow_self_as     = true
                    dis_peer_as_check = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "disabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile2.id
                    }
                  ]
                },
                {
                  ip_address          = "10.1.1.45"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    allow_self_as     = true
                    dis_peer_as_check = true
                    nh_self           = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile2.id
                    },
                    {
                      direction = "import"
                      target_dn = aci_route_control_profile.profile1.id
                    }
                  ]
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "106"
              interface_id   = "eth1/29"
              path_type      = "pc"
              ip_address     = "20.1.1.76/24"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/31"
              path_type      = "vpc"
              #ip_address     = "0.0.0.0/0"
              target_dscp = "EF"
              bgp_peers = [
                {
                  ip_address          = "10.1.1.25"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    send_com = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile2.id
                    },
                    {
                      direction = "import"
                      target_dn = aci_route_control_profile.profile1.id
                    }
                  ]
                },
              ]
              side_A = {
                ip_address = "15.1.1.9/24"
                secondary_addresses = [
                  {
                    ip_address = "15.1.1.10/24"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.11/24"
                    ipv6_dad   = "disabled"
                  },
                ]
              }
              side_B = {
                ip_address = "15.1.1.13/24"
              }
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/30"
              path_type      = "pc"
              ip_address     = "15.1.1.9/24"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "10.1.1.2/24"
                  ipv6_dad   = "enabled"
                },
                {
                  ip_address = "10.1.1.8/24"
                  ipv6_dad   = "disabled"
                },
              ]
            },
          ]
          floating_svi = [
            {
              pod_id      = "1"
              node_id     = "106"
              ip_address  = "15.1.1.18/24"
              encap       = "vlan-3"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  vlan                = "vlan-3"
                  floating_address    = "10.23.2.5/24"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["10.34.23.1/24", "10.34.23.2/24", "10.34.23.3/24"]
                }
              ]
              bgp_peers = [
                {
                  ip_address          = "10.1.1.21"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  peer_controls       = ["bfd"]
                  private_as_control  = ["remove-all", "remove-exclusive"]
                  admin_state         = "disabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile2.id
                    }
                  ]
                },
                {
                  ip_address          = "10.1.1.42"
                  address_control     = ["af-mcast", "af-ucast"]
                  allowed_self_as_cnt = "1"
                  bgp_controls = {
                    as_override = true
                  }
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile2.id
                    },
                    {
                      direction = "import"
                      target_dn = aci_route_control_profile.profile1.id
                    }
                  ]
                },
              ]
            },
            {
              pod_id      = "1"
              node_id     = "107"
              ip_address  = "10.1.1.19/24"
              encap       = "vlan-4"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "10.23.2.8/24"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["10.34.23.1/24", "10.34.23.2/24", "10.34.23.3/24"]
                }
              ]
            },
          ]
        },
      ]
    }
  ]
}

# output "module"{
#   value = module.l3out.l3out_dn
# }