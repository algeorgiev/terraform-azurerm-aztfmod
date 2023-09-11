# Ref : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip

resource "azurerm_public_ip" "pip" {
  name                = var.name
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = var.allocation_method
  domain_name_label   = var.generate_domain_name_label ? var.name : var.domain_name_label
  reverse_fqdn        = var.reverse_fqdn
  tags                = merge(local.tags, try(var.tags, {}))
  public_ip_prefix_id = var.public_ip_prefix_id
  ip_tags             = var.ip_tags
  ip_version          = var.ip_version
  sku                 = var.sku
  sku_tier            = var.sku_tier

  # Apply conditional logic to the application of the ZONES attribute.
  zones               = try(var.zones, []) == null ? [] :  alltrue(try([for z in var.zones : z == "1" || z == "2" || z == "3" || z == ""],["0"])) == true ? var.zones : ["1", "2", "3"]
  
}

/*
  ZONES COMMENTS
  CODE: try(var.zones, []) == null ? [] :  alltrue(try([for z in var.zones : z == "1" || z == "2" || z == "3" || z == ""],["0"])) == true ? var.zones : ["1", "2", "3"]
  
  Example:
  var.zones=null
    try(null, []) == null ? [] :  alltrue(try([for z in null : z == "1" || z == "2" || z == "3" || z == ""],["0"])) == true ? null : ["1", "2", "3"]
  result=[]  EXPECTED

  var.zones="null"
    try("null", []) == null ? [] :  alltrue(try([for z in "null" : z == "1" || z == "2" || z == "3" || z == ""],["0"])) == true ? "null" : ["1", "2", "3"]
  result=["1", "2", "3"]  EXPECTED

  var.zones=["1"]
    try([1], []) == null ? [] :  alltrue(try([for z in [1] : z == "1" || z == "2" || z == "3" || z == ""],["0"])) == true ? [1] : ["1", "2", "3"]
  result=[1]  EXPECTED
  #NOTE terraform uses un-quoted strings as map-identifiers, unquoted integers are written in as their STRING values.

  var.zones=["1","2"] 
    try(["1","2"], []) == null ? [] :  alltrue(try([for z in ["1","2"] : z == "1" || z == "2" || z == "3" || z == ""],["0"])) == true ? [1] : ["1", "2", "3"]
  result=[1]  EXPECTED

*/