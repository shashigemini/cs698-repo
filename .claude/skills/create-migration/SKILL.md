---
name: create-migration
description: Generate an Alembic database migration for this FastAPI project. Handles async SQLAlchemy patterns, ensures downgrade() is implemented, and verifies the migration applies cleanly.
---

Follow these steps to create a database migration:

## Step 1 — Generate the migration

```bash
cd apps/backend
poetry run alembic revision --autogenerate -m "<description of change>"
```

## Step 2 — Review the generated file

Open the newly created file in `apps/backend/alembic/versions/`.

Check:
- `upgrade()` contains the expected changes (new table, new column, index, etc.)
- `downgrade()` is fully implemented — never leave it as `pass`. If downgrade is destructive (drops a column with data), add a comment explaining why.
- For nullable-to-non-nullable changes: ensure existing rows are backfilled before the constraint is added.

## Step 3 — For data migrations

If the migration modifies existing data (not just schema), wrap it:

```python
def upgrade() -> None:
    bind = op.get_bind()
    # Use bind.execute() for data operations
    bind.execute(text("UPDATE users SET ..."))
    # Then apply schema change
    op.alter_column(...)
```

## Step 4 — Apply and verify

```bash
cd apps/backend
poetry run alembic upgrade head
```

Check exit code 0 and no errors. If using the Docker dev environment:

```bash
docker compose -f apps/backend/dev_test/docker-compose.dev.yml exec api poetry run alembic upgrade head
```

## Step 5 — Test downgrade

```bash
cd apps/backend
poetry run alembic downgrade -1
poetry run alembic upgrade head
```

Both should succeed with exit code 0.
