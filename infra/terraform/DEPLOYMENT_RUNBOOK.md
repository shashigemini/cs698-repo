# CS698 Terraform Deployment Runbook

## Terraform backend governance

### State key policy (must remain constant)

- This stack uses a **single, fixed backend key**: `cs698/terraform.tfstate`.
- The deployment workflow enforces this value and fails if a conflicting `TF_STATE_KEY` secret is present.
- Required backend inputs:
  - `TF_STATE_BUCKET` (GitHub secret)
  - `TF_STATE_REGION` (GitHub secret)
  - `TF_STATE_KEY` (workflow constant, not environment-specific)

### Auditability requirements in CI

The GitHub Actions workflow (`.github/workflows/deploy-aws-ec2.yml`) performs the following before apply:

1. Validates backend values are present and state key is unchanged.
2. Prints effective backend settings (`bucket`, `key`, `region`) in logs.
3. Runs `terraform plan -detailed-exitcode` and emits plan summary to logs.
4. Applies only the reviewed plan file when changes are present.

## Orphan EC2 cleanup procedure

Use this to detect and safely remove EC2 instances that should belong to this stack but are no longer in Terraform state.

### Scope

The cleanup script compares:

- Instances tagged `ManagedBy=Terraform`
- Instances named `cs698-app-server` that do **not** have `ManagedBy=Terraform`
- IDs currently tracked in Terraform state (`terraform show -json`)

It treats as orphan any instance that is:

- Name-tagged `cs698-app-server`
- missing `ManagedBy=Terraform`
- absent from Terraform state

### Prerequisites

From `infra/terraform/`:

- Terraform initialized to the correct backend/workspace.
- AWS CLI authenticated to the target account.
- `jq` installed.

### Audit run (no termination)

```bash
./scripts/cleanup_orphan_ec2.sh --region us-east-1
```

This prints:

- Terraform-managed instance IDs from state
- ManagedBy-tagged live instances
- Untagged `cs698-app-server` instances
- Confirmed orphan IDs

### Termination run (explicit confirmation required)

```bash
./scripts/cleanup_orphan_ec2.sh --region us-east-1 --execute
```

Safety controls:

- Default mode is read-only audit.
- `--execute` is required to terminate.
- Interactive confirmation string (`terminate-orphans`) is required before termination.

### Post-cleanup verification

1. Re-run audit mode and confirm zero confirmed orphans.
2. Run `terraform plan` to ensure state and infrastructure are aligned.
3. Confirm service health endpoint if deployment instance changed.
