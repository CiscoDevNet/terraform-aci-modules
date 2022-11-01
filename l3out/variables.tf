terraform {
  experiments = [module_variable_optional_attrs]
}

variable "tenant_dn" {
  type = string
}

variable "name" {
  type = string
}

variable "alias" {
  type    = string
  default = ""
}

variable "annotation" {
  type    = string
  default = "orchestrator:terraform"
}

variable "description" {
  default = ""
}

variable "vrf_dn" {
  type    = string
  default = ""
}

variable "l3_domain_dn" {
  type    = string
  default = ""
}

variable "route_profile_for_interleak_dn" {
  type    = string
  default = ""
}

variable "route_control_for_dampening" {
  type = list(object({
    address_family = optional(string) # choose between ipv4 and v6
    route_map_dn   = optional(string)
  }))
  validation {
    condition     = contains(["ipv4", "ipv6"], var.route_control_for_dampening[0].address_family)
    error_message = "Valid values for route_control_for_dampening are (ipv4, ipv6)"
  }
}

variable "route_control_enforcement" {
  type = bool
}

variable "target_dscp" {
  type    = string
  default = "unspecified"
  validation {
    condition     = contains(["CS0", "CS1", "AF11", "AF12", "AF13", "CS2", "AF21", "AF22", "AF23", "CS3", "CS4", "CS5", "CS6", "CS7", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "VA", "EF", "unspecified"], var.target_dscp)
    error_message = "Valid values for target_dscp are (CS0, CS1, AF11, AF12, AF13, CS2, AF21, AF22, AF23, CS3, CS4, CS5, CS6, CS7, AF31, AF32, AF33, AF41, AF42, AF43, VA, EF, unspecified)"
  }
}

############## Variables for  "aci_l3out_bgp_external_policy" ####################    
variable "external_bgp_name_alias" {
  default = ""
}

############## Variables for  "aci_l3out_external_epg" ####################
variable "l3out_external_epg" {
  type = list(object({
    annotation             = optional(string)
    description            = optional(string)
    exception_tag          = optional(string)
    flood_on_encapsulation = optional(string)
    label_match_criteria   = optional(string)
    alias                  = optional(string)
    name                   = string
    preferred_group_member = optional(bool)
    qos_class              = optional(string)
    target_dscp            = optional(string)
    route_control_profiles = optional(list(object({
      direction    = string
      route_map_dn = string
    })))
    subnets = optional(list(object({
      ip        = string
      aggregate = optional(string)
      alias     = optional(string)
      scope     = list(string)
    })))
  }))
  validation {
    condition     = alltrue([for criteria in var.l3out_external_epg : contains(["All", "AtleastOne", "AtmostOne", "None"], criteria["label_match_criteria"])])
    error_message = "Valid values for label_match_criteria in l3out_external_epg are (All, AtleastOne, AtmostOne, None)"
  }
  validation {
    condition     = alltrue([for index, class in var.l3out_external_epg : contains(["unspecified", "level6", "level5", "level4", "level3", "level2", "level1"], var.l3out_external_epg[index].qos_class)])
    error_message = "Valid values for qos_class in l3out_external_epg are (unspecified, level6, level5, level4, level3, level2, level1)"
  }
  validation {
    condition     = alltrue([for dscp in var.l3out_external_epg : contains(["CS0", "CS1", "AF11", "AF12", "AF13", "CS2", "AF21", "AF22", "AF23", "CS3", "CS4", "CS5", "CS6", "CS7", "AF31", "AF32", "AF33", "AF41", "AF42", "AF43", "VA", "EF", "unspecified"], dscp["target_dscp"])])
    error_message = "Valid values for target_dscp in l3out_external_epg are (CS0, CS1, AF11, AF12, AF13, CS2, AF21, AF22, AF23, CS3, CS4, CS5, CS6, CS7, AF31, AF32, AF33, AF41, AF42, AF43, VA, EF, unspecified)"
  }
  validation {
    condition = alltrue([for aggregate in(flatten([
      for external_epg in var.l3out_external_epg : [
        for subnet in(external_epg.subnets == null) ? [] : external_epg.subnets : [
          subnet.aggregate
        ]
      ]
    ])) : contains(["import-rtctrl", "export-rtctrl", "shared-rtctrl", "none"], aggregate)])
    error_message = "Valid values for aggregate in subnets of l3out_external_epg are (import-rtctrl, export-rtctrl, shared-rtctrl, none)"
  }
  validation {
    condition = alltrue([for scope in(flatten([
      for external_epg in var.l3out_external_epg : [
        for subnet in(external_epg.subnets == null) ? [] : external_epg.subnets : [
          subnet.scope
        ]
      ]
    ])) : contains(["import-rtctrl", "export-rtctrl", "shared-rtctrl", "none"], scope)])
    error_message = "Valid values for scope in subnets of l3out_external_epg are (import-rtctrl, export-rtctrl, shared-rtctrl, import-security, shared-security)"
  }
  validation {
    condition = alltrue([for direction in(flatten([
      for external_epg in var.l3out_external_epg : [
        for profile in(external_epg.route_control_profiles == null) ? [] : external_epg.route_control_profiles : [
          profile.direction
        ]
      ]
    ])) : contains(["export", "import"], direction)])
    error_message = "Valid values for direction in route_control_profiles of l3out_external_epg are (export, import)"
  }
}

output "vars" {
  value = [for direction in(flatten([
    for external_epg in var.l3out_external_epg : [
      for profile in(external_epg.route_control_profiles == null) ? [] : external_epg.route_control_profiles : [
        profile.direction
      ]
    ]
  ])) : direction]
}
