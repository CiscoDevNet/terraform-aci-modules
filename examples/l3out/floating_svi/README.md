<!-- BEGIN_TF_DOCS -->
## Floating SVI
* Floating SVI can be minimally defined as shown below.
  - Floating SVI IPv4 and IPv6 addresses can be defined in tandem which will automatically create two floating svi logical interface profiles for each address family.
  - Multiple anchor nodes can be defined with IPv4 and IPv6 addresses in tandem where the anchor nodes having IPv4 address will automatically be created under the IPv4 floating svi logical interface profile and the ones with IPv6 will be created under the IPv6 logical interface profile.

```hcl
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
      pod_id       = "1"
      node_id      = "114"
      ip_address   = "19.1.1.21/24"
      ipv6_address = "2001:db1:a::18/64"
      vlan         = "1"
    }
  ]
}
```
