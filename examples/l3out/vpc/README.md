<!-- BEGIN_TF_DOCS -->
## VPC
* A VPC under SVI can be created by defining a vpcs block as shown below.
  - IPv4 and IPv6 addresses can be defined together for both Side A and Side B adresses which will automatically create logical interface profiles for each address family by associating themselves to the nodes defined in the vpcs block.

```hcl
vpcs = [
  {
    pod_id = 1
    nodes = [
      {
        node_id            = "121"
        router_id          = "1.1.1.101"
        router_id_loopback = "no"
        loopback_address   = "172.16.32.101"
      }
    ]
    interfaces = [
      {
        channel = "channel_vpc1"
        vlan    = "1"
        side_a = {
          ip                       = "19.1.2.18/24"
          ipv6                     = "2000:db2:a::15/64"
          secondary_ip_addresses   = ["19.1.2.17/24"]
          secondary_ipv6_addresses = ["2000:db2:a::17/64"]
        }
        side_b = {
          ip                       = "19.1.2.19/24"
          ipv6                     = "2000:db2:a::16/64"
          secondary_ip_addresses   = ["19.1.2.21/24"]
          secondary_ipv6_addresses = ["2000:db2:a::18/64"]
        }
      }
    ]
  }
] 
```
