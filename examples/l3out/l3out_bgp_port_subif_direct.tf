module "bgp02_l3out" {
  source = "./.."

  name        = "bgp02_l3out"
  alias       = ""
  description = "L3Out-BGP-Port-Subif-direct"
  tenant_dn   = aci_tenant.test.id
  vrf_dn      = aci_vrf.test.id
  l3dom_dn    = data.aci_l3_domain_profile.core.id

  bgp = {
    enabled = true
  }

  nodes = {
    "1101" = {
      pod_id             = "1"
      node_id            = "1101"
      router_id          = "1.1.1.101"
      router_id_loopback = "no"
    },
    "1102" = {
      pod_id             = "1"
      node_id            = "1102"
      router_id          = "1.1.1.102"
      router_id_loopback = "no"
    }
  }

  interfaces = {
    "1101_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1101"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.32.10/30"
      vlan_encap       = "vlan-32"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"

      bgp_peers = {
        "core01" = {
          peer_ip_addr     = "172.16.32.9"
          peer_asn         = "65032"
          addr_family_ctrl = "af-ucast"
          bgp_ctrl         = "send-com,send-ext-com"
          # Remaining attributes will use the default values
        }
      }
    },
    "1102_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1102"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.32.14/30"
      vlan_encap       = "vlan-32"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"

      bgp_peers = {
        "core01" = {
          peer_ip_addr     = "172.16.32.13"
          peer_asn         = "65032"
          addr_family_ctrl = "af-ucast"
          bgp_ctrl         = "send-com,send-ext-com"
          # Remaining attributes will use the default values
        }
      }
    }
  }

  external_l3epg = {
    "default" = {
      name         = "default"
      pref_gr_memb = "exclude"
      subnets = {
        "default" = {
          prefix = "0.0.0.0/0"
          scope  = ["import-security"]
        }
      }
    }
  }
}
