## Nushell Testing Conventions

Always adhere to the established testing patterns in this directory.

- **Library**: Every script must start with `use _lib.nu *`.
- **Logic**: Encapsulate test cases in functions that return lists of result records.
- **Reporting**: Use the `audit` runner in `main` for individual scripts.
- **Master Runners**: Use the `orchestrate` helper for scripts that aggregate multiple test files.
- **Dependencies**: Use `skip` for missing optional tools/dependencies. Do not let missing tools cause a "Pass" or "Fail" state if the test simply cannot run.
- **Just Interface**: When adding a new test suite, also add a corresponding recipe in `scripts/tests.just`.

Refer to `docs/nu-scripting.md` for the full technical specification.
