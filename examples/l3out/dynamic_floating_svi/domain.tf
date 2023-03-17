resource "aci_vmm_domain" "virtual_domain" {
  provider_profile_dn       = "uni/vmmp-VMware"
  name                      = "vm_Domain"
}
