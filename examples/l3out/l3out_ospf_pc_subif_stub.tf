module "ospf02_l3out" {
  source = "./.."

  name        = "ospf02_l3out"
  alias       = ""
  description = "L3Out-OSPF-PC-Subif-stub"
  tenant_dn   = aci_tenant.test.id
  vrf_dn      = aci_vrf.test.id
  l3dom_dn    = data.aci_l3_domain_profile.core.id

  ospf = {
    enabled   = true
    area_id   = "0.0.0.7"
    area_type = "stub"
    area_cost = "1"
    # area_ctrl ommited, takes default value
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
      l2_port_type     = "pc"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1101"
      interface_id     = "pc_core"
      ip_addr_a        = "172.16.37.2/30"
      vlan_encap       = "vlan-37"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"

      ospf_interface_policy_dn = aci_ospf_interface_policy.ospf_pol.id
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
