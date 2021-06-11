# Create L4-L7 Service Graph template.
resource "aci_l4_l7_service_graph_template" "this" {
    tenant_dn                         = aci_tenant.this.id
    name                              = var.service_graph.name
    description                       = var.service_graph.description
    l4_l7_service_graph_template_type = "legacy"
    ui_template_type                  = "UNSPECIFIED"
}

# Create L4-L7 Service Graph template node.
resource "aci_function_node" "this" {
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.this.id
    name                            = "N1"
    func_template_type              = "ADC_TWO_ARM"
    func_type                       = "GoTo"
    is_copy                         = "no"
    managed                         = "no"
    routing_mode                    = "Redirect"
    sequence_number                 = "0"
    share_encap                     = "no"
    relation_vns_rs_node_to_l_dev   = "${aci_tenant.this.id}/lDevVip-${var.device_name}"
}

# Create L4-L7 Service Graph template T1 connection.
resource "aci_connection" "t1-n1" {
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.this.id
    name                            = "C2"
    adj_type                        = "L3"
    conn_dir                        = "provider"
    conn_type                       = "external"
    direct_connect                  = "no"
    unicast_route                   = "yes"
    relation_vns_rs_abs_connection_conns = [
        aci_l4_l7_service_graph_template.this.term_prov_dn,
        aci_function_node.this.conn_provider_dn
    ]
}

# Create L4-L7 Service Graph template T2 connection.
resource "aci_connection" "n1-t2" {
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.this.id
    name                            = "C1"
    adj_type                        = "L3"
    conn_dir                        = "provider"
    conn_type                       = "external"
    direct_connect                  = "no"
    unicast_route                   = "yes"
    relation_vns_rs_abs_connection_conns = [
        aci_l4_l7_service_graph_template.this.term_cons_dn,
        aci_function_node.this.conn_consumer_dn
    ]
}

# Create L4-L7 Logical Device Context.
resource "aci_logical_device_context" "this" {
    tenant_dn                          = aci_tenant.this.id
    ctrct_name_or_lbl                  = aci_contract.this.name
    graph_name_or_lbl                  = var.service_graph.name
    node_name_or_lbl                   = "N1"
    relation_vns_rs_l_dev_ctx_to_l_dev = "${aci_tenant.this.id}/lDevVip-${var.device_name}"
}

# Create L4-L7 Logical Device Interface Contexts.
resource "aci_logical_interface_context" "consumer" {
	logical_device_context_dn        = aci_logical_device_context.this.id
	conn_name_or_lbl                 = "consumer"
	l3_dest                          = "yes"
	permit_log                       = "no"
    relation_vns_rs_l_if_ctx_to_l_if = "${aci_tenant.this.id}/lDevVip-${var.device_name}/lIf-External"
    relation_vns_rs_l_if_ctx_to_bd   = aci_bridge_domain.consumer_service_bd.id
}

resource "aci_logical_interface_context" "provider" {
	logical_device_context_dn        = aci_logical_device_context.this.id
	conn_name_or_lbl                 = "provider"
	l3_dest                          = "no"
	permit_log                       = "no"
    relation_vns_rs_l_if_ctx_to_l_if = "${aci_tenant.this.id}/lDevVip-${var.device_name}/lIf-Internal"
    relation_vns_rs_l_if_ctx_to_bd   = aci_bridge_domain.provider_service_bd.id
    relation_vns_rs_l_if_ctx_to_svc_redirect_pol = aci_service_redirect_policy.this.id
}

# Query for the VMM controller.
data "aci_vmm_controller" "this" {
    vmm_domain_dn = data.aci_vmm_domain.this.id
    name          = var.vmm_controller_name
}

# Create L4-L7 Device.
resource "aci_rest" "device" {
    path    = "api/node/mo/${aci_tenant.this.id}/lDevVip-${var.device_name}.json"
    payload = templatefile(
        "${path.module}/template.json",
        {
            annotation          = var.annotation
            tenant_dn           = aci_tenant.this.id
            device_name         = var.device_name
            vmm_domain_dn       = data.aci_vmm_domain.this.id
            vmm_controller_dn   = data.aci_vmm_controller.this.id
            vmm_controller_name = var.vmm_controller_name
            vm_name             = var.vm_name
            internal_vnic       = var.vnic.internal
            external_vnic       = var.vnic.external
        }
    )
}

# Create Redirect Health Group.
resource "aci_rest" "health_group" {
    path       = "api/node/mo/${aci_tenant.this.id}/svcCont/redirectHealthGroup-${var.health_group_name}.json"
    class_name = "vnsRedirectHealthGroup"
    content    = {
        annotation = var.annotation
        name       = var.health_group_name
    }
}

# Create IP SLA Monitoring Policy.
resource "aci_rest" "ip_sla" {
    path       = "api/node/mo/${aci_tenant.this.id}/ipslaMonitoringPol-${var.ip_sla_name}.json"
    class_name = "fvIPSLAMonitoringPol"
    content    = {
        annotation          = var.annotation
        name                = var.ip_sla_name
        slaDetectMultiplier = "3"
        slaFrequency        = "3"
        slaType             = "icmp"
    }
}

# Create a L4-L7 Redirection Policy (PBR Policy)
resource "aci_service_redirect_policy" "this" {
    tenant_dn             = aci_tenant.this.id
    name                  = "${var.service_graph.name}-redirectPolicy"
    dest_type             = "L3"
    hashing_algorithm     = "sip-dip-prototype"
    threshold_down_action = "permit"
    threshold_enable      = "no"
    relation_vns_rs_ipsla_monitoring_pol = aci_rest.ip_sla.id
}

# Create a L4-L7 Destination in a Redirection Policy (PBR Destination)
resource "aci_destination_of_redirected_traffic" "this" {
    dest_name                  = var.device_name
    service_redirect_policy_dn = aci_service_redirect_policy.this.id
    ip                         = var.device_ip_address
    mac                        = var.device_mac_address
    relation_vns_rs_redirect_health_group = aci_rest.health_group.id
}

# Query Consumer Arm VLAN
data "aci_rest" "vlan_consumer" {
    path = "api/node/class/vnsEPgDef.json?query-target-filter=and(eq(vnsEPgDef.lIfCtxDn,\"${aci_logical_interface_context.consumer.id}\"))"
    depends_on = [aci_rest.device, aci_epg_to_domain.consumer_epg, aci_epg_to_domain.provider_epg]
}

# Query Provider Arm VLAN
data "aci_rest" "vlan_provider" {
    path = "api/node/class/vnsEPgDef.json?query-target-filter=and(eq(vnsEPgDef.lIfCtxDn,\"${aci_logical_interface_context.provider.id}\"))"
    depends_on = [aci_rest.device, aci_epg_to_domain.consumer_epg, aci_epg_to_domain.provider_epg]
}