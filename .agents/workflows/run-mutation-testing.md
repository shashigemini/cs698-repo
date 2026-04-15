---
description: How to run mutation testing and analyze the results
---
# Running Mutation Tests

Mutation testing introduces deliberate faults (mutations) into your codebase and runs your test suite to ensure the tests catch them. The goal is to verify the *quality* of your tests.

### 1. Execute the Automated Script
Instead of running `mutmut` directly, use the wrapper script we created. This ensures the environment is clean, executes the tests, and formats the output into a readable markdown report.

```bash
cd /workspaces/cs698-repo/apps/backend
./scripts/run_mutation_tests.sh
```

### 2. Analyze the Results
Once the script completes, open the generated report to review how your test suite performed:
- **[mutation_report.md](file:///workspaces/cs698-repo/apps/backend/mutation_report.md)**: Contains the survival statistics (Killed vs Survived) and a line-by-line breakdown of exactly which faults survived.

If you encounter unexpected failures, you can check the raw diagnostic output:
- `apps/backend/mutmut_log.txt`
- `apps/backend/mutmut_error.log`

### 3. Adding New Modules
If you want to add new modules to the mutation testing suite, edit the `paths_to_mutate` array inside **`apps/backend/pyproject.toml`**.

**Best Practices for Target Selection:**
- **DO Include:** Business logic (`app/rag/`, `app/core/security.py`), isolated Repositories (`user_repo.py`), and pure Services.
- **DO NOT Include:** Infrastructure boilerplate (`app/main.py`, `app/config.py`) or raw connection handlers (`database.py`, `redis_client.py`). Because the tests mock the real connections using an isolated SQLite in-memory database and an `AsyncMock` for Redis, mutating the real infrastructure files will result in meaningless "survived" noise.

### Architectural Context for Agents
- The mutation sandbox fundamentally alters file paths for tests. We use `also_copy = ["app/"]` in `pyproject.toml` so `mutmut` populates its isolated testing sandbox intelligently, avoiding `ModuleNotFoundError`s.
- `conftest.py` sets up `db_session` and `mock_redis`. It natively provides an isolated SQLite backend so that hundreds of mutations can be tested sequentially without waiting for Docker containers or leaving orphaned state rows.

### Gotchas & Troubleshooting
- **"not checked" Mutants**: If your mutation report shows 100% of mutants as `not checked` or the total testing completes in just a few seconds, it guarantees the baseline test run failed and `mutmut` aborted. 
- **`tests_dir` in `pyproject.toml` Parsing Error**: Do NOT set `tests_dir = "tests/"` inside `[tool.mutmut]` in `pyproject.toml`. The `mutmut` TOML parser interprets the string as a list of characters (attempting to run tests in directories named `t`, `e`, `s`, `t`, `s`, `/` and subsequently crashing the baseline run). Because "tests" is the default anyway, omit the key entirely.
- **Always Use Poetry**: Mutation testing commands must be wrapped in `poetry run` (e.g. `poetry run mutmut run`) inside shell scripts to guarantee the correct virtual environment boundaries.
- **Weak Assertions = Survival**: `mutmut` will punish tests that lack strict specificity. To kill survivors effectively:
  - Assert exact exception messages using `pytest.raises(Error, match="exact string")`.
  - Assert mocked method parameters (e.g., `mock.assert_called_with(object)`).
  - Explicitly test default argument branches (e.g. function calls with omitted arguments).
  - Test underlying logs via the `caplog` fixture to guarantee errors are being logged correctly.
