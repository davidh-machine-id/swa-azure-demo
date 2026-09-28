# SWA Azure Demo

## Quick Start

**REQUIRED:** Azure Account with privileges to create resource groups, roles and storage containers

**REQUIRED:** Download swa-release tarfile and put it in the `./dist` directory

- **REQUIRED MINIMUM VERSION:** swa-release `v1.1.4`

Commands to run:

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

# Deploy to kind cluster
task deploy-all-kind
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

- `go` — [Install Docs](https://go.dev/doc/install)
- `terraform` — [Install Docs](https://developer.hashicorp.com/terraform/install)
- `docker` — [Install Docs](https://www.docker.com/get-started/)
- `kind` — [Install Docs](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- `helm` — [Install Docs](https://helm.sh/docs/intro/install/)
- `task` (go-task) — [Install Docs](https://taskfile.dev/docs/installation)
- `jq` — [Install Docs](https://jqlang.org/download/)
- `az` (Azure CLI) — [Install Docs](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- `conjur` (Secrets Manager CLI) — [Install Docs (SaaS)](https://docs.cyberark.com/secrets-manager-saas/latest/en/content/conjurcloud/cli/cli-setup-new.htm)

The bootstrap script will check that the required commands are available

```bash
bash ./scripts/bootstrap.sh
```

### 2. Download SWA Binaries

**REQUIRED MINIMUM VERSION:** swa-release `v1.1.4`

Download binaries from the marketplace and place the tarball in the `./dist` directory.

NOTE: if you have a zip file, unzip it to extract the swa-release tarfile.

Once the tarfile is in `./dist` then run the prep script.

```bash
# Extract the tarball into swa-release dir
task swa:extract
task swa:prep
```

### 3. Deploy Everything to a kind cluster

```bash
task deploy-all-kind
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
