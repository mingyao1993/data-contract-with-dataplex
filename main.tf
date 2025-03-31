locals {
  yaml_data = yamldecode(file("data-contract.yaml"))
  rule_attributes = flatten([
    for column in local.yaml_data.columns : [
      for rule in lookup(column, "data_quality_rules", []) : merge(rule, { column = column.name })
    ]
  ])
}

# output "yaml" {
#   value = local.yaml_data
# }

# output "rules" {
#   value = local.flattened_rules
# }

resource "google_dataplex_datascan" "full_quality_scan" {
  location     = "europe-west2"
  project      = "prj-vo-aa-s-platform-eng"
  display_name = local.yaml_data.dataset
  data_scan_id = replace(local.yaml_data.dataset, "_", "-")
  description  = local.yaml_data.description
  labels = {
    project = "prj-vo-aa-s-platform-eng"
  }

  data {
    resource = "prj-vo-aa-s-platform-eng.my_dataset.all_data_types"
  }

  execution_spec {
    trigger {
      on_demand {}
    }
  }

  data_quality_spec {
    sampling_percent = 10

    dynamic "rules" {
      for_each = local.rule_attributes
      content {
        name        = rules.value.name
        description = rules.value.description
        dimension   = rules.value.dimension
        threshold   = rules.value.threshold
        column      = rules.value.column
        dynamic "non_null_expectation" {
          for_each = lookup(rules.value, "non_null_expectation", {})
          content {}
        }
        dynamic "range_expectation" {
          for_each = lookup(rules.value, "range_expectation", {})
          content {
            min_value          = lookup(rules.value.range_expectation, "min_value", null)
            max_value          = lookup(rules.value.range_expectation, "max_value", null)
            strict_min_enabled = lookup(rules.value.range_expectation, "strict_min_enabled", null)
            strict_max_enabled = lookup(rules.value.range_expectation, "strict_max_enabled", null)
          }
        }
      }
    }
  }
}
