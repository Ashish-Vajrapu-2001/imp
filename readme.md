# Azure SQL to Delta Lake CDC Pipeline

Metadata-driven pipeline handling extraction from Azure SQL (ERP, CRM, Marketing) to Data Lake.

## Features
- **Metadata Driven**: Add tables via SQL, not code.
- **State Management**: Automatically handles Initial vs Incremental.
- **Lineage**: Uses `pipeline_run_id` for end-to-end traceability.
- **Resources**:
  - ADF: `ADF-Databricks456`
  - ADLS: `adfdatabricks456`
  - SQL: `adf-databricks`
