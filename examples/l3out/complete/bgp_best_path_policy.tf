resource "aci_bgp_best_path_policy" "best_path_policy" {
  tenant_dn = aci_tenant.tenant.id
  name      = "bgp_path1"
  ctrl      = "asPathMultipathRelax"
}
