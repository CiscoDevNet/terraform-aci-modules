# terraform-aci-l3out

This module creates a L3Out with all the objects included in it, using a similar set of configuration options as the ones available in the l3out wizard available in the UI

* Supported protocols are OSPF, BGP and static.
* Supported L2 interface types are "port", "pc" and "vpc"
* Supported L3 interface types are "l3-port", "sub-interface" and "ext-svi"
* BGP peers can be defined either at interface level or node profile level (local interface used is loopback)

:warning: **This module uses experimental features:** module_variable_optional_attrs

## Usage

### Example for L3Out using OSPF

```hcl
module "l3out" {
  source   = "github.com/adealdag/terraform-aci-l3out"

  name        = "core_l3out"
  alias       = ""
  description = "L3Out to core network"
  tenant_dn   = aci_tenant.prod.id
  vrf_dn      = aci_vrf.prod.id
  l3dom_dn    = aci_l3_domain_profile.core.id

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
      ip_addr_a        = "172.16.21.10/30"
      vlan_encap       = "vlan-21"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"

      ospf_interface_policy_dn = aci_ospf_interface_policy.ospf_p2p.id
    },
    "1102_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1102"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.21.14/30"
      vlan_encap       = "vlan-21"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"

      ospf_interface_policy_dn = aci_ospf_interface_policy.ospf_p2p.id
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
```

### Example for L3Out using BGP and loopbacks as source interface

```hcl
module "l3out" {
  source   = "github.com/adealdag/terraform-aci-l3out"

  name        = "core_l3out"
  alias       = ""
  description = "L3Out to core network"
  tenant_dn   = aci_tenant.prod.id
  vrf_dn      = aci_vrf.prod.id
  l3dom_dn    = data.aci_l3_domain_profile.core.id

  bgp = {
    enabled   = true
    bgp_peers = {
      "key" = {
        peer_ip_addr          = "172.16.22.1"
        peer_asn              = "65022"
        addr_family_ctrl      = "af-ucast"
        bgp_ctrl              = "send-com,send-ext-com"
        peer_ctrl             = "dis-conn-check"
        # Remaining attributes will use the default values
      }
    }
  }

  nodes = {
    "1101" = {
      pod_id             = "1"
      node_id            = "1101"
      router_id          = "1.1.1.101"
      router_id_loopback = "no"
      loopbacks = ["172.16.22.101"]
      static_routes = {
        "bgp_peer" = {
          prefix = "172.16.22.1/32"
          next_hops = ["172.16.22.9"]
        }
      }
    },
    "1102" = {
      pod_id             = "1"
      node_id            = "1102"
      router_id          = "1.1.1.102"
      router_id_loopback = "no"
      loopbacks = ["172.16.22.102"]
      static_routes = {
        "bgp_peer" = {
          prefix = "172.16.22.1/32"
          next_hops = ["172.16.22.13"]
        }
      }
    }
  }

  interfaces = {
    "1101_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1101"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.22.10/30"
      vlan_encap       = "vlan-22"
      vlan_encap_scope = "local"
      mode             = "regular"
      mtu              = "9216"
    },
    "1102_1_25" = {
      l2_port_type     = "port"
      l3_port_type     = "sub-interface"
      pod_id           = "1"
      node_a_id        = "1102"
      interface_id     = "eth1/25"
      ip_addr_a        = "172.16.22.14/30"
      vlan_encap       = "vlan-22"
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
```