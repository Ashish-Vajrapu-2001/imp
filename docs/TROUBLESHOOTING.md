# Troubleshooting

- **Initial Load Loop**: If pipeline keeps running Initial Load, check `control.table_metadata`. Ensure `initial_load_completed` is being set to 1. Verify `sp_UpdateTableMetadata` execution in Databricks logs.
- **Missing Columns**: Ensure CDC and Source tables schema match.
- **Access Denied**: Check Key Vault permissions for ADF Managed Identity.
