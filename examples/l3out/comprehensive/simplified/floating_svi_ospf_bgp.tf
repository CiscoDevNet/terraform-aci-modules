// Test file for floating svi with bgp and ospf
module "bgp_floating_svi" {
  source      = "../../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_floating_svi_virtual_bgp"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf4.id

  bgp = true

  floating_svi = {
    domain_dn        = aci_vmm_domain.virtual_domain.id
    floating_ip      = "19.1.2.1/24"
    floating_ipv6    = "2001:db1:a::15/64"
    vlan             = "4"
    forged_transmit  = false
    mac_change       = false
    promiscuous_mode = true
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
      {
        pod_id       = "1"
        node_id      = "114"
        ip_address   = "19.1.1.21/24"
        ipv6_address = "2001:db1:a::18/64"
        vlan         = "1"
      },
      {
        pod_id       = "1"
        node_id      = "115"
        ip_address   = "19.1.1.22/24"
        ipv6_address = "2001:db1:a::19/64"
        vlan         = "5"
      },
    ]
  }
}

module "ospf_floating_svi" {
  source      = "../../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_floating_svi_virtual_ospf"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf5.id

  ospf = {
    area_cost = "1"
    area_ctrl = ["redistribute"]
    area_id   = "3"
    area_type = "regular"
  }

  floating_svi = {
    domain_dn        = aci_vmm_domain.virtual_domain.id
    floating_ip      = "19.1.2.2/24"
    floating_ipv6    = "2001:db1:a::16/64"
    vlan             = "4"
    forged_transmit  = false
    mac_change       = false
    promiscuous_mode = true
    ospf_interface_profile = {
      ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
      authentication_key_id = "1"
    }
    anchor_nodes = [
      {
        pod_id       = "1"
        node_id      = "114"
        ip_address   = "19.1.1.23/24"
        ipv6_address = "2001:db1:a::20/64"
        vlan         = "2"
      },
      {
        pod_id       = "1"
        node_id      = "115"
        ip_address   = "19.1.1.24/24"
        ipv6_address = "2001:db1:a::21/64"
        vlan         = "2"
      },
    ]
  }
}