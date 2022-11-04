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

module "l3out" {
  source                         = "./l3out"
  tenant_dn                      = aci_tenant.tenant.id
  name                           = "module_l3out"
  alias                          = "l3out"
  description                    = "Created by l3out module"
  route_control_enforcement      = true
  target_dscp                    = "EF"
  vrf_dn                         = "uni/tn-vEPC/ctx-VRF"
  l3_domain_dn                   = "uni/l3dom-ansible_l3_dom"
  route_profile_for_interleak_dn = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
  route_control_for_dampening = [
    {
      address_family = "ipv4"
      route_map_dn   = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
    },
    {
      address_family = "ipv6"
      route_map_dn   = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
    }
  ]
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
          route_map_dn = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
        },
        {
          direction    = "import"
          route_map_dn = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
        }
      ]
      subnets = [
        {
          ip        = "10.0.0.0/24"
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
          route_map_dn = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
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
          set_rule_dn = "uni/tn-common/attr-SET-SNJ-AWS-NONPROD-SECONDARY-MS"
        },
        {
          name           = "control2"
          action         = "deny"
          order          = "1"
          set_rule_dn    = "uni/tn-common/attr-ok"
          match_rules_dn = ["uni/tn-common/subj-PREFIX-AWS-NONPROD-MS", "uni/tn-common/subj-DEFAULT-ROUTE-MS"]
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
          set_rule_dn    = "uni/tn-common/attr-SET-SNJ-AWS-NONPROD-SECONDARY-MS"
          match_rules_dn = ["uni/tn-common/subj-DEFAULT-ROUTE-MS"]
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
          set_rule_dn    = "uni/tn-common/attr-SET-SNJ-AWS-NONPROD-SECONDARY-MS"
          match_rules_dn = ["uni/tn-common/subj-DEFAULT-ROUTE-MS", "uni/tn-common/subj-PREFIX-AWS-NONPROD-MS", "uni/tn-common/subj-PREFIX-AWS-NP-1-TDXG-UW2"]
        },
        {
          name           = "control5"
          action         = "deny"
          order          = "1"
          set_rule_dn    = "uni/tn-common/attr-SET-SNJ-AWS-NONPROD-SECONDARY-MS"
          match_rules_dn = ["uni/tn-common/subj-PREFIX-AWS-NP-1-TDXG-UW2", "uni/tn-common/subj-PREFIX-AWS-NONPROD-MS"]
        },
      ]
    }
  ]
  logical_node_profiles = [
    {
      name          = "node_profile1"
      config_issues = "none"
      target_dscp   = "VA"
      nodes = [
        {
          #node_dn            = "topology/pod-1/node-101"
          node_id            = "101"
          pod_id             = "1"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_addresses = "172.16.31.101"
          static_routes = [
            {
              ip                  = "10.0.0.3/12"
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
              ip                  = "10.0.0.2/12"
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
    },
    {
      name          = "node_profile2"
      config_issues = "routerid-not-changable-with-mcast"
      target_dscp   = "AF11"
    },
    {
      name          = "node_profile3"
      config_issues = "node-path-misconfig"
      target_dscp   = "EF"
      nodes = [
        {
          # node_dn            = "topology/pod-1/node-103"
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
    }
  ]
}

output "test" {
  value = module.l3out.logical_nodes_static_routes
}
