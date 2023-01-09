resource "aci_route_control_profile" "profile" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile"
  route_control_profile_type = "global"
}

resource "aci_route_control_profile" "profile2" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile2"
  route_control_profile_type = "global"
}
