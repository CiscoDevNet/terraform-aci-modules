// Test file for nodes with ospf enabled
module "ospf_nodes" {
  source      = "../../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_l3out_nodes_ospf"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf6.id

  ospf = {
    area_cost = "1"
    area_ctrl = ["redistribute"]
    area_id   = "2"
    area_type = "regular"
  }

  ospf_interface_profile = {
    ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
    authentication_key_id = "2"
  }

  nodes = [
    {
      node_id          = "201"
      pod_id           = "1"
      router_id        = "111.111.111.111"
      loopback_address = "172.16.31.101"
      static_routes = [
        {
          prefix              = "20.0.0.3/24"
          fallback_preference = "1"
          route_control       = true
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.91"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.92"
              next_hop_profile_type = "prefix"
            },
          ]
        },
        {
          prefix              = "21.0.0.2/24"
          fallback_preference = "3"
          route_control       = false
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.93"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.94"
              next_hop_profile_type = "prefix"
            },
          ]
        }
      ]
      interfaces = [
        {
          port                     = "1/20"
          ip                       = "15.14.15.1/24"
          ipv6                     = "2005:db8:e::2/64"
          secondary_ip_addresses   = ["15.15.15.1/24", "15.16.15.1/24", "15.17.15.1/24"]
          secondary_ipv6_addresses = ["2005:db8:e::3/64", "2005:db8:e::4/64", "2005:db8:e::5/64"]
        },
        {
          port = "1/21"
          ip   = "15.1.1.2/24"
          ipv6 = "2005:db8:b::2/64"
          vlan = "2"
        },
        {
          port = "1/22"
          ip   = "16.1.1.49/24"
          ipv6 = "2006:db8:c::2/64"
          vlan = "4"
          svi  = true
        },
        {
          channel                = "channel-ten"
          ip                     = "14.14.14.1/24"
          secondary_ip_addresses = ["15.15.14.1/24", "15.16.14.1/24", "15.17.14.1/24"]
        },
        {
          channel                = "channel-eleven"
          ip                     = "15.1.16.2/24"
          secondary_ip_addresses = ["15.2.16.2/24", "15.3.16.2/24", "15.4.16.2/24"]
          vlan                   = "2"

        },
        {
          channel                = "channel-twelve"
          ip                     = "175.16.103.3/24"
          secondary_ip_addresses = ["175.17.103.3/24", "175.18.103.3/24", "175.19.103.3/24"]
          vlan                   = "2"
          svi                    = true
        },
        {
          channel = "channel-thirteen"
          ipv6    = "2001:db8:a::2/64"
        },
      ]
    },
    {
      node_id          = "202"
      pod_id           = "2"
      router_id        = "112.112.112.112"
      loopback_address = "172.16.31.102"
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy2.id
        authentication_key_id = "3"
      }
      interfaces = [
        {
          port = "1/23"
          ip   = "15.14.16.1/24"
          ipv6 = "2006:db8:d::2/64"
        },
        {
          channel = "channel-fourteen"
          ip      = "15.14.17.1/24"
        },
      ]
    },
    {
      node_id          = "203"
      pod_id           = "1"
      router_id        = "113.113.113.113"
      loopback_address = "172.16.31.103"
      interfaces = [
        {
          channel = "channel-fifteen"
          ip      = "15.14.18.1/24"
        },
      ]
    },
    {
      node_id          = "204"
      pod_id           = "1"
      router_id        = "114.114.114.114"
      loopback_address = "172.16.31.104"
      static_routes = [
        {
          prefix              = "10.1.0.6/24"
          fallback_preference = "1"
          route_control       = true
        },
      ]
      interfaces = [
        {
          port = "1/24"
          ip   = "15.14.19.1/24"
          ipv6 = "2005:db8:f::2/64"
        },
      ]
    },
    {
      node_id          = "205"
      pod_id           = "1"
      router_id        = "115.115.115.115"
      loopback_address = "172.16.31.106"
      interfaces = [
        {
          port = "1/25"
          ip   = "15.14.20.1/24"
          ipv6 = "2005:db9:a::2/64"
        },
      ]
    },
    {
      node_id          = "206"
      pod_id           = "1"
      router_id        = "116.116.116.116"
      loopback_address = "172.16.31.107"
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy3.id
        authentication_key_id = "4"
      }
      interfaces = [
        {
          port                     = "1/26"
          ip                       = "15.14.21.1/24"
          ipv6                     = "2005:db9:b::2/64"
          secondary_ip_addresses   = ["15.15.21.1/24", "15.16.21.1/24", "15.17.21.1/24"]
          secondary_ipv6_addresses = ["2005:db9:b::3/64", "2005:db9:b::4/64", "2005:db9:b::5/64"]
        },
        {
          channel = "channel-sixteen"
          ip      = "15.14.22.1/24"
        },
      ]
    },
    {
      node_id          = "207"
      pod_id           = "1"
      router_id        = "117.117.117.117"
      loopback_address = "172.16.31.108"
      interfaces = [
        {
          channel = "channel-seventeen"
          ipv6    = "2005:db8:e::5/64"
        },
      ]
    },
    {
      node_id          = "208"
      pod_id           = "1"
      router_id        = "118.118.118.118"
      loopback_address = "172.16.31.109"
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy4.id
        authentication_key_id = "5"
      }
      static_routes = [
        {
          prefix              = "10.1.0.3/24"
          fallback_preference = "1"
          route_control       = true
          next_hop_addresses = [
            {
              next_hop_ip           = "173.16.31.10"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "173.16.31.12"
              next_hop_profile_type = "prefix"
            }
          ]
        },
        {
          prefix              = "10.1.0.2/24"
          fallback_preference = "2"
          route_control       = false
          next_hop_addresses = [
            {
              next_hop_ip           = "173.16.31.9"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "173.16.31.12"
              next_hop_profile_type = "prefix"
            },
          ]
        },
      ]
      interfaces = [
        {
          port = "1/26"
          ip   = "15.14.15.5/24"
          ipv6 = "2005:db8:e::3/64"
        },
        {
          port = "1/27"
          ip   = "15.1.1.3/24"
          ipv6 = "2005:db8:b::3/64"
          vlan = "2"
        },
        {
          port = "1/28"
          ip   = "15.2.1.5/24"
          ipv6 = "2005:db8:c::3/64"
          vlan = "4"
          svi  = true
        },
        {
          channel = "channel-seventeen"
          ip      = "15.14.14.2/24"
        },
        {
          channel = "channel-eighteen"
          ip      = "5.1.16.3/24"
          vlan    = "2"

        },
        {
          channel = "channel-nineteen"
          ip      = "172.16.103.4/24"
          vlan    = "2"
          svi     = true
        },
        {
          channel                  = "channel-twenty"
          ipv6                     = "2005:db8:a::3/64"
          secondary_ipv6_addresses = ["2005:db8:a::4/64", "2005:db8:a::5/64", "2005:db8:a::6/64"]
        },
      ]
    },
    {
      node_id          = "209"
      pod_id           = "1"
      router_id        = "119.119.119.119"
      loopback_address = "172.16.31.110"
      interfaces = [
        {
          port = "1/29"
          ip   = "11.1.1.18/24"
          ipv6 = "2005:db9:c::9/64"
          vlan = "4"
          svi  = true
        },
        {
          port = "1/30"
          ip   = "11.1.1.18/24"
          ipv6 = "2005:db9:c::9/64"
          vlan = "4"
          svi  = true
        },
      ]
    }
  ]
}