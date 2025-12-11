# Deployment Guide

1. **Infrastructure**: Deploy Azure Resources using ARM/Bicep.
2. **Database**: Run SQL scripts 01-05 in `sql/` folder against `ADF-Databricks` database.
3. **Secret Management**: Add secrets to Key Vault `ADF-Databricks1`.
4. **ADF**: Import Linked Services, then Datasets, then Pipelines.
5. **Databricks**: Import Notebooks to workspace.
6. **Initial Run**: Trigger `PL_Master_Orchestrator`. It will detect `initial_load_completed = 0` and run full loads.
