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
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_dynamic_l3out"
  alias       = "dynamic_l3out"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  bgp = {
    alias = "bgp"
  }

  vpcs = [
    {
      pod_id = 1
      nodes = [
        {
          node_id            = "121"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.32.101"
        },
        {
          node_id            = "122"
          router_id          = "1.1.2.101"
          router_id_loopback = "yes"
        },
      ]
      interfaces = [
        {
          channel = "channel_vpc1"
          vlan    = "1"
          side_a = {
            ip                     = "19.1.2.18/24"
            secondary_ip_addresses = ["19.2.2.18/24", "19.3.2.18/24", "19.4.2.18/24"]
          }
          side_b = {
            ip                     = "19.1.2.19/24"
            secondary_ip_addresses = ["19.2.2.19/24", "19.3.2.19/24", "19.4.2.19/24"]
          }
          bgp_peers = [
            {
              ip_address          = "10.2.2.27"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              bgp_controls = {
                as_override = true
              }
              peer_controls      = ["bfd"]
              private_as_control = ["remove-all", "remove-exclusive"]
              admin_state        = "enabled"
            }
          ]
        },
        {
          channel = "channel_vpc6"
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
          bgp_peers = [
            {
              ipv6_address        = "2000:db1:a::25/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
            }
          ]
        }
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
      bgp_peers = [
        {
          #loopback_as_source  = false
          ip_address          = "10.1.1.40"
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
          loopback_as_source  = false
          ip_address          = "10.1.1.41"
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
          ipv6_address        = "2000:db1:a::30/64"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "6"
          peer_controls       = ["bfd"]
          private_as_control  = ["remove-all", "remove-exclusive"]
          admin_state         = "disabled"
        },
      ]
    },
    {
      pod_id = 1
      nodes = [
        {
          node_id            = "123"
          router_id          = "1.1.3.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.33.101"
        },
        {
          node_id            = "124"
          router_id          = "1.1.4.101"
          router_id_loopback = "yes"
          loopback_address   = "172.16.34.103"
        },
      ]
      interfaces = [
        {
          channel = "channel_vpc2"
          vlan    = "2"
          side_a = {
            ip                     = "19.4.2.20/24"
            secondary_ip_addresses = ["19.4.3.20/24", "19.4.4.20/24", "19.4.5.20/24"]
          }
          side_b = {
            ip                     = "19.4.2.21/24"
            secondary_ip_addresses = ["19.4.3.21/24", "19.4.4.21/24", "19.4.5.21/24"]
          }
        },
        {
          channel = "channel_vpc3"
          vlan    = "2"
          side_a = {
            ip                 = "19.4.2.20/24"
            ipv6               = "2000:db1:a::15/64"
            link_local_address = "fe80::23"
          }
          side_b = {
            ip                 = "19.4.2.21/24"
            ipv6               = "2000:db1:a::16/64"
            link_local_address = "fe80::24"
          }
          bgp_peers = [
            {
              ip_address          = "10.2.2.29"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "2"
              bgp_controls = {
                as_override = true
              }
              peer_controls      = ["bfd"]
              private_as_control = ["remove-all", "remove-exclusive"]
              admin_state        = "enabled"
              route_control_profiles = [
                {
                  direction = "export"
                  target_dn = aci_route_control_profile.profile1.id
                }
              ]
            },
            {
              ipv6_address        = "2000:db1:a::26/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "2"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
            },
            {
              ipv6_address        = "2000:db1:a::27/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "2"
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
          ]
        }
      ]
      static_routes = [
        {
          prefix              = "10.2.1.3/24"
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
          prefix              = "10.2.1.2/24"
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
      bgp_peers = [
        {
          #loopback_as_source  = false
          ip_address          = "10.1.1.50"
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
              direction = "import"
              target_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
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
          #loopback_as_source  = false
          ipv6_address        = "2000:db1:a::50/64"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "6"
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
          loopback_as_source  = false
          ip_address          = "10.1.1.52"
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
          ipv6_address        = "2000:db1:a::51/64"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "6"
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
      ]
    },
    {
      pod_id = 2
      nodes = [
        {
          node_id            = "128"
          router_id          = "1.1.7.101"
          router_id_loopback = "no"
        },
        {
          node_id   = "129"
          router_id = "1.1.8.101"
        },

      ]
      interfaces = [
        {
          channel = "channel_vpc7"
          vlan    = "3"
          side_a = {
            ip                       = "20.4.2.20/24"
            ipv6                     = "2000:db2:a::15/64"
            link_local_address       = "fe80::28"
            secondary_ip_addresses   = ["20.4.3.20/24", "20.4.4.20/24"]
            secondary_ipv6_addresses = ["2001:db2:a::17/64", "2001:db2:a::18/64", "2001:db2:a::19/64"]
          }
          side_b = {
            ip                       = "20.4.2.21/24"
            ipv6                     = "2000:db2:a::16/64"
            link_local_address       = "fe80::29"
            secondary_ip_addresses   = ["20.4.3.21/24", "20.4.4.21/24"]
            secondary_ipv6_addresses = ["2001:db2:a::20/64", "2001:db2:a::21/64", "2001:db2:a::22/64"]
          }
          bgp_peers = [
            {
              ipv6_address        = "2000:db2:a::25/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "5"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
              route_control_profiles = [
                {
                  direction = "export"
                  target_dn = aci_route_control_profile.profile2.id
                }
              ]
            }
          ]
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
      bgp_peers = [
        {
          #loopback_as_source  = false
          ip_address          = "10.1.1.42"
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
              direction = "import"
              target_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
        {
          loopback_as_source  = false
          ip_address          = "10.1.1.43"
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
          ipv6_address        = "2000:db1:a::31/64"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "6"
          peer_controls       = ["bfd"]
          private_as_control  = ["remove-all", "remove-exclusive"]
          admin_state         = "disabled"
        },
      ]
    },
    {
      pod_id = 4
      nodes = [
        {
          node_id            = "131"
          router_id          = "1.1.9.101"
          router_id_loopback = "no"
        },
        {
          node_id   = "132"
          router_id = "1.1.10.101"
        },

      ]
      interfaces = [
        {
          channel = "channel_vpc9"
          vlan    = "5"
          side_a = {
            ip                       = "20.6.2.20/24"
            ipv6                     = "2000:db3:a::15/64"
            link_local_address       = "fe80::28"
            secondary_ip_addresses   = ["20.6.3.20/24", "20.6.4.20/24"]
            secondary_ipv6_addresses = ["2001:db3:a::17/64"]
          }
          side_b = {
            ip                       = "20.6.2.21/24"
            ipv6                     = "2000:db3:a::16/64"
            link_local_address       = "fe80::29"
            secondary_ip_addresses   = ["20.6.3.21/24", "20.6.4.21/24"]
            secondary_ipv6_addresses = ["2001:db3:a::21/64"]
          }
          bgp_peers = [
            {
              ipv6_address        = "2000:db2:a::29/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "5"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
              route_control_profiles = [
                {
                  direction = "export"
                  target_dn = aci_route_control_profile.profile2.id
                }
              ]
            }
          ]
        }
      ]
      static_routes = [
        {
          prefix              = "10.1.1.6/24"
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
          prefix              = "10.1.1.7/24"
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
      bgp_peers = [
        {
          #loopback_as_source  = false
          ip_address          = "10.1.1.49"
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
              direction = "import"
              target_dn = aci_route_control_profile.profile1.id
            }
          ]
        },
        {
          loopback_as_source  = false
          ip_address          = "10.1.1.56"
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
          ipv6_address        = "2000:db1:a::33/64"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "6"
          peer_controls       = ["bfd"]
          private_as_control  = ["remove-all", "remove-exclusive"]
          admin_state         = "disabled"
        },
      ]
    }
  ]

  floating_svi = {
    domain_dn                         = aci_physical_domain.physical_domain.id
    floating_ip                       = "19.1.2.1/24"
    floating_ipv6                     = "2001:db1:a::15/64"
    floating_secondary_ip_addresses   = ["19.1.23.1/24", "19.1.23.2/24", "19.1.23.3/24"]
    floating_secondary_ipv6_addresses = ["2001:db2:a::15/64", "2001:db3:a::15/64", "2001:db4:a::15/64"]
    vlan                              = "5"
    anchor_nodes = [
      {
        pod_id                 = "1"
        node_id                = "110"
        ip_address             = "19.1.1.18/24"
        secondary_ip_addresses = ["19.2.1.18/24", "19.3.1.18/24", "19.4.1.18/24"]
        vlan                   = "1"
        autostate              = "disabled"
        encap_scope            = "local"
        mode                   = "regular"
        mtu                    = "inherit"
        target_dscp            = "EF"
        bgp_peers = [
          {
            ip_address          = "19.2.1.18"
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
            ip_address          = "19.3.1.18"
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
      },
      {
        pod_id     = "1"
        node_id    = "111"
        ip_address = "19.1.1.20/24"
        vlan       = "1"
      },
      {
        pod_id             = "1"
        node_id            = "112"
        ipv6_address       = "2001:db1:a::16/64"
        link_local_address = "fe80::19"
        vlan               = "1"
      },
      {
        pod_id             = "1"
        node_id            = "113"
        ipv6_address       = "2001:db1:a::17/64"
        link_local_address = "fe80::20"
        vlan               = "1"
      },
      {
        pod_id                   = "1"
        node_id                  = "114"
        ip_address               = "19.1.1.21/24"
        ipv6_address             = "2001:db1:a::18/64"
        secondary_ip_addresses   = ["19.2.1.21/24", "19.3.1.21/24", "19.4.1.21/24"]
        secondary_ipv6_addresses = ["2001:db2:a::18/64", "2001:db3:a::18/64", "2001:db4:a::18/64"]
        vlan                     = "1"
        bgp_peers = [
          {
            ipv6_address        = "2001:db1:a::24/64"
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
        pod_id                   = "1"
        node_id                  = "115"
        ip_address               = "19.1.1.22/24"
        ipv6_address             = "2001:db1:a::19/64"
        secondary_ipv6_addresses = ["2001:db2:a::19/64", "2001:db3:a::19/64", "2001:db4:a::19/64"]
        link_local_address       = "fe80::21"
        vlan                     = "5"
        bgp_peers = [
          {
            ip_address          = "19.2.1.21"
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
            ipv6_address        = "2001:db1:a::25/64"
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
            ip_address          = "19.3.1.21"
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
      ipv6_address        = "2001:db1:a::9/64"
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
      interfaces = [
        {
          port                     = "1/11"
          ip                       = "14.14.15.1/24"
          ipv6                     = "2001:db8:e::2/64"
          secondary_ip_addresses   = ["14.15.15.1/24", "14.16.15.1/24", "14.17.15.1/24"]
          secondary_ipv6_addresses = ["2001:db8:e::3/64", "2001:db8:e::4/64", "2001:db8:e::5/64"]
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
          channel                = "channel-one"
          ip                     = "14.14.14.1/24"
          secondary_ip_addresses = ["14.15.14.1/24", "14.16.14.1/24", "14.17.14.1/24"]
        },
        {
          channel                = "channel-two"
          ip                     = "14.1.16.2/24"
          secondary_ip_addresses = ["14.2.16.2/24", "14.3.16.2/24", "14.4.16.2/24"]
          vlan                   = "2"

        },
        {
          channel                = "channel-three"
          ip                     = "172.16.103.3/24"
          secondary_ip_addresses = ["172.17.103.3/24", "172.18.103.3/24", "172.19.103.3/24"]
          vlan                   = "2"
          svi                    = true
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
          port                     = "1/11"
          ip                       = "14.14.21.1/24"
          ipv6                     = "2001:db9:b::2/64"
          secondary_ip_addresses   = ["14.15.21.1/24", "14.16.21.1/24", "14.17.21.1/24"]
          secondary_ipv6_addresses = ["2001:db9:b::3/64", "2001:db9:b::4/64", "2001:db9:b::5/64"]
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
          channel                  = "channel-six"
          ipv6                     = "2001:db8:a::3/64"
          secondary_ipv6_addresses = ["2001:db8:a::4/64", "2001:db8:a::5/64", "2001:db8:a::6/64"]
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
      