# ADR 0002: Integration Testing Robot Pattern

## Status
Accepted

## Context
Integration tests often become brittle and unreadable when UI finders and interactions are mixed directly into the test logic. As the UI changes, tests break in multiple places.

## Decision
We adopt the **Robot Pattern** for all integration and complex widget tests.

### Rationale
- **Separation of Concerns**: Robots handle the "How" (finding buttons, entering text), while tests handle the "What" (user flows).
- **Reusability**: `AuthRobot` can be reused across multiple test files.
- **Maintainability**: If a button's key changes, only one method in the robot needs updating, rather than every test case.

## Consequences
- Requires creating a Robot class for each major feature area.
- Tests become slightly more verbose in setup but much clearer in execution.
