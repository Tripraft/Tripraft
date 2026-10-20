# Infrastructure provisioning placeholder

This directory reserves a location for future provider-specific Terraform. It contains no `.tf` modules, backend configuration or state, and does not provision infrastructure.

Before adding configuration, select the hosting provider and region, network boundaries, database/backup requirements, secret storage, state backend and deployment identity. Document those choices with the modules so maintainers can understand what a plan would create or change.

The current application release path uses a configured hosting deployment hook, described in [the runbook](../../docs/runbook.md). See the [infrastructure file guide](../README.md) for the existing Docker, workflow and tooling responsibilities.
