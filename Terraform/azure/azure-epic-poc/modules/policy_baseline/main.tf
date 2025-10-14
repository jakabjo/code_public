# Simple example: require specific tags
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-tags"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require standard tags"
  policy_rule  = jsonencode({
    if = {
      field = "type"
      notEquals = "Microsoft.Resources/subscriptions/resourceGroups"
    }
    then = {
      effect = "deny"
      details = {
        missingCondition = {
          anyOf = [
            for t in var.tags_required : {
              field = "tags[${t}]"
              exists = "true"
            }
          ]
        }
      }
    }
  })
}

resource "azurerm_policy_assignment" "require_tags_assign" {
  for_each             = toset(var.assignment_scope_rg_ids)
  name                 = "require-tags-assignment-${index(var.assignment_scope_rg_ids, each.value)}"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  scope                = each.value
}
