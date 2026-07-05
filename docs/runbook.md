# Operational Runbook — intuitiveAI web-app (dev)

**Audience:** An engineer who did **not** build this system and needs to deploy, verify, operate, or recover it.

This runbook covers a single Azure environment: a Linux VM running an HTTPS (nginx) service, inside a VNet with scoped NSG rules, with secrets held in Azure Key Vault. Infrastructure is defined in Terraform under `deployments/`.

---

## 0. System at a glance

| Component | Resource (dev) | Purpose |
|---|---|---|
| Resource group | `rg-intai-wa-dev-cus` | Container for all resources |
| Virtual network | `vnet-intai-wa-dev-cus` | Network, `web` subnet `10.0.1.0/24` |
| NSG | `nsg-vnet-intai-wa-dev-cus` | Allows 443 (public), 22 (admin IP only) |
| Key Vault | `kv-intai-wa-dev-cus` | Holds application secret(s) |
| Linux VM | `vm-intai-wa-dev-cus` | Runs nginx HTTPS service on 443 |
| Public IP | `pip-vm-intai-wa-dev-cus` | Public entry point for the service |

**Region:** `centralus`. **Naming:** `<resource>-<brand>-<project>-<env>-<region-alias>`, driven by `local.prefix`.

**Deploy root:** `deployments/projects/web-app/dev/` — all Terraform commands run from here unless stated otherwise.

**Authentication to Azure/Key Vault:**
- **Terraform → Azure:** a service principal, supplied via `ARM_*` environment variables (never committed).
- **VM → Key Vault:** the VM's **system-assigned managed identity**, granted `Get`/`List` on secrets only. No credentials live on the VM.

---

## 1. Prerequisites

Before doing anything, the operating engineer needs:

1. **Azure CLI** installed and logged in to the correct subscription:
   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```
2. **Terraform** >= 1.5 installed.
3. **A service principal** with Contributor on the subscription (or the resource group), plus permission to set Key Vault access policies. Export its credentials — these are read natively by the azurerm provider and must **never** be committed:
   ```bash
   export ARM_CLIENT_ID="<sp-client-id>"
   export ARM_CLIENT_SECRET="<sp-client-secret>"
   export ARM_TENANT_ID="<tenant-id>"
   export ARM_SUBSCRIPTION_ID="<subscription-id>"
   ```
   (PowerShell: `$env:ARM_CLIENT_ID = "..."` etc.)
4. **An SSH key pair** for break-glass VM access. Point `ssh_public_key_path` in `terraform.tfvars` at your `.pub` file. Keep the private key off the repo.
5. **`terraform.tfvars`** populated from `terraform.tfvars.example`. Set `allowed_ssh_cidr` to **your** IP as `x.x.x.x/32` — never `0.0.0.0/0`.

> **Region note:** This subscription enforces an `allowed-locations` Azure Policy permitting only `eastus` and `eastus2` (and any region later added). `centralus` was enabled for this deployment. If deploying elsewhere, confirm the region is policy-allowed **and** has capacity for the chosen `vm_size`, or `apply` will fail with a `403` (policy) or `409` (capacity).

---

## 2. Deploy from scratch

From `deployments/projects/web-app/dev/`:

```bash
# 1. Initialize providers, modules, and backend
terraform init

# 2. Review what will be created
terraform plan

# 3. Apply
terraform apply
# type "yes" when prompted
```

Expected result: resource group, VNet + subnet + NSG, Key Vault + access policies, public IP + NIC + Linux VM. Total time ~5–8 minutes (Key Vault provisioning is the slow step, ~3 min).

**Immediately after apply**, retrieve the outputs you'll need for verification:
```bash
terraform output
# note the VM public IP (e.g. 20.12.230.46)
```

Cloud-init runs on first boot and takes ~2–3 minutes to install and start nginx. Wait before health-checking.

> **If `apply` fails on VM SKU (409 capacity / 400 not-valid):** the chosen `vm_size` is unavailable in the region. Override with a size known to have capacity (D-series clears these more reliably than B-series), e.g. set `vm_size = "Standard_D2s_v5"` and re-apply. `vm_size` is a variable precisely so this needs no module changes.

---

## 3. Health verification

Confirm the HTTPS service is live. Replace `<vm-public-ip>` with the value from `terraform output`.

**1. Health endpoint (should return `ok`):**
```bash
curl -k https://<vm-public-ip>/health
```
- `-k` accepts the self-signed certificate — expected, not an error.
- On Windows PowerShell use `curl.exe -k ...` (the `curl` alias there is `Invoke-WebRequest` and ignores `-k`).

**2. Root page:** browse to `https://<vm-public-ip>/` and accept the certificate warning. You should see the intuitiveAI landing page.

**3. TLS is actually serving:** a "could not establish trust relationship" / certificate-trust error from a client that rejects self-signed certs is a **success signal** — it means nginx negotiated TLS. A **timeout or connection-refused** means the service is down (see §5).

**4. Verify from Azure side:**
```bash
az vm get-instance-view -g rg-intai-wa-dev-cus -n vm-intai-wa-dev-cus \
  --query "instanceView.statuses[?starts_with(code,'PowerState')].displayStatus" -o tsv
# expect: VM running
```

