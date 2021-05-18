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
    routing_mode                    = "unspecified"
    sequence_number                 = "0"
    share_encap                     = "no"
    relation_vns_rs_node_to_l_dev   = "${aci_tenant.this.id}/lDevVip-${var.device_name}"
}

# Create L4-L7 Service Graph template T1 connection.
resource "aci_connection" "t1-n1" {
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.this.id
    name           = "C2"
    adj_type       = "L2"
    conn_dir       = "provider"
    conn_type      = "external"
    direct_connect = "no"
    unicast_route  = "yes"
    relation_vns_rs_abs_connection_conns = [
        aci_l4_l7_service_graph_template.this.term_prov_dn,
        aci_function_node.this.conn_provider_dn
    ]
}

# Create L4-L7 Service Graph template T2 connection.
resource "aci_connection" "n1-t2" {
    l4_l7_service_graph_template_dn = aci_l4_l7_service_graph_template.this.id
    name                            = "C1"
    adj_type                        = "L2"
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
    relation_vns_rs_l_if_ctx_to_bd   = aci_bridge_domain.consumer_bd.id
}

resource "aci_logical_interface_context" "provider" {
	logical_device_context_dn        = aci_logical_device_context.this.id
	conn_name_or_lbl                 = "provider"
	l3_dest                          = "yes"
	permit_log                       = "no"
    relation_vns_rs_l_if_ctx_to_l_if = "${aci_tenant.this.id}/lDevVip-${var.device_name}/lIf-Internal"
    relation_vns_rs_l_if_ctx_to_bd   = aci_bridge_domain.provider_bd.id
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

data "aci_rest" "vlan_consumer" {
    path = "api/node/class/vnsEPgDef.json?query-target-filter=and(eq(vnsEPgDef.lIfCtxDn,\"${aci_logical_interface_context.consumer.id}\"))"
    depends_on = [aci_rest.device, aci_epg_to_domain.consumer_epg, aci_epg_to_domain.provider_epg]
}

data "aci_rest" "vlan_provider" {
    path = "api/node/class/vnsEPgDef.json?query-target-filter=and(eq(vnsEPgDef.lIfCtxDn,\"${aci_logical_interface_context.provider.id}\"))"
    depends_on = [aci_rest.device, aci_epg_to_domain.consumer_epg, aci_epg_to_domain.provider_epg]
}