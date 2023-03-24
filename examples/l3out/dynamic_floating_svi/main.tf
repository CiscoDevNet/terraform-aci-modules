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
  name        = "module_dynamic_l3out_floating_svi_virtual"
  alias       = "dynamic_l3out"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  bgp = {
    alias = "bgp"
  }

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
        pod_id     = "1"
        node_id    = "114"
        ip_address = "19.1.1.21/24"
        ipv6_address = "2001:db1:a::18/64"
        vlan       = "1"
      },
      {
        pod_id     = "1"
        node_id    = "115"
        ip_address = "19.1.1.22/24"
        ipv6_address = "2001:db1:a::19/64"
        vlan       = "5"
      },
    ]
  }
}