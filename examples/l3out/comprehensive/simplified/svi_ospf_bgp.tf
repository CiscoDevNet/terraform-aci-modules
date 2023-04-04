// Test file for svi with ospf and bgp enabled
module "l3out_svi_bgp" {
  source      = "../../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_svi_bgp"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf2.id

  bgp = true

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
          ip_address          = "10.1.1.55"
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

module "l3out_svi_ospf" {
  source      = "../../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_svi_ospf"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf3.id

  ospf = {
    area_cost = "1"
    area_ctrl = ["redistribute"]
    area_id   = "0"
    area_type = "regular"
  }

  ospf_interface_profile = {
    ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy2.id
    authentication_key_id = "5"
  }

  nodes = [
    {
      node_id          = "101"
      pod_id           = "1"
      router_id        = "110.110.110.110"
      loopback_address = "172.16.31.109"
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
        authentication_key_id = "1"
      }
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
     