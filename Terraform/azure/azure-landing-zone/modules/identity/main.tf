variable "mfa_excluded_user_object_ids" { type = list(string) }
variable "include_guests"               { type = bool }

resource "azuread_conditional_access_policy" "require_mfa" {
  display_name = "Require MFA - All Users (with exclusions)"
  state        = "enabled"

  conditions {
    users {
      include_users  = ["All"]
      exclude_users  = var.mfa_excluded_user_object_ids
      include_guests = var.include_guests
    }
    applications { include_applications = ["All"] }
    client_app_types = ["all"]
  }

  grant_controls { operator = "OR" built_in_controls = ["mfa"] }
  session_controls {}
}
