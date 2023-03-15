terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = "admin"
  password = "LionelIsAwesome!123"
  url      = "https://173.36.219.70"
  insecure = true
}

module "l3out" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_dynamic_l3out"
  alias       = "dynamic_l3out"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  bgp = {
    alias = "bgp"
  }

  floating_svi = {
    domain_dn        = aci_physical_domain.physical_domain.id
    floating_ip      = "19.1.2.1/24"
    floating_ipv6    = "2001:db1:a::15/64"
    vlan             = "5"
    forged_transmit  = false
    mac_change       = false
    promiscuous_mode = false
    anchor_nodes = [
      {
        pod_id     = "1"
        node_id    = "110"
        ip_address = "19.1.1.18/24"
        vlan       = "1"
      },
      {
        pod_id     = "1"
        node_id    = "111"
        ip_address = "19.1.1.20/24"
        vlan       = "1"
      },
      {
        pod_id       = "1"
        node_id      = "112"
        ipv6_address = "2001:db1:a::16/64"
        vlan         = "1"
      },
      {
        pod_id       = "1"
        node_id      = "113"
        ipv6_address = "2001:db1:a::17/64"
        vlan         = "1"
      },
    ]
  }

  bgp_peers = [
        {
          # loopback_as_source = true
          ip_address          = "10.1.1.11"
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
        {
          # loopback_as_source = true
          ip_address          = "10.1.1.12"
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
        {
          //loopback_as_source = false
          ip_address          = "10.1.1.13"
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
            }
          ]
        },
        {
          //loopback_as_source = false
          ipv6_address          = "2001:db1:a::9/64"
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
            }
          ]
        },
      ]

  nodes = [
    {
      node_id          = "101"
      pod_id           = "1"
      router_id        = "102.102.102.102"
      loopback_address = "172.16.31.101"
      static_routes = [
        {
          prefix              = "11.0.0.3/12"
          fallback_preference = "1"
          route_control       = true
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.9"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.20"
              next_hop_profile_type = "prefix"
            },
          ]
        },
        {
          prefix              = "12.0.0.2/12"
          fallback_preference = "3"
          route_control       = false
          next_hop_addresses = [
            {
              next_hop_ip           = "172.16.31.9"
              next_hop_profile_type = "prefix"
            },
            {
              next_hop_ip           = "172.16.31.21"
              next_hop_profile_type = "prefix"
            },
          ]
        }
      ]
      //bgp_peers = [push to node as default...or all interfaces in this node]
      interfaces = [
        {
          port = "1/11"
          ip   = "14.14.15.1/24"
          ipv6 = "2001:db8:e::2/64"
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
        },
        {
          port = "1/13"
          ip   = "14.1.1.2/24"
          ipv6 = "2001:db8:b::2/64"
          vlan = "2"
        },
        {
          port = "1/12"
          ip   = "10.1.1.49/24"
          ipv6 = "2001:db8:c::2/64"
          vlan = "4"
          svi  = true
        },
        {
          channel = "channel-one"
          ip      = "14.14.14.1/24"
        },
        {
          channel = "channel-two"
          ip      = "14.1.16.2/24"
          vlan    = "2"

        },
        {
          channel = "channel-three"
          ip      = "172.16.103.3/24"
          vlan    = "2"
          svi     = true
        },
        {
          channel = "channel-six"
          ipv6    = "2001:db8:a::2/64"
          bgp_peers = [
            {
              ipv6_address        = "2001:db7:a::2/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              bgp_controls = {
                as_override = true
              }
              peer_controls      = ["bfd"]
              private_as_control = ["remove-all", "remove-exclusive"]
              admin_state        = "enabled"
            },
          ]
        },
      ]
    },
    {
      node_id          = "102"
      pod_id           = "1"
      router_id        = "103.103.103.103"
      loopback_address = "172.16.31.102"
      interfaces = [
        {
          port = "1/11"
          ip   = "14.14.16.1/24"
          ipv6 = "2001:db8:d::2/64"
        },
        {
          channel = "channel-one"
          ip      = "14.14.17.1/24"
        },
      ]
    },
    {
      node_id          = "103"
      pod_id           = "1"
      router_id        = "104.104.104.104"
      loopback_address = "172.16.31.103"
      bgp_peers = [
        {
          loopback_as_source  = false
          ip_address          = "10.1.1.39"
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
        # {
        #   loopback_as_source = false
        #   ip_address          = "2001:db6:a::2/64"
        #   address_control     = ["af-mcast", "af-ucast"]
        #   allowed_self_as_cnt = "1"
        #   bgp_controls = {
        #     send_com = true
        #   }
        #   peer_controls      = ["bfd"]
        #   private_as_control = ["remove-all", "remove-exclusive"]
        #   admin_state        = "enabled"
        #   route_control_profiles = [
        #     {
        #       direction = "export"
        #       target_dn = aci_route_control_profile.profile2.id
        #     }
        #   ]
        # },
      ]
      interfaces = [
        {
          channel = "channel-one"
          ip      = "14.14.18.1/24"
        },
      ]
    },
    {
      node_id          = "104"
      pod_id           = "1"
      router_id        = "105.105.105.105"
      loopback_address = "172.16.31.104"
      static_routes = [
        {
          prefix              = "10.0.0.6/12"
          fallback_preference = "1"
          route_control       = true
        },
      ]
      interfaces = [
        {
          port = "1/11"
          ip   = "14.14.19.1/24"
          ipv6 = "2001:db8:f::2/64"
        },
      ]
    },
    {
      node_id          = "105"
      pod_id           = "1"
      router_id        = "106.106.106.106"
      loopback_address = "172.16.31.105"
      interfaces = [
        {
          port = "1/11"
          ip   = "14.14.20.1/24"
          ipv6 = "2001:db9:a::2/64"
          bgp_peers = [
            {
              ip_address          = "10.1.1.26"
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
                }
              ]
            },
            {
              ipv6_address        = "2001:db7:a::3/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
            },
          ]
        },
      ]
    },
    {
      node_id          = "106"
      pod_id           = "1"
      router_id        = "107.107.107.107"
      loopback_address = "172.16.31.106"
      bgp_peers = [
        {
          # loopback_as_source = true
          ip_address          = "10.1.1.35"
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
        {
          # loopback_as_source = true
          ip_address          = "10.1.1.36"
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
            }
          ]
        },
        {
          loopback_as_source  = false
          ipv6_address        = "2001:db2:a::3/64"
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
            }
          ]
        },
      ]
      interfaces = [
        {
          port = "1/11"
          ip   = "14.14.21.1/24"
          ipv6 = "2001:db9:b::2/64"
          bgp_peers = [
            {
              ip_address          = "10.1.1.87"
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
              ipv6_address        = "2001:db5:b::3/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
            },
          ]
        },
        {
          channel = "channel-seven"
          ip      = "14.14.22.1/24"
          bgp_peers = [
            {
              ip_address          = "10.1.1.90"
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
        },
      ]
    },
    {
      node_id          = "107"
      pod_id           = "1"
      router_id        = "108.108.108.108"
      loopback_address = "172.16.31.107"
      interfaces = [
        {
          channel = "channel-eight"
          ipv6    = "2001:db8:e::5/64"
        },
      ]
    },
    {
      node_id          = "108"
      pod_id           = "1"
      router_id        = "109.109.109.109"
      loopback_address = "172.16.31.108"
      static_routes = [
        {
          prefix              = "10.0.0.3/12"
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
        },
        {
          prefix              = "10.0.0.2/12"
          fallback_preference = "2"
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
      interfaces = [
        {
          port = "1/15"
          ip   = "14.14.15.5/24"
          ipv6 = "2001:db8:e::3/64"
          bgp_peers = [
            {
              ip_address          = "10.1.1.27"
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
              ipv6_address        = "2001:db7:e::3/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
            },
          ]
        },
        {
          port = "1/16"
          ip   = "14.1.1.3/24"
          ipv6 = "2001:db8:b::3/64"
          vlan = "2"
        },
        {
          port = "1/17"
          ip   = "10.1.1.59/24"
          ipv6 = "2001:db8:c::3/64"
          vlan = "4"
          svi  = true
        },
        {
          channel = "channel-one"
          ip      = "14.14.14.2/24"
        },
        {
          channel = "channel-two"
          ip      = "14.1.16.3/24"
          vlan    = "2"

        },
        {
          channel = "channel-three"
          ip      = "172.16.103.4/24"
          vlan    = "2"
          svi     = true
        },
        {
          channel = "channel-six"
          ipv6    = "2001:db8:a::3/64"
        },
      ]
    },
    {
      node_id          = "109"
      pod_id           = "1"
      router_id        = "110.110.110.110"
      loopback_address = "172.16.31.109"
      bgp_peers = [
        {
          loopback_as_source  = false
          ip_address          = "10.1.1.51"
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
            }
          ]
        },
        {
          loopback_as_source  = false
          ipv6_address        = "2001:db1:a::3/64"
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
            }
          ]
        },
      ]
      interfaces = [
        {
          port = "1/18"
          ip   = "10.1.1.18/24"
          ipv6 = "2001:db9:c::9/64"
          vlan = "4"
          svi  = true
        },
        {
          port = "1/19"
          ip   = "10.1.1.18/24"
          ipv6 = "2001:db9:c::9/64"
          vlan = "4"
          svi  = true
        },
      ]
    }
  ]
}

# output "module"{
#   value = module.l3out.debug
# }       