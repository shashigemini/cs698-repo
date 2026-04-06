# mutmut — Python Mutation Tester

> Source: https://mutmut.readthedocs.io/en/latest/

Mutmut is a mutation testing system for Python, with a strong focus on ease of use. Mutation testing works by introducing small, deliberate bugs (mutants) into your code and checking whether your tests catch them. If a mutant survives, it means your test suite has a gap.

---

## Key Features

- Apply found mutants to disk with a single command for easy review
- Remembers previous work — supports incremental runs
- Knows which tests to execute for each function, speeding up runs
- Interactive terminal-based UI (TUI)
- Parallel and fast execution

> **Note:** If you want to mutate code outside of functions, use `mutmut 2`, which has a different execution model than `mutmut 3+`.

---

## Requirements

- Must be run on a system with `fork` support.
- **Windows:** must run inside WSL (Windows Subsystem for Linux).

---

## Install and Run

```bash
pip install mutmut
mutmut run
```

- Runs `pytest` against tests in a `tests/` or `test/` folder by default.
- Automatically tries to detect which source code to mutate.
- You can stop at any time — mutmut resumes where it left off.
- Re-tests functions that were modified since the last run.

### Browsing Results

```bash
mutmut browse
```

Interactive TUI where you can:
- View surviving mutants
- Press `r` to retest a mutant after updating tests
- Press `f` to retest a specific function
- Press `m` to retest an entire module
- Write a mutant to disk directly from the UI

### Applying a Mutant to Disk

```bash
mutmut apply <mutant>
```

> **WARNING:** Make sure the file you are mutating is committed to source control before applying a mutant.

---

## Configuration

### `setup.cfg`

```ini
[mutmut]
paths_to_mutate=src/
tests_dir=tests/
```

### `pyproject.toml`

```toml
[tool.mutmut]
paths_to_mutate = ["src/"]
tests_dir = ["tests/"]
```

---

## Configuration Options

### Wildcard Filtering — Run Only Specific Mutants

Unix-style filename pattern matching is supported:

```bash
mutmut run "my_module*"
mutmut run "my_module.my_function*"
```

---

### "Also Copy" Files

Some test setups require extra files beyond the source and test directories. Add them with `also_copy`:

```ini
[mutmut]
also_copy=
    iommi/snapshots/
    conftest.py
```

---

### Limit Stack Depth

Prevents distantly-called functions from being tested by unrelated tests. Helps keep mutation testing fast and test failures meaningful.

```ini
[mutmut]
max_stack_depth=8
```

- **Lower value** → faster runs, more localized tests, but more surviving mutants
- **Higher value** → slower runs, more mutants caught

Use this in large codebases where base functions are called indirectly by many tests.

---

### Exclude Files from Mutation

```ini
[mutmut]
do_not_mutate=
    *__tests.py
```

Supports Unix glob patterns.

---

### Debug / Verbose Output

```ini
[mutmut]
debug=true
```

By default, mutmut suppresses test output for a clean view. Enable `debug` to see full output. Note: failing tests from mutated code are expected and not necessarily errors.

---

## Whitelisting Lines (Suppress Mutation)

Add a `# pragma: no mutate` comment to skip mutation on a specific line:

```python
some_code_here()  # pragma: no mutate
```

**Common use cases:**
- Version strings (no test needed)
- Performance-optimized `break` vs `continue` logic (correct either way, just slower when mutated)

---

## Example Mutations Applied by mutmut

| Original | Mutated |
|----------|---------|
| `0` | `1` |
| `5` | `6` |
| `<` | `<=` |
| `break` | `continue` |
| `continue` | `break` |

The goal is for mutations to be as **subtle** as possible.

- Full mutation list: `node_mutation.py`
- Tests describing mutations: `test_mutation.py`

---

## Recommended Workflow

1. **Run mutmut:**
   ```bash
   mutmut run
   ```
   A full run is preferred, but you can exit early and work with partial results.

2. **Browse surviving mutants:**
   ```bash
   mutmut browse
   ```

3. **Pick a mutant** you want to kill and write a test targeting it.

4. **Retest** the mutant by pressing `r` in the TUI to confirm the kill.

5. **Repeat** until your test suite is robust.

---

## Data & State

Mutmut stores all run data and mutants in the `mutants/` directory.

To start completely fresh:

```bash
rm -rf mutants/
```

---

## Installation Notes

If you get an error about `libcst` requiring a Rust compiler during install:

- Your architecture (e.g., `x86_64-darwin`) lacks a prebuilt binary for `libcst`
- Install `rustc` and `cargo` from the [Rust toolchain](https://www.rust-lang.org/tools/install) before retrying

---

## Contributing

See the official contributing guide on the [mutmut repository](https://mutmut.readthedocs.io/en/latest/).
