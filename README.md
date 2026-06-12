# SWA Azure Demo

## Quick Start

```bash
cp setup.env.example setup.env

# Change PROJECT_PREFIX, CONJUR_TENANT, AZURE_TENANT_ID, AZURE_REGION
# Ensure PROJECT_PREFIX is unique, it is used to compute resource names
$EDITOR setup.env

# Check prerequisites
bash ./scripts/bootstrap.sh

# Download binaries from marketplace, put tarfile in ./dist dir
task swa:extract
task swa:prep

# ONLY if on a mac and running terraform locally, you may need to clear the quarantine xattr
task swa:mac-fix-tf-provider

# Deploy to kind cluster
task deploy-all
```

## Quick Start Summary

### 1. Configure

Set these vars:

| Variable Name   | Example                                                                                    |
| --------------- | ------------------------------------------------------------------------------------------ |
| PROJECT_PREFIX  | Prefix used to compute resource names                                                      |
| CONJUR_TENANT   | Subdomain part of Secrets Manager, ex: https://<CONJUR_TENANT>.secretsmgr.cyberark.cloud   |
| AZURE_TENANT_ID | Ex: 00000000-0000-0000-0000-000000000000 - Get it: az account show --query tenantId -o tsv |
| AZURE_REGION    | Ex: eastus, westus, centralus, eastus2                                                     |

```bash
# Copy template
cp setup.env.example setup.env

# Edit with your environment's values

# Change PROJECT_PREFIX, CONJUR_TENANT, AZURE_TENANT_ID, AZURE_REGION
# Ensure PROJECT_PREFIX is unique, it is used to compute resource names

$EDITOR setup.env
```

### 1. Check Prerequisites

Required commands:

- `go` — [Install](https://go.dev/doc/install)
- `terraform` — [Install](https://developer.hashicorp.com/terraform/install)
- `docker` — [Install](https://www.docker.com/get-started/)
- `kind` — [Install](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- `helm` — [Install](https://helm.sh/docs/intro/install/)
- `task` — [Install](https://taskfile.dev/docs/installation)
- `jq` — [Install](https://jqlang.org/download/)
- `az` (Azure CLI) — [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- `conjur` (Secrets Manager CLI) — [Install (SaaS)](https://docs.cyberark.com/secrets-manager-saas/latest/en/content/conjurcloud/cli/cli-setup-new.htm)

The bootstrap script will check that the required commands are available

```bash
bash ./scripts/bootstrap.sh
```

### 2. Download SWA Binaries

Download binaries from the marketplace and place the tarball in the `./dist` directory.

NOTE: if you have a zip file, unzip it to extract the swa-release tarfile.

Once the tarfile is in `./dist` then run the prep script.

```bash
# Extract the tarball into swa-release dir
task swa:extract
task swa:prep

# ONLY if on a mac and running terraform locally, you may need to clear the quarantine attr
task swa:mac-fix-tf-provider
```

### 3. Deploy Everything to a kind cluster

```bash
task deploy-all
```

---

## File Structure

```text
swa-aure-demo/
├── Taskfile.yml                    # Task orchestration 
├── setup.env.example               # Environment template
├── setup.env                       # Your config (git-ignored)
├── app/                            # Go application
├── terraform/                      # Infrastructure as Code
│   └── environments/azure/         # Setup Azure resources
│   └── environments/kind/          # Setup Kind cluster
│   └── environments/swa-provider/  # Setup swa-provider
└── scripts/                        # Task scripts
└── dist/                           # Dir for swa-release tarfile
```
