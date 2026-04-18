#!/usr/bin/env bash
# run_mutation_tests.sh
# Automates mutmut run and report generation for project Tier 1 modules.

set -euo pipefail

# Ensure we're in the backend directory
cd "$(dirname "$0")/.."

echo "--------------------------------------------------"
echo "🚀 Starting Mutation Testing Pipeline"
echo "--------------------------------------------------"

# 1. Clean stale sandbox
echo "[1/4] Cleaning stale 'mutants/' directory..."
rm -rf mutants/

# 2. Run mutmut
echo "[2/4] Executing mutmut (this may take several minutes)..."
poetry run mutmut run || true

# 3. Generate summary results
echo "[3/4] Collecting mutation results..."
RESULTS=$(poetry run mutmut results 2>&1 || echo "Error collecting results")

# 4. Create Markdown Report
echo "[4/4] Generating mutation_report.md..."
cat > mutation_report.md <<EOF
# Mutation Testing Report
**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Environment:** Linux (DevContainer)
**Tool:** mutmut v3.5.0

## Overall Summary
\`\`\`
$RESULTS
\`\`\`

## Methodology
- **Targets:** Determined by \`pyproject.toml\` [tool.mutmut]
- **Isolation:** Sandbox environment in \`mutants/\`
- **Protection:** \`MUTANT_UNDER_TEST\` guard in \`conftest.py\`
- **Sandbox Payload:** Full \`app/\` directory copied as dependency layer

## Next Steps
- Review modules with survival rates > 0.
- Enhance test coverage or improve assertions where mutants survived.
EOF

echo "--------------------------------------------------"
echo "✅ Pipeline Complete!"
echo "Report saved to: $(pwd)/mutation_report.md"
echo "--------------------------------------------------"
