---
description: Detect the project's stack and run its test suite (example of detect-and-dispatch pattern)
---

This command demonstrates the **detect-and-dispatch** pattern: one stack-agnostic command, dispatching to stack-specific tooling at runtime.

Steps:

1. **Detect stack** by looking at marker files in the repo root (and one level deep for monorepos):

   | Marker file | Stack | Default test command |
   |---|---|---|
   | `package.json` | node | `npm test` (or `pnpm test` / `yarn test` if lockfile matches) |
   | `Cargo.toml` | rust | `cargo test` |
   | `go.mod` | go | `go test ./...` |
   | `pyproject.toml` or `pytest.ini` | python | `pytest` |
   | `Gemfile` | ruby | `bundle exec rspec` (or `rake test`) |
   | `pubspec.yaml` | flutter | `flutter test` |
   | `pom.xml` / `build.gradle*` | jvm | `mvn test` / `gradle test` |
   | `Package.swift` | swift | `swift test` |

2. **Override**: if `.claude/test.sh` exists in the project, use that instead — it's the project's explicit override.

3. **Confirm** the chosen command in one line, then run it.

4. **If multiple stacks detected** (monorepo), ask which one — don't guess.

5. **If no marker found**, say so and ask the user for the test command.

Args ($ARGUMENTS): if provided, treat as a filter / scope passed to the test runner (e.g. `/stack-test auth` → `npm test -- auth` or `cargo test auth`).

This pattern generalizes — copy this command structure for `/stack-build`, `/stack-lint`, `/stack-format`, etc.
