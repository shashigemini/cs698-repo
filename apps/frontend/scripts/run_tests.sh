#!/usr/bin/env bash
# apps/frontend/scripts/run_tests.sh
# Runs P5 frontend unit tests with coverage

set -e

# Navigate to frontend directory
cd "$(dirname "$0")/.."

echo "========================================"
echo " Running Frontend P5 Unit Tests"
echo "========================================"

# Run only the two targeted test files
flutter test \
  test/core/services/cryptography_service_test.dart \
  test/features/chat/application/chat_controller_test.dart \
  --coverage

python3 -c "
import sys

TARGETS = {
    'lib/core/services/cryptography_service.dart',
    'lib/features/chat/application/chat_controller.dart'
}

try:
    with open('coverage/lcov.info') as f:
        data = {k: {'t': 0, 'c': 0} for k in TARGETS}
        curr = None
        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                curr = line[3:]
            elif curr in TARGETS and line.startswith('DA:'):
                parts = line[3:].split(',')
                data[curr]['t'] += 1
                if int(parts[1]) > 0:
                    data[curr]['c'] += 1

    print('')
    print('---------- frontend coverage ----------')
    print(f'{\"Name\":<30} {\"Stmts\":>6} {\"Miss\":>6} {\"Cover\":>6}')
    print('-' * 51)
    
    tt, tm = 0, 0
    # sort by name for consistent table rendering
    for fname in sorted(TARGETS):
        t = data[fname]['t']
        c = data[fname]['c']
        m = t - c
        pct = int((c / t * 100)) if t > 0 else 0
        tt += t
        tm += m
        print(f'{fname.split(\"/\")[-1]:<30} {t:>6} {m:>6} {pct:>5}%')
            
    print('-' * 51)
    t_pct = int(((tt - tm) / tt * 100)) if tt > 0 else 0
    print(f'{\"TOTAL\":<30} {tt:>6} {tm:>6} {t_pct:>5}%')

except Exception as e:
    print(f'Coverage report failed: {e}')
"

echo ""
echo "Frontend P5 Tests: ✅ SUCCESS"
