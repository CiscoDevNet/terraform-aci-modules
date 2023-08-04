// Test file for vpc with ospf enabled
module "ospf_vpc" {
  source      = "../../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_l3out_vpc_ospf"
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
    authentication_key_id = "1"
  }

  vpcs = [
    {
      pod_id = 1
      nodes = [
        {
          node_id            = "151"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.32.101"
        },
        {
          node_id            = "152"
          router_id          = "1.1.2.101"
          router_id_loopback = "yes"
        },
      ]
      interfaces = [
        {
          channel = "channel_vpc1"
          vlan    = "1"
          side_a = {
            ip                     = "19.5.2.18/24"
            secondary_ip_addresses = ["19.2.2.18/24", "19.3.2.18/24", "19.4.2.18/24"]
          }
          side_b = {
            ip                     = "19.5.2.19/24"
            secondary_ip_addresses = ["19.2.2.19/24", "19.3.2.19/24", "19.4.2.19/24"]
          }
        },
        {
          channel = "channel_vpc2"
          vlan    = "5"
          side_a = {
            ipv6                     = "2000:db1:a::17/64"
            link_local_address       = "fe80::25"
            secondary_ipv6_addresses = ["2001:db1:a::19/64"]
          }
          side_b = {
            ipv6                     = "2000:db1:a::18/64"
            link_local_address       = "fe80::26"
            secondary_ipv6_addresses = ["2001:db1:a::20/64"]
          }
        },
        {
          channel = "channel_vpc3"
          vlan    = "4"
          side_a = {
            ip                     = "19.7.2.18/24"
            secondary_ip_addresses = ["19.2.3.18/24", "19.3.4.18/24", "19.4.5.18/24"]
          }
          side_b = {
            ip                     = "19.7.2.19/24"
            secondary_ip_addresses = ["19.2.3.19/24", "19.3.4.19/24", "19.4.5.19/24"]
          }
        },
      ]
      static_routes = [
        {
          prefix              = "10.0.0.4/24"
          fallback_preference = "1"
          route_control       = true
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.10"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.12"
              next_hop_profile_type = "prefix"
            }
          ]
        }
      ]
    },
    {
      pod_id = 1
      nodes = [
        {
          node_id            = "153"
          router_id          = "1.1.3.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.33.101"
        },
        {
          node_id            = "154"
          router_id          = "1.1.4.101"
          router_id_loopback = "yes"
          loopback_address   = "172.16.34.103"
        },
      ]
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy2.id
        authentication_key_id = "5"
      }
      interfaces = [
        {
          channel = "channel_vpc4"
          vlan    = "3"
          side_a = {
            ip                       = "20.5.2.25/24"
            ipv6                     = "2000:db2:a::35/64"
            link_local_address       = "fe80::28"
            secondary_ip_addresses   = ["20.4.3.20/24", "20.4.4.20/24"]
            secondary_ipv6_addresses = ["2001:db2:a::17/64", "2001:db2:a::18/64", "2001:db2:a::19/64"]
          }
          side_b = {
            ip                       = "20.5.2.26/24"
            ipv6                     = "2000:db2:a::36/64"
            link_local_address       = "fe80::29"
            secondary_ip_addresses   = ["20.4.3.21/24", "20.4.4.21/24"]
            secondary_ipv6_addresses = ["2001:db2:a::20/64", "2001:db2:a::21/64", "2001:db2:a::22/64"]
          }
        },
        {
          channel = "channel_vpc5"
          vlan    = "6"
          side_a = {
            ip                       = "20.8.2.25/24"
            ipv6                     = "2001:db2:a::35/64"
            link_local_address       = "fe80::32"
            secondary_ip_addresses   = ["20.8.3.20/24", "20.8.4.20/24"]
            secondary_ipv6_addresses = ["2001:db2:a::23/64", "2001:db2:a::24/64", "2001:db2:a::25/64"]
          }
          side_b = {
            ip                       = "20.8.2.26/24"
            ipv6                     = "2001:db2:a::36/64"
            link_local_address       = "fe80::33"
            secondary_ip_addresses   = ["20.8.3.21/24", "20.8.4.21/24"]
            secondary_ipv6_addresses = ["2001:db2:a::26/64", "2001:db2:a::27/64", "2001:db2:a::28/64"]
          }
        }
      ]
      static_routes = [
        {
          prefix              = "10.1.1.3/24"
          fallback_preference = "3"
          route_control       = true
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.10"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.12"
              next_hop_profile_type = "prefix"
            }
          ]
        },
        {
          prefix              = "10.1.1.2/24"
          fallback_preference = "4"
          route_control       = false
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.9"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.12"
              next_hop_profile_type = "prefix"
            },
          ]
        },
      ]
    },
    {
      pod_id = 4
      nodes = [
        {
          node_id            = "155"
          router_id          = "1.1.9.101"
          router_id_loopback = "no"
        },
        {
          node_id   = "156"
          router_id = "1.1.10.101"
        },
      ]
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy3.id
        authentication_key_id = "9"
      }
      interfaces = [
        {
          channel = "channel_vpc6"
          vlan    = "7"
          side_a = {
            ip                       = "20.7.2.20/24"
            ipv6                     = "2000:db3:a::15/64"
            link_local_address       = "fe80::30"
            secondary_ip_addresses   = ["20.6.3.20/24", "20.6.4.20/24"]
            secondary_ipv6_addresses = ["2001:db3:a::17/64"]
          }
          side_b = {
            ip                       = "20.7.2.21/24"
            ipv6                     = "2000:db3:a::16/64"
            link_local_address       = "fe80::31"
            secondary_ip_addresses   = ["20.6.3.21/24", "20.6.4.21/24"]
            secondary_ipv6_addresses = ["2001:db3:a::21/64"]
          }
        },
        {
          channel = "channel_vpc7"
          vlan    = "8"
          side_a = {
            ip                       = "20.9.2.20/24"
            ipv6                     = "2000:db4:a::15/64"
            link_local_address       = "fe80::34"
            secondary_ip_addresses   = ["20.9.3.20/24", "20.9.4.20/24"]
            secondary_ipv6_addresses = ["2001:db4:a::17/64"]
          }
          side_b = {
            ip                       = "20.9.2.21/24"
            ipv6                     = "2000:db4:a::16/64"
            link_local_address       = "fe80::35"
            secondary_ip_addresses   = ["20.9.3.21/24", "20.9.4.21/24"]
            secondary_ipv6_addresses = ["2001:db4:a::21/64"]
          }
        }
      ]
    }
  ]
}

