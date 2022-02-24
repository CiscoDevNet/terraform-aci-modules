module "ospf01_l3out" {
  source = "./.."

  name        = "ospf01_l3out"
  alias       = ""
  description = "L3Out-OSPF-Port-Subif-regular"
  tenant_dn   = aci_tenant.test.id
  vrf_dn      = aci_vrf.test.id
  l3dom_dn    = data.aci_l3_domain_profile.core.id

  ospf = {
    enabled   = true
    area_id   = "0.0.0.1"
    area_type = "regular"
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
    "1101_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1101"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.36.10/30"
      vlan_encap       = "vlan-36"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"

      ospf_interface_policy_dn = aci_ospf_interface_policy.ospf_pol.id
    },
    "1102_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1102"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.36.14/30"
      vlan_encap       = "vlan-36"
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
