# databricks/notebooks/setup/Mount_ADLS.py
storage_account = "adfdatabricks456"
container = "datalake"
client_id = "{{PLACEHOLDER_SPN_APP_ID}}"
tenant_id = "{{PLACEHOLDER_TENANT_ID}}"
client_secret = "{{PLACEHOLDER_SPN_SECRET}}"

configs = {
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": client_id,
  "fs.azure.account.oauth2.client.secret": client_secret,
  "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
}

mount_point = f"/mnt/{container}"
if not any(mount.mountPoint == mount_point for mount in dbutils.fs.mounts()):
  dbutils.fs.mount(
    source = f"abfss://{container}@{storage_account}.dfs.core.windows.net/",
    mount_point = mount_point,
    extra_configs = configs
  )
