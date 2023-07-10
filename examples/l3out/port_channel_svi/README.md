<!-- BEGIN_TF_DOCS -->
## Routed Interface, Routed Sub-Interface, SVI
* The Routed Interface, Routed Sub-Interface and SVI for a particular node can be defined minimally as shown below.
  - To create a routed interface we define `port` with a value and to create a routed sub-interface we use `channel`.
  - To create a SVI we set `svi` to `true`.
  - IPv4 and IPv6 addresses can be defined in tandem for a port which will automatically create two logical interface profiles for the said port for each address family.

```hcl
nodes = [
  {
    node_id          = "101"
    pod_id           = "1"
    router_id        = "102.102.102.102"
    loopback_address = "172.16.31.101"
    interfaces = [
      {
        port = "1/13"
        ip   = "14.1.1.2/24"
        ipv6 = "2001:db8:b::2/64"
        vlan = "2"
      },
      {
        channel                = "channel-one"
        ip                     = "14.14.14.1/24"
        secondary_ip_addresses = ["14.15.14.1/24", "14.16.14.1/24", "14.17.14.1/24"]
        vlan                   = "3"
      },
      {
        port = "1/12"
        ip   = "10.1.1.49/24"
        ipv6 = "2001:db8:c::2/64"
        vlan = "4"
        svi  = true
      },
    ]
  }
]
```