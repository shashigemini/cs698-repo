#!/usr/bin/env bash
set -euo pipefail

# Finds EC2 instances that look like this stack but are not tracked by Terraform state.
# Default mode is audit-only. Use --execute to terminate confirmed orphan instances.

STACK_NAME="cs698-app-server"
AWS_REGION="${AWS_REGION:-us-east-1}"
EXECUTE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--region <aws-region>] [--execute]

Options:
  --region <aws-region>   AWS region to inspect (default: ${AWS_REGION})
  --execute               Terminate orphan instances after interactive confirmation.
  -h, --help              Show this help.

Definition of orphan in this script:
  - EC2 instance has Name=${STACK_NAME}, and
  - is NOT tagged ManagedBy=Terraform, and
  - is NOT referenced by Terraform state for this workspace.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --execute)
      EXECUTE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required."
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required."
  exit 1
fi

echo "Refreshing Terraform state metadata..."
terraform state pull >/dev/null

echo "Collecting Terraform-managed EC2 instance IDs from state..."
mapfile -t TF_INSTANCE_IDS < <(
  terraform show -json | jq -r '
    [.values.root_module.resources[]?, (.values.root_module.child_modules[]?.resources[]?)]
    | flatten
    | .[]
    | select(.type == "aws_instance")
    | .values.id
    | select(. != null and . != "")
  '
)

echo "Terraform state contains ${#TF_INSTANCE_IDS[@]} EC2 instance(s)."
for id in "${TF_INSTANCE_IDS[@]:-}"; do
  [[ -n "$id" ]] && echo "  - $id"
done

TF_IDS_FILE="$(mktemp)"
printf '%s\n' "${TF_INSTANCE_IDS[@]:-}" | sed '/^$/d' | sort -u > "$TF_IDS_FILE"

echo

echo "Querying tagged instances (ManagedBy=Terraform)..."
mapfile -t TAGGED_TF_IDS < <(
  aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:ManagedBy,Values=Terraform" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    | jq -r '.Reservations[].Instances[].InstanceId'
)

echo "Tagged ManagedBy=Terraform instances: ${#TAGGED_TF_IDS[@]}"
for id in "${TAGGED_TF_IDS[@]:-}"; do
  [[ -n "$id" ]] && echo "  - $id"
done

echo

echo "Querying ${STACK_NAME} instances that are NOT tagged ManagedBy=Terraform..."
mapfile -t UNTAGGED_STACK_IDS < <(
  aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=${STACK_NAME}" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    | jq -r '
      .Reservations[].Instances[]
      | select(((.Tags // []) | any(.Key == "ManagedBy" and .Value == "Terraform")) | not)
      | .InstanceId
    '
)

echo "Untagged ${STACK_NAME} instances: ${#UNTAGGED_STACK_IDS[@]}"
for id in "${UNTAGGED_STACK_IDS[@]:-}"; do
  [[ -n "$id" ]] && echo "  - $id"
done

echo

ORPHAN_IDS=()
for id in "${UNTAGGED_STACK_IDS[@]:-}"; do
  [[ -z "$id" ]] && continue
  if ! grep -Fxq "$id" "$TF_IDS_FILE"; then
    ORPHAN_IDS+=("$id")
  fi
done

echo "Confirmed orphan instances (untagged + not in Terraform state): ${#ORPHAN_IDS[@]}"
for id in "${ORPHAN_IDS[@]:-}"; do
  [[ -n "$id" ]] && echo "  - $id"
done

if [[ ${#ORPHAN_IDS[@]} -eq 0 ]]; then
  echo "No orphan instances found."
  exit 0
fi

if [[ "$EXECUTE" != true ]]; then
  echo
  echo "Audit only. Re-run with --execute to terminate the orphan instances above."
  exit 0
fi

echo
read -r -p "Type 'terminate-orphans' to confirm termination of ${#ORPHAN_IDS[@]} instance(s): " CONFIRM
if [[ "$CONFIRM" != "terminate-orphans" ]]; then
  echo "Confirmation string mismatch. Aborting termination."
  exit 1
fi

echo "Terminating orphan instances..."
aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids "${ORPHAN_IDS[@]}" >/dev/null

echo "Termination request submitted for:"
printf '  - %s\n' "${ORPHAN_IDS[@]}"
