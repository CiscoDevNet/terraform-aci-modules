resource "aci_application_epg" "Web_epg" {
  application_profile_dn = aci_application_profile.app_profile_for_epg.id
  name                   = "Web_epg"
  relation_fv_rs_bd      = aci_bridge_domain.bridge_domain.id
  relation_fv_rs_cons    = [aci_contract.contract.id]
}
