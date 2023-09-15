resource "azurecaf_name" "vngw_connection" {
  name          = var.settings.name
  resource_type = "azurerm_virtual_network_gateway"
  prefixes      = var.global_settings.prefixes
  random_length = var.global_settings.random_length
  clean_input   = true
  passthrough   = var.global_settings.passthrough
  use_slug      = var.global_settings.use_slug
}

resource "azurerm_virtual_network_gateway_connection" "vngw_connection" {
  name                = azurecaf_name.vngw_connection.result
  location            = var.location
  resource_group_name = var.resource_group_name
  #only ExpressRoute and IPSec are supported. Vnet2Vnet is excluded.
  type                       = var.settings.type
  virtual_network_gateway_id = var.virtual_network_gateway_id

  # The following arguments are applicable only if the type="ExpressRoute"
  express_route_circuit_id = try(var.express_route_circuit_id, null)
  authorization_key        = try(var.authorization_key, null)


  # The following arguments are applicable only if the type="IPsec" (VPN)
  connection_protocol                = can(var.settings.connection_protocol) ? var.settings.connection_protocol : try(var.settings.connection_method, null) #azurerm calls this attribute 'connection_protocol' so that is what we should be setting in our tfvars file!
  local_network_gateway_id           = try(var.local_network_gateway_id, null)
  dpd_timeout_seconds                = try(var.settings.dpd_timeout_seconds, null)
  shared_key                         = try(var.settings.shared_key, null)
  connection_mode                    = try(var.settings.connection_mode, null)  # ResponderOnly/InitiatorOnly/Default
  tags                               = local.tags

  #Only one IP Sec Policy block per connection
  dynamic "ipsec_policy" {
    for_each = try(var.settings.ipsec_policy, {})
    content {
      # Phase 1
      dh_group         = ipsec_policy.value.dh_group               # DHGroup1, DHGroup14, DHGroup2, DHGroup2048, DHGroup24, ECP256, ECP384, or None
      ike_encryption   = ipsec_policy.value.ike_encryption         # AES128, AES192, AES256, DES, or DES3
      ike_integrity    = ipsec_policy.value.ike_integrity          # MD5, SHA1, SHA256, or SHA384
      sa_datasize      = try(ipsec_policy.value.sa_datasize, null) # Must be at least 1024 KB. Defaults to 102400000 KB.
      sa_lifetime      = try(ipsec_policy.value.sa_lifetime, null) # Must be at least 300 seconds. Defaults to 27000 seconds.
      # Phase 2
      ipsec_encryption = ipsec_policy.value.ipsec_encryption       # AES128, AES192, AES256, DES, DES3, GCMAES128, GCMAES192, GCMAES256, or None.
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity        # GCMAES128, GCMAES192, GCMAES256, MD5, SHA1, or SHA256.
      pfs_group        = ipsec_policy.value.pfs_group              # ECP256, ECP384, PFS1, PFS2, PFS2048, PFS24, or None
      # Phase 2 lifetime                  =  27000 
    }
  }

  # Handling BGP layers (traditional "tunnel-mode" ipsec vpn)
  enable_bgp                         = try(var.settings.enable_bgp, null) # If true, likely custom bgp addresses are used for peering
  dynamic "custom_bgp_addresses" {
    for_each = try(var.settings.custom_bgp_addresses, {})
    content {
      primary = try(custom_bgp_addresses.value.primary, null)
      secondary = try(custom_bgp_addresses.value.secondary, null)
    }
  }

  # routing weight, added to any advertised route, to each receiving peer/neighbour
  routing_weight = try(var.settings.routing_weight, null)

  # Handling Traffic Selectors (modern "route-mode" ipsec vpn)
  use_policy_based_traffic_selectors = try(var.settings.use_policy_based_traffic_selectors, false) #if set true, traffic_selectors_policy needs to be used
  dynamic "traffic_selector_policy" {
    for_each = try(var.settings.traffic_selector_policy, {})
    content {
      local_address_cidrs = try( traffic_selector_policy.value.local_address_cidrs, null )
      remote_address_cidrs = try( traffic_selector_policy.value.remote_address_cidrs, null )
    }
  }

  # Supporting NAT RULE IDs
  ingress_nat_rule_ids = try( var.settings.ingress_nat_rule_ids, null )
  egress_nat_rule_ids =  try( var.settings.egress_nat_rule_ids, null )

  timeouts {
    create = "60m"
    delete = "60m"
  }


}