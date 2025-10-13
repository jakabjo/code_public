locals {
  name = "hello"
  tags = { Project = "azure-tf-snippets", Env = "dev" }
}

variable "location" { type = string default = "westus2" }

module "rg" {
  source   = "../../modules/rg"
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

# Create a tiny Python function zip (host.json + function.json + __init__.py)
resource "local_file" "host" {
  filename = "${path.module}/host.json"
  content  = <<-JSON
  { "version": "2.0" }
  JSON
}

resource "local_file" "function_json" {
  filename = "${path.module}/HttpTrigger/function.json"
  content  = <<-JSON
  {
    "bindings": [
      {
        "authLevel": "anonymous",
        "type": "httpTrigger",
        "direction": "in",
        "name": "req",
        "methods": ["get"],
        "route": "/"
      },
      {
        "type": "http",
        "direction": "out",
        "name": "res"
      }
    ]
  }
  JSON
}

resource "local_file" "__init__" {
  filename = "${path.module}/HttpTrigger/__init__.py"
  content  = <<-PY
  import json
  def main(req):
      return {
          "statusCode": 200,
          "body": "hello from Azure Functions"
      }
  PY
}

resource "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/function.zip"
  source_dir  = path.module
  excludes    = ["*.tf*", "*.zip"]
}

module "func" {
  source              = "../../modules/function-http"
  name                = local.name
  resource_group_name = module.rg.name
  location            = var.location
  zip_path            = archive_file.zip.output_path
  tags                = local.tags
}

output "function_url_hint" { value = "https://" + module.func.function_default_hostname + "/api/" }
