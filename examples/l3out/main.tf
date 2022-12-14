terraform {
  required_providers {
    aci = {
      source = "ciscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = ""
  password = ""
  url      = ""
  insecure = true
}

# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "module_l3out_tf_tenant"
  description = "Created for l3out module"
}

resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf1"
}

resource "aci_l3_domain_profile" "profile" {
  name = "l3_domain_profile"
}

resource "aci_route_control_profile" "profile" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile"
  route_control_profile_type = "global"
}

resource "aci_route_control_profile" "profile2" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile2"
  route_control_profile_type = "global"
}

resource "aci_match_rule" "rule" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule"
}

resource "aci_match_rule" "rule2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule2"
}

resource "aci_match_rule" "rule3" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule3"
}

resource "aci_action_rule_profile" "set_rule" {
  tenant_dn = aci_tenant.tenant.id
  name      = "rule1"
}

resource "aci_action_rule_profile" "set_rule2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "rule2"
}

resource "aci_bgp_timers" "timer" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "timer1"
  gr_ctrl      = "helper"
  hold_intvl   = "189"
  ka_intvl     = "65"
  max_as_limit = "70"
  name_alias   = "aliasing"
  stale_intvl  = "15"
}

resource "aci_bgp_best_path_policy" "best_path_policy" {
  tenant_dn = aci_tenant.tenant.id
  name      = "bgp_path1"
  ctrl      = "asPathMultipathRelax"
}

