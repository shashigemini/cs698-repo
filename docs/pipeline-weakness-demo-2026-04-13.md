# Pipeline Weakness Demo

Date: 2026-04-13

This branch is an explicit red-team classroom exercise. It does not try to hide intent. The purpose is to show that the current CI gates are narrow enough that a harmless backend source change outside the covered files can still pass the advertised backend checks.

## Change used for the demo

File changed: `backend/app/api/chat_router.py`

The code change is a no-op refactor:

- extracted the conversation list pagination defaults into module constants
- kept the endpoint behavior unchanged

## What this demonstrates

The repository's generic backend smoke-test workflow currently runs only:

- `tests/test_security.py`
- `tests/test_auth_service.py`

That means a change in `backend/app/api/chat_router.py` is outside the workflow's effective scope unless another broader workflow or repo setting blocks it.

## Expected lesson

If the current checks pass on this branch, that is evidence that:

1. the workflow names overstate their protective coverage
2. backend routing and API behavior are not comprehensively gated in CI
3. required checks should be upgraded to full-suite verification rather than targeted smoke tests

## Safe follow-up

After the exercise, the recommended remediation is:

1. replace the narrow smoke-test workflows with full backend and frontend suites
2. add analysis and build verification
3. make those checks required before merge
