variable "prefix"   { type = string }
variable "location" { type = string }
variable "rg_name"  { type = string }
variable "tags"     { type = map(string) }

variable "subnet_ids" {
  description = "Map of spoke subnet IDs: {ingress, app, data, private}"
  type = object({
    ingress = string
    app     = string
    data    = string
    private = string
  })
}

variable "office_cidrs" { type = list(string) }

variable "extra_rules_per_snet" {
  description = "Additional rules per subnet."
  type = object({
    ingress = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
    app     = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
    data    = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
    private = list(object({ name=string, priority=number, direction=string, access=string, protocol=string,
      source_port_range=string, destination_port_range=string, source_address_prefix=string, destination_address_prefix=string }))
  })
}
