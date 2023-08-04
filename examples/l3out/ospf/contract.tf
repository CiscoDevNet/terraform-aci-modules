resource "aci_contract" "contract" {
  tenant_dn = aci_tenant.tenant.id
  name      = "For_Internet"
}

resource "aci_contract_subject" "contract_subject" {
  contract_dn   = aci_contract.contract.id
  name          = "contract_subject"
  rev_flt_ports = "no"
}

resource "aci_filter" "filter" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "filter1"
  description = "This filter is created by terraform ACI provider."
}

resource "aci_filter_entry" "demoentry" {
  filter_dn     = aci_filter.filter.id
  name          = "entry1"
  description   = "This entry is created by terraform ACI provider"
  apply_to_frag = "no"
  arp_opc       = "unspecified"
  d_from_port   = "80"
  d_to_port     = "80"
  ether_t       = "ip"
  icmpv4_t      = "unspecified"
  icmpv6_t      = "unspecified"
  match_dscp    = "AF11"
  prot          = "tcp"
  s_from_port   = "80"
  s_to_port     = "443"
  stateful      = "no"
  tcp_rules     = ["ack"]
}

resource "aci_contract_subject_filter" "contract_subject_filter" {
  contract_subject_dn = aci_contract_subject.contract_subject.id
  action              = "permit"
  directives          = ["log"]
  priority_override   = "default"
  filter_dn           = aci_filter.filter.id
}