**5. Check the monitoring alert exists:** in the Azure portal, Monitor → Alerts → Alert rules, confirm `alert-vm-availability-<prefix>` is enabled. It fires if VM availability drops below 100% over a 5-minute window.

---

## 4. Key Vault secret rotation

The application secret is stored in `kv-intai-wa-dev-cus`. The VM reads it at boot via its managed identity (`Get`/`List` only). Rotation replaces the secret value; the VM picks up the new value on its next boot/config reload.

### Option A — rotate via Terraform (preferred, keeps state consistent)

If the secret is Terraform-managed (`azurerm_key_vault_secret` with a `random_password`), taint the password so the next apply regenerates it:

```bash
terraform apply -replace="random_password.app_secret"
```
This generates a new random value and writes it to Key Vault as a new secret version. Terraform state stays authoritative.

### Option B — rotate manually via CLI (out-of-band / emergency)

```bash
# set a new secret version
az keyvault secret set \
  --vault-name kv-intai-wa-dev-cus \
  --name app-secret \
  --value "<new-secret-value>"

# confirm the new version is current
az keyvault secret show \
  --vault-name kv-intai-wa-dev-cus \
  --name app-secret \
  --query "value" -o tsv
```
> If you rotate manually, run `terraform plan` afterward — Terraform may show drift on the secret. Reconcile by importing the change or re-applying Option A so state matches reality.

### Propagate the new secret to the running VM

The VM fetches the secret at boot. To force it to pick up the rotated value **without a full rebuild**, reboot the VM so cloud-init re-runs (or the service re-reads it):
```bash
az vm restart -g rg-intai-wa-dev-cus -n vm-intai-wa-dev-cus
```
Then re-verify with §3.

### Verify the VM's identity can still read the secret
After any access-policy change, confirm the VM identity retains `Get`/`List`:
```bash
az keyvault show --name kv-intai-wa-dev-cus \
  --query "properties.accessPolicies[].permissions.secrets" -o json
```
The VM's principal should have exactly `["Get","List"]` — no more. If it's missing, re-apply Terraform (the `azurerm_key_vault_access_policy.vm` resource re-grants it).

---

## 5. Recovery from a VM failure

Symptoms: `/health` times out or refuses connection; `az vm get-instance-view` shows the VM not `running`; the availability alert has fired.

Work through these in order — cheapest first.

### 5.1 Restart the VM (transient fault)
```bash
az vm restart -g rg-intai-wa-dev-cus -n vm-intai-wa-dev-cus
```
Wait ~2 min, then re-run §3 health checks. Fixes most transient issues.

### 5.2 Inspect the service (VM is up, service is down)
SSH in from your admin IP (the NSG allows 22 only from `allowed_ssh_cidr`):
```bash
ssh -i <path-to-private-key> azureuser@<vm-public-ip>

# check nginx
sudo systemctl status nginx
sudo systemctl restart nginx

# check cloud-init ran correctly
sudo cat /var/log/cloud-init-custom.log
sudo cloud-init status
```
If nginx failed to start, the cloud-init log shows why (cert generation, package install, config test). Fix and `sudo systemctl restart nginx`.

### 5.3 Rebuild the VM (VM is unrecoverable)
The VM is **stateless** — it holds no data that isn't reproducible from Terraform + cloud-init. Safe to destroy and recreate just the compute layer:
```bash
terraform apply -replace="module.compute.azurerm_linux_virtual_machine.this"
```
This recreates the VM (new boot → cloud-init re-installs nginx, re-fetches the secret via managed identity) while leaving the network, Key Vault, and public IP intact.

> **Note:** the public IP is a separate resource (`pip-vm-...`) and is **not** destroyed by replacing the VM, so the service returns on the **same IP**. Confirm with §3.

### 5.4 Full environment rebuild (last resort)
If state is badly drifted or multiple layers are broken:
```bash
terraform destroy   # yes
terraform apply     # yes
```
Because nothing holds persistent data, a clean rebuild is safe and produces a known-good environment. Re-verify with §3. Note the public IP **will** change in a full rebuild.

---

## 6. Teardown

To remove the entire environment:
```bash
terraform destroy
# type "yes"
```
Key Vault has `purge_protection_enabled = false` in dev, so the vault name frees immediately for re-use. (In production this would be `true`, and the vault would sit in soft-delete for the retention window.)

---

## Appendix — quick command reference

| Task | Command |
|---|---|
| Deploy | `terraform apply` |
| Health check | `curl -k https://<ip>/health` → `ok` |
| VM state | `az vm get-instance-view -g rg-intai-wa-dev-cus -n vm-intai-wa-dev-cus` |
| Restart VM | `az vm restart -g rg-intai-wa-dev-cus -n vm-intai-wa-dev-cus` |
| Rotate secret (TF) | `terraform apply -replace="random_password.app_secret"` |
| Rotate secret (CLI) | `az keyvault secret set --vault-name kv-intai-wa-dev-cus --name app-secret --value "..."` |
| Rebuild VM only | `terraform apply -replace="module.compute.azurerm_linux_virtual_machine.this"` |
| Full rebuild | `terraform destroy && terraform apply` |
