# AI Usage Note

AI usage was permitted for this assessment. This note describes how I used it.

## Tools

I used an AI assistant (Claude) as a pair-programming and review partner throughout
the build, alongside the standard toolchain (Terraform, Azure CLI, TFLint, Git). I
also used inline AI code suggestions in VS Code while writing the Terraform code,
accepting or rejecting completions as I went.

## How I used it

**Architecture and scoping.** I used AI to pressure-test structural decisions — for
example, whether to include a `foundation` layer for subscription/management-group/
policy resources, whether to use Azure Bastion instead of scoped SSH, and how to
organize modules for reuse. In each case the decision was to scope to the assessment
brief and document the production-grade alternative in the README, rather than
over-engineer. AI was useful for arguing both sides; the scoping calls were mine.

**Module scaffolding.** I used AI to draft initial module code (Key Vault, compute,
networking, monitoring) which I then reviewed, corrected, and adapted to my naming
convention and layout. Several drafts needed real fixes — e.g. removing an inline
Key Vault `access_policy` block that conflicted with the standalone
`azurerm_key_vault_access_policy` pattern I chose for least-privilege decoupling.

**Debugging.** I used AI to help interpret errors encountered during real deployment,
including: `git` rejecting a pushed provider binary over the file-size limit (fixed by
correcting `.gitignore` and rewriting history), PowerShell-vs-cmd syntax differences,
Key Vault permission case-sensitivity, VM SKU capacity (`409`) and validity (`400`)
errors across regions, an `allowed-locations` Azure Policy blocking `centralus`, and
Terraform state drift on a partially-created access policy.

**Documentation.** I used AI to help draft the README and runbook, which I then
verified against the actually-deployed resources (resource names, region, commands)
rather than accepting them as written.

## What I verified myself

All infrastructure was deployed and verified by me against live Azure resources:
the HTTPS service was confirmed serving on 443 (`curl -k https://<ip>/health` → `ok`),
NSG scoping and Key Vault access policies were checked against the deployed state, and
the CI pipeline was confirmed running on a pull request. AI accelerated the work and
caught issues early, but every decision and every deployed resource was reviewed and
validated by me.
