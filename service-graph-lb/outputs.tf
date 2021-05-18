output "external_vlan" {
    value = data.aci_rest.vlan_consumer.content.encap
    description = "The encap for the consumer/external arm"
}

output "internal_vlan" {
    value = data.aci_rest.vlan_provider.content.encap
    description = "The encap for the provider/internal arm"
}
