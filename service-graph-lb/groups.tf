# Define an ACI Application Profile Resource.
resource "aci_application_profile" "this" {
    tenant_dn   = aci_tenant.this.id
    name        = var.ap.name
    description = var.ap.description
}

# Define an ACI Consumer EPG Resource.
resource "aci_application_epg" "consumer_epg" {
    application_profile_dn  = aci_application_profile.this.id
    name                    = var.epgs.consumer.name
    relation_fv_rs_bd       = aci_bridge_domain.consumer_bd.id
    description             = var.epgs.consumer.description
}

# Define an ACI Provider EPG Resource.
resource "aci_application_epg" "provider_epg" {
    application_profile_dn  = aci_application_profile.this.id
    name                    = var.epgs.provider.name
    relation_fv_rs_bd       = aci_bridge_domain.provider_bd.id
    description             = var.epgs.provider.description
}

# Query for the VMM domain.
data "aci_vmm_domain" "this" {
    provider_profile_dn  = var.vmm_provider_dn
    name                 = var.vmm_domain_name
}

# Associate the EPG Resources with a VMM Domain.
resource "aci_epg_to_domain" "consumer_epg" {
    application_epg_dn = aci_application_epg.consumer_epg.id
    tdn                = data.aci_vmm_domain.this.id
    res_imedcy         = "immediate"
}

# Associate the EPG Resources with a VMM Domain.
resource "aci_epg_to_domain" "provider_epg" {
    application_epg_dn = aci_application_epg.provider_epg.id
    tdn                = data.aci_vmm_domain.this.id
    res_imedcy         = "immediate"
}

# Associate the EPGs with the contrats.
resource "aci_epg_to_contract" "consumer" {
    application_epg_dn = aci_application_epg.consumer_epg.id
    contract_dn        = aci_contract.this.id
    contract_type      = "consumer"
}

resource "aci_epg_to_contract" "provider" {
    application_epg_dn = aci_application_epg.provider_epg.id
    contract_dn        = aci_contract.this.id
    contract_type      = "provider"
}
