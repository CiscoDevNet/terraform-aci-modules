# Define an ACI Filter Resource.
resource "aci_filter" "this" {
    for_each    = var.filters
    tenant_dn   = aci_tenant.this.id
    description = each.value.description
    name        = each.value.filter
}

# Define an ACI Filter Entry Resource.
resource "aci_filter_entry" "this" {
    for_each      = var.filters
    filter_dn     = aci_filter.this[each.key].id
    name          = each.value.entry
}

# Define an ACI Contract Resource.
resource "aci_contract" "this" {
    tenant_dn   = aci_tenant.this.id
    name        = var.contract.name
    description = var.contract.description
    scope       = var.contract.scope
}

# Define an ACI Contract Subject Resource.
resource "aci_contract_subject" "this" {
    for_each                      = var.filters
    contract_dn                   = aci_contract.this.id
    name                          = var.contract.subject
    relation_vz_rs_subj_filt_att  = [aci_filter.this[each.key].id]
    relation_vz_rs_subj_graph_att = aci_l4_l7_service_graph_template.this.id
}