module "l3out" {
  source                         = "./l3out"
  tenant_dn                      = aci_tenant.tenant.id
  name                           = "module_l3out"
  alias                          = "l3out"
  description                    = "Created by l3out module"
  route_control_enforcement      = true
  target_dscp                    = "EF"
  vrf_dn                         = aci_vrf.vrf.id
  l3_domain_dn                   = aci_l3_domain_profile.profile.id
  route_profile_for_interleak_dn = aci_route_control_profile.profile.id
  route_control_for_dampening = [
    {
      address_family = "ipv4"
      route_map_dn   = aci_route_control_profile.profile.id
    },
    {
      address_family = "ipv6"
      route_map_dn   = aci_route_control_profile.profile.id
    }
  ]
  route_profiles_for_redistribution = [
    {
      source       = "static"
      route_map_dn = aci_route_control_profile.profile.id
    },
    {
      source       = "direct"
      route_map_dn = aci_route_control_profile.profile2.id
    }
  ]
  multicast = {
    address_families = ["ipv4", "ipv6"]
  }
  external_epgs = [
    {
      name                   = "ext_epg1"
      description            = "l3out_ext_epg1"
      flood_on_encap         = "enabled"
      label_match_criteria   = "All"
      preferred_group_member = true
      qos_class              = "level4"
      target_dscp            = "VA"
      route_control_profiles = [
        {
          direction    = "export"
          route_map_dn = aci_route_control_profile.profile.id
        },
        {
          direction    = "import"
          route_map_dn = aci_route_control_profile.profile.id
        }
      ]
      subnets = [
        {
          ip        = "172.16.0.0/16/24"
          scope     = ["import-rtctrl", "export-rtctrl"]
          aggregate = "shared-rtctrl"

        },
        {
          ip        = "11.0.0.0/24"
          scope     = ["import-rtctrl", "export-rtctrl"]
          aggregate = "none"
          route_control_profiles = [
            {
              direction    = "export"
              route_map_dn = "uni/tn-module_l3out_tf_tenant/out-module_l3out/prof-test"
            }
          ]
        },
      ]
    },
    {
      name                   = "ext_epg2"
      description            = "l3out_ext_epg2"
      flood_on_encap         = "enabled"
      label_match_criteria   = "All"
      preferred_group_member = false
      qos_class              = "level1"
      target_dscp            = "CS0"
      route_control_profiles = [
        {
          direction    = "export"
          route_map_dn = aci_route_control_profile.profile.id
        }
      ]
    },
    {
      name                   = "ext_epg3"
      description            = "l3out_ext_epg3"
      flood_on_encap         = "disabled"
      label_match_criteria   = "All"
      preferred_group_member = true
      qos_class              = "level3"
      target_dscp            = "CS4"
      subnets = [
        {
          ip        = "21.1.1.0/24"
          scope     = ["import-rtctrl", "export-rtctrl"]
          aggregate = "shared-rtctrl"
          route_control_profiles = [
            {
              direction    = "import"
              route_map_dn = "uni/tn-module_l3out_tf_tenant/out-module_l3out/prof-ok"
            }
          ]
        },
        {
          ip        = "33.1.1.0/24"
          scope     = ["import-rtctrl", "export-rtctrl"]
          aggregate = "none"
        }
      ]
    }
  ]
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
  logical_node_profiles = [
    {
      name          = "node_profile1"
      config_issues = "none"
      target_dscp   = "VA"
      bgp_protocol_profile = {
        bgp_timers     = aci_bgp_timers.timer.id
        as_path_policy = aci_bgp_best_path_policy.best_path_policy.id
      }
      nodes = [
        {
          node_id            = "101"
          pod_id             = "1"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_addresses = "172.16.31.101"
          static_routes = [
            {
              ip                  = "11.0.0.3/12"
              aggregate           = "no"
              fallback_preference = "1"
              route_control       = "bfd"
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
              ip                  = "12.0.0.2/12"
              aggregate           = "yes"
              fallback_preference = "3"
              route_control       = "unspecified"
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
          bfd = {
            authentication_key     = "sh1"
            authentication_key_id  = "1"
            interface_profile_type = "sha1"
            bfd_interface_policy   = "uni/tn-common/bfdIfPol-BFD_POLICY"
          }
          paths = [
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/26"
              path_type      = "port"
              ip_address     = "13.1.1.1/12"
              target_dscp    = "EF"
              bgp_peers = [
                {
                  ip_address         = "10.1.1.2"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                },
                {
                  ip_address         = "10.1.1.49"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "disabled"
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/27"
              path_type      = "port"
              ip_address     = "14.1.1.2/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "103"
              interface_id   = "eth1/28"
              path_type      = "port"
              ip_address     = "11.1.1.3/12"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "11.1.1.5/12"
                  ipv6_dad   = "enabled"
                },
                {
                  ip_address = "11.1.1.6/12"
                  ipv6_dad   = "disabled"
                },
              ]
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "104"
              node2_id       = "105"
              interface_id   = "eth1/29"
              path_type      = "dpc"
              ip_address     = "12.1.1.4/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "106"
              node2_id       = "107"
              interface_id   = "eth1/30"
              path_type      = "dpc"
              ip_address     = "13.1.1.5/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/31"
              path_type      = "dpc"
              ip_address     = "15.1.1.9/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/31"
              path_type      = "vpc"
              ip_address     = "15.1.1.7/12"
              target_dscp    = "EF"
              side_A = {
                ip_address = "15.1.1.9/12"
                secondary_addresses = [
                  {
                    ip_address = "15.1.1.10/12"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.11/12"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.12/12"
                    ipv6_dad   = "disabled"
                  },
                ]
              }
              side_B = {
                ip_address = "15.1.1.13/12"
                secondary_addresses = [
                  {
                    ip_address = "15.1.1.14/12"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.15/12"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.16/12"
                    ipv6_dad   = "disabled"
                  },
                ]
              }
            },
          ]
          floating_svi = [
            {
              pod_id      = "106"
              node_id     = "1"
              ip_address  = "19.1.1.18/12"
              encap       = "vlan-1"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  target_dn           = "uni/phys-PhyDom"
                  floating_address    = "10.23.2.1/12"
                  forged_transmit     = "Disabled"
                  mac_change          = "Disabled"
                  promiscuous_mode    = "Disabled"
                  secondary_addresses = ["10.34.23.1/12", "10.34.23.2/12", "10.34.23.3/12"]
                }
              ]
              bgp_peers = [
                {
                  ip_address         = "10.1.1.26"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "disabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile.id
                    },
                  ]

                },
                {
                  ip_address         = "10.1.1.4"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
                  peer_controls      = ["bfd"]
                  private_as_control = ["remove-all", "remove-exclusive"]
                  admin_state        = "enabled"
                  route_control_profiles = [
                    {
                      direction = "export"
                      target_dn = aci_route_control_profile.profile.id
                    },
                    {
                      direction = "import"
                      target_dn = aci_route_control_profile.profile.id
                    }
                  ]
                },
              ]
            },
            {
              pod_id      = "106"
              node_id     = "1"
              ip_address  = "20.1.1.4/12"
              encap       = "vlan-2"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  target_dn           = "uni/phys-PhyDom"
                  floating_address    = "10.23.2.2/12"
                  forged_transmit     = "Disabled"
                  mac_change          = "Disabled"
                  promiscuous_mode    = "Disabled"
                  secondary_addresses = ["10.34.23.1/12", "10.34.23.2/12", "10.34.23.3/12"]
                }
              ]
              bgp_peers = [
                {
                  ip_address         = "10.1.1.23"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
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
          hsrp = {
            version = "v1"
            hsrp_groups = [
              {
                name           = "hsrp_1"
                address_family = "ipv4"
                group_id       = "1"
                #ip             = "10.22.30.40"
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
              ip_address     = "17.1.1.1/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/26"
              path_type      = "port"
              ip_address     = "18.1.1.2/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "104"
              node2_id       = "105"
              interface_id   = "eth1/28"
              path_type      = "dpc"
              ip_address     = "19.1.1.87/12"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "10.1.1.5/12"
                  ipv6_dad   = "disabled"
                },
                {
                  ip_address = "10.1.1.6/12"
                  ipv6_dad   = "disabled"
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "106"
              node2_id       = "107"
              interface_id   = "eth1/29"
              path_type      = "dpc"
              ip_address     = "20.1.1.76/12"
              target_dscp    = "EF"
            },
          ]
        },
      ]
    },
    {
      name          = "node_profile2"
      config_issues = "routerid-not-changable-with-mcast"
      target_dscp   = "AF11"
      bgp_peers_nodes = [
        {
          ip_address         = "10.1.1.20"
          address_control    = ["af-mcast", "af-ucast"]
          allowed_self_as    = "1"
          bgp_controls       = ["allow-self-as"]
          peer_controls      = ["bfd"]
          private_as_control = ["remove-all", "remove-exclusive"]
          admin_state        = "disabled"
          route_control_profiles = [
            {
              direction = "import"
              target_dn = aci_route_control_profile.profile.id
            }
          ]
        },
        {
          ip_address         = "10.1.1.45"
          address_control    = ["af-mcast", "af-ucast"]
          allowed_self_as    = "1"
          bgp_controls       = ["allow-self-as"]
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
              target_dn = aci_route_control_profile.profile.id
            }
          ]
        },
      ]
      interfaces = [
        {
          name = "interface"
          bfd = {
            authentication_key     = "sh1"
            authentication_key_id  = "5"
            interface_profile_type = "sha1"
            bfd_interface_policy   = "uni/tn-common/bfdIfPol-default"
          }
          hsrp = {
            version = "v1"
            hsrp_groups = [
              {
                name           = "hsrp1"
                address_family = "ipv4"
                group_id       = "2"
                ip_obtain_mode = "learn"
                mac            = "02:10:45:00:00:57"
              },
              {
                name                  = "hsrp2"
                address_family        = "ipv4"
                group_id              = "1"
                ip                    = "10.22.30.40"
                ip_obtain_mode        = "admin"
                mac                   = "02:10:45:00:00:56"
                secondary_virtual_ips = ["191.1.1.1", "191.1.1.2"]
              },
            ]
          }
        },
      ]
    },
    {
      name        = "node_profile3"
      target_dscp = "EF"
      bgp_peers_nodes = [
        {
          ip_address         = "10.1.1.234"
          address_control    = ["af-mcast", "af-ucast"]
          allowed_self_as    = "1"
          bgp_controls       = ["allow-self-as"]
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
              target_dn = aci_route_control_profile.profile.id
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
          loopback_addresses = "172.16.31.106"
          static_routes = [
            {
              ip                  = "10.0.0.3/12"
              aggregate           = "no"
              fallback_preference = "1"
              route_control       = "bfd"
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
              ip                  = "10.0.0.2/12"
              aggregate           = "yes"
              fallback_preference = "2"
              route_control       = "unspecified"
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
              ip                  = "10.0.0.6/12"
              aggregate           = "no"
              fallback_preference = "1"
              route_control       = "bfd"
            },
            {
              ip                  = "10.0.0.7/12"
              aggregate           = "yes"
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
        },
        {
          name = "interface3"
          bfd = {
            authentication_key     = "sh5"
            authentication_key_id  = "1"
            interface_profile_type = "sha1"
            bfd_interface_policy   = "uni/tn-common/bfdIfPol-default"
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
              ip_address     = "17.1.1.1/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/28"
              node2_id       = "102"
              path_type      = "dpc"
              ip_address     = "10.1.1.27/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              node2_id       = "103"
              interface_id   = "eth1/29"
              path_type      = "dpc"
              ip_address     = "20.1.1.89/12"
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
              ip_address     = "17.1.1.1/12"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "10.1.1.2/12"
                  ipv6_dad   = "disabled"
                },
                {
                  ip_address = "10.1.1.3/12"
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
              ip_address     = "18.1.1.2/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "103"
              interface_id   = "eth1/27"
              path_type      = "port"
              ip_address     = "11.1.1.3/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "104"
              node2_id       = "105"
              interface_id   = "eth1/28"
              path_type      = "dpc"
              ip_address     = "19.1.1.87/12"
              target_dscp    = "EF"
              bgp_peers = [
                {
                  ip_address         = "10.1.1.20"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
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
                  ip_address         = "10.1.1.45"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
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
                      target_dn = aci_route_control_profile.profile.id
                    }
                  ]
                },
              ]
            },
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "106"
              node2_id       = "107"
              interface_id   = "eth1/29"
              path_type      = "dpc"
              ip_address     = "20.1.1.76/12"
              target_dscp    = "EF"
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/31"
              path_type      = "vpc"
              ip_address     = "15.1.1.6/12"
              target_dscp    = "EF"
              bgp_peers = [
                {
                  ip_address         = "10.1.1.25"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
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
                      target_dn = aci_route_control_profile.profile.id
                    }
                  ]
                },
              ]
              side_A = {
                ip_address = "15.1.1.9/12"
                secondary_addresses = [
                  {
                    ip_address = "15.1.1.10/12"
                    ipv6_dad   = "disabled"
                  },
                  {
                    ip_address = "15.1.1.11/12"
                    ipv6_dad   = "disabled"
                  },
                ]
              }
              side_B = {
                ip_address = "15.1.1.13/12"
              }
            },
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "108"
              node2_id       = "109"
              interface_id   = "eth1/30"
              path_type      = "dpc"
              ip_address     = "15.1.1.9/12"
              target_dscp    = "EF"
              secondary_addresses = [
                {
                  ip_address = "10.1.1.2/12"
                  ipv6_dad   = "enabled"
                },
                {
                  ip_address = "10.1.1.8/12"
                  ipv6_dad   = "disabled"
                },
              ]
            },
          ]
          floating_svi = [
            {
              pod_id      = "106"
              node_id     = "1"
              ip_address  = "15.1.1.18/12"
              encap       = "vlan-3"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  target_dn           = "uni/phys-PhyDom"
                  vlan                = "vlan-3"
                  floating_address    = "10.23.2.5/12"
                  forged_transmit     = "Disabled"
                  mac_change          = "Disabled"
                  promiscuous_mode    = "Disabled"
                  secondary_addresses = ["10.34.23.1/12", "10.34.23.2/12", "10.34.23.3/12"]
                }
              ]
              bgp_peers = [
                {
                  ip_address         = "10.1.1.21"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
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
                  ip_address         = "10.1.1.42"
                  address_control    = ["af-mcast", "af-ucast"]
                  allowed_self_as    = "1"
                  bgp_controls       = ["allow-self-as"]
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
                      target_dn = aci_route_control_profile.profile.id
                    }
                  ]
                },
              ]
            },
            {
              pod_id      = "106"
              node_id     = "1"
              ip_address  = "10.1.1.19/12"
              encap       = "vlan-4"
              mac         = "00:22:BD:F8:19:FF"
              target_dscp = "EF"
              path_attributes = [
                {
                  target_dn           = "uni/phys-PhyDom"
                  floating_address    = "10.23.2.8/12"
                  forged_transmit     = "Disabled"
                  mac_change          = "Disabled"
                  promiscuous_mode    = "Disabled"
                  secondary_addresses = ["10.34.23.1/12", "10.34.23.2/12", "10.34.23.3/12"]
                }
              ]
            },
          ]
        },
      ]
    }
  ]
}

output "test" {
  value = module.l3out.bgp_peers
}
