module "bgp03_l3out" {
  source = "./.."

  name        = "bgp03_l3out"
  alias       = ""
  description = "L3Out-BGP-PC-Routed-direct"
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
    }
  }

  interfaces = {
    "pc_core" = {
      l2_port_type = "pc"
      l3_port_type = "l3-port"
      pod_id       = "1"
      node_a_id    = "1101"
      interface_id = "pc_core"
      ip_addr_a    = "172.16.33.2/30"
      mtu          = "9216"

      bgp_peers = {
        "core01" = {
          peer_ip_addr     = "172.16.33.1"
          peer_asn         = "65033"
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
