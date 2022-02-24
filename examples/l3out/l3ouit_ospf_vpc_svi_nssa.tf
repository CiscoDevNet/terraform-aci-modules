
module "ospf03_l3out" {
  source = "./.."

  name        = "ospf03_l3out"
  alias       = ""
  description = "L3Out-OSPF-VPC-svi-nssa"
  tenant_dn   = aci_tenant.test.id
  vrf_dn      = aci_vrf.test.id
  l3dom_dn    = data.aci_l3_domain_profile.core.id

  ospf = {
    enabled   = true
    area_id   = "0.0.0.8"
    area_type = "nssa"
    area_cost = "1"
    # area_ctrl ommited, takes default value
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
    "vpc_core" = {
      l2_port_type     = "vpc"
      l3_port_type     = "ext-svi"
      pod_id           = "1"
      node_a_id        = "1101"
      node_b_id        = "1102"
      interface_id     = "vpc_core"
      ip_addr_a        = "172.16.38.101/24"
      ip_addr_b        = "172.16.38.102/24"
      vlan_encap       = "vlan-38"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"
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
