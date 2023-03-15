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
  name        = "module_dynamic_l3out_svi"
  alias       = "dynamic_l3out"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  bgp = {
    alias = "bgp"
  }

  bgp_peers = [
    {
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
      loopback_as_source  = false
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
      loopback_as_source  = false
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
    },
    {
      node_id          = "102"
      pod_id           = "1"
      router_id        = "111.111.111.111"
      loopback_address = "172.16.31.119"
      interfaces = [
        {
          port = "1/20"
          ip   = "10.1.1.19/24"
          ipv6 = "2001:db9:a::9/64"
          vlan = "2"
          svi  = true
        },
        {
          port = "1/21"
          ip   = "10.1.1.19/24"
          ipv6 = "2001:db9:a::9/64"
          vlan = "2"
          svi  = true
        },
      ]
    }
  ]
}
     