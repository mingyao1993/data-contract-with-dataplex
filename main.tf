locals {
    _file_data_contract = yamldecode(file("${path.module}/data_contract.yaml"))
    
    gcp_project = local._file_data_contract.server.project
    gcp_region = local._file_data_contract.server.region

    bq_dataset = local._file_data_contract.server.dataset
    bq_table = local._file_data_contract.schema.table
}

resource "google_dataplex_datascan" "dq_scan" {
  project      = local.gcp_project
  location     = local.gcp_region
  data_scan_id = replace("${local.bq_dataset}_${local.bq_table}", "_", "-")

  data {
    resource = "//bigquery.googleapis.com/projects/${local.gcp_project}/datasets/${local.bq_dataset}/tables/${local.bq_table}"
  }

  execution_spec {
    trigger {
      dynamic "on_demand" {
        for_each = try(local.execution.trigger.on_demand, null) != null ? [""] : []
        content {}
      }

      dynamic "schedule" {
        for_each = try(local.execution.trigger.schedule, null) != null ? [""] : []
        content {
          cron = local.execution.trigger.schedule.cron
        }
      }
    }

    field = try(local.execution.field, null)
  }

  # Custom logic to parse out rules metadata from a local rules.yaml file
  data_quality_spec {
    sampling_percent = try(local.sampling_percent, null)
    row_filter       = try(local.row_filter, null)

    dynamic "rules" {
      for_each = local.rules
      content {
        column      = try(rules.value.column, null)
        ignore_null = try(rules.value.ignore_null, null)
        dimension   = rules.value.dimension
        description = try(rules.value.description, null)
        name        = try(rules.value.name, null)
        threshold   = try(rules.value.threshold, null)

        dynamic "non_null_expectation" {
          for_each = try(rules.value.non_null_expectation, null) != null ? [""] : []
          content {
          }
        }

        dynamic "range_expectation" {
          for_each = try(rules.value.range_expectation, null) != null ? [""] : []
          content {
            min_value          = try(rules.value.range_expectation.min_value, null)
            max_value          = try(rules.value.range_expectation.max_value, null)
            strict_min_enabled = try(rules.value.range_expectation.strict_min_enabled, null)
            strict_max_enabled = try(rules.value.range_expectation.strict_max_enabled, null)
          }
        }

        dynamic "set_expectation" {
          for_each = try(rules.value.set_expectation, null) != null ? [""] : []
          content {
            values = rules.value.set_expectation.values
          }
        }

        dynamic "uniqueness_expectation" {
          for_each = try(rules.value.uniqueness_expectation, null) != null ? [""] : []
          content {
          }
        }

        dynamic "regex_expectation" {
          for_each = try(rules.value.regex_expectation, null) != null ? [""] : []
          content {
            regex = rules.value.regex_expectation.regex
          }
        }

        dynamic "statistic_range_expectation" {
          for_each = try(rules.value.statistic_range_expectation, null) != null ? [""] : []
          content {
            min_value          = try(rules.value.statistic_range_expectation.min_value, null)
            max_value          = try(rules.value.statistic_range_expectation.max_value, null)
            strict_min_enabled = try(rules.value.statistic_range_expectation.strict_min_enabled, null)
            strict_max_enabled = try(rules.value.statistic_range_expectation.strict_max_enabled, null)
            statistic          = rules.value.statistic_range_expectation.statistic
          }
        }

        dynamic "row_condition_expectation" {
          for_each = try(rules.value.row_condition_expectation, null) != null ? [""] : []
          content {
            sql_expression = rules.value.row_condition_expectation.sql_expression
          }
        }

        dynamic "table_condition_expectation" {
          for_each = try(rules.value.table_condition_expectation, null) != null ? [""] : []
          content {
            sql_expression = rules.value.table_condition_expectation.sql_expression
          }
        }

        dynamic "sql_assertion" {
          for_each = try(rules.value.sql_assertion, null) != null ? [""] : []
          content {
            sql_statement = rules.value.sql_assertion.sql_statement
          }
        }
      }
    }
  }
}

resource "google_monitoring_alert_policy" "dq_scan" {
  display_name = "dataplex_dq_scan_${google_dataplex_datascan.dq_scan.id}"
  combiner     = "OR"
  conditions {
    display_name = "Log match condition: Failed Job Execution"
    condition_matched_log {
      filter = "severity=\"ERROR\" resource.type = \"dataplex.googleapis.com/Task\" logName = \"projects/${local.gcp_project}/logs/dataplex.googleapis.com%2Fprocess\" jsonPayload.state = \"FAILED\""
    }
  }
  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
    auto_close = "604800s"
  }
}
