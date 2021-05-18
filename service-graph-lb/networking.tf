# Define an ACI VRF Resource.
resource "aci_vrf" "this" {
    tenant_dn   = aci_tenant.this.id
    name        = var.vrf.name
    description = var.vrf.description
}

# Define the provider ACI BD Resource.
resource "aci_bridge_domain" "provider_bd" {
    tenant_dn          = aci_tenant.this.id
    relation_fv_rs_ctx = aci_vrf.this.id
    name               = var.provider_bd.name
    description        = var.provider_bd.description
    multi_dst_pkt_act  = var.consumer_bd.multi_dst_pkt_act
}

# Define the provider ACI BD Subnet Resource.
resource "aci_subnet" "provider_bd_subnet" {
    for_each    = var.provider_bd_subnets
    parent_dn   = aci_bridge_domain.provider_bd.id
    description = each.value.description
    ip          = each.value.subnet
}

# Define the consumer ACI BD Resource.
resource "aci_bridge_domain" "consumer_bd" {
    tenant_dn          = aci_tenant.this.id
    relation_fv_rs_ctx = aci_vrf.this.id
    name               = var.consumer_bd.name
    description        = var.consumer_bd.description
    multi_dst_pkt_act  = var.consumer_bd.multi_dst_pkt_act
}

# Define the consumer ACI BD Subnet Resource.
resource "aci_subnet" "consumer_bd_subnet" {
    for_each    = var.consumer_bd_subnets
    parent_dn   = aci_bridge_domain.consumer_bd.id
    description = each.value.description
    ip          = each.value.subnet
}
