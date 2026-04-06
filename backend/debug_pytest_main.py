import pytest
import sys
import os

# Emulate mutmut's setup
sys.path.insert(0, os.getcwd())
print(f"PYTHONPATH: {sys.path}")
print(f"CWD: {os.getcwd()}")

# Run the exact command mutmut tried
args = ['-vv', '--rootdir=.', '--tb=native', '-x', '-q', 'tests/test_trivial.py']
ret = pytest.main(args)
print(f"EXIT CODE: {ret}")
