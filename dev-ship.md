# /dev-ship — Pre-Commit Gate (generic)

A pre-commit pipeline for any project. No GLBA. No mortgage compliance.
Just typecheck, lint, tests, security, code review, build, commit.

Check `$ARGUMENTS` for flags:
- `--dry-run` — run all gates, no staging/commit/push
- `--push` — push + open PR after commit
- `--skip-build` — skip the build step
- `--skip-security` — skip /cso (use when running on a known-clean diff)

There is intentionally no flag to skip the security gate unless explicitly passed.

---

## Step 1: Verify Working State

Run `git branch --show-current` and `git status --short`.

- If on `main` or `master`: abort — "Cannot ship from the default branch."
- If no changes: abort — "Nothing to commit."
- Print the branch name and changed file count.

---

## Step 2: Detect Stack

```bash
[ -f tsconfig.json ] && echo "TYPESCRIPT: yes" || echo "TYPESCRIPT: no"
[ -f package.json ] && cat package.json | grep -E '"(test|lint|typecheck|build|check)"' | head -8
[ -f Gemfile ] && echo "RUBY: yes"
[ -f go.mod ] && echo "GO: yes"
[ -f pyproject.toml ] || [ -f requirements.txt ] && echo "PYTHON: yes"
[ -f Cargo.toml ] && echo "RUST: yes"
```

From this, determine the commands for Steps 3–6. Use what's in `package.json` scripts.
If a step has no detected command, skip it and note the skip.

---

## Step 3: Typecheck

**If TypeScript (`tsconfig.json` exists):**
Run `npx tsc --noEmit` (or the `typecheck` / `check` script if present in package.json).

**If Go:** Run `go vet ./...`
**If Rust:** Run `cargo check`
**Otherwise:** Skip — note "No typecheck command detected."

Stop on errors. Do **not** auto-fix type errors.

---

## Step 4: Lint

Run whichever is found first:
- `package.json` script named `lint` → `npm run lint`
- `.rubocop.yml` → `bundle exec rubocop`
- `pyproject.toml` with ruff/flake8 → `ruff check .` or `flake8`
- `go.mod` → `golangci-lint run` (if installed) or skip
- None found → skip, note "No lint command detected."

Auto-fix only if the lint tool's `--fix` flag resolves the issue without changing logic.
For non-auto-fixable errors: stop and report.

---

## Step 5: Tests

Run whichever is found:
- `package.json` script `test` → `npm test`
- `spec/` directory with `.rspec` → `bundle exec rspec`
- `pytest.ini` or `pyproject.toml` with pytest → `pytest`
- `go.mod` → `go test ./...`
- `Cargo.toml` → `cargo test`
- None found → skip, note "No test command detected."

If tests fail: invoke the `superpowers:systematic-debugging` skill on failing tests.
Re-run after each fix. Maximum 3 iterations. If still failing: stop — do not commit broken tests.

---

## Step 6: Security Audit

Invoke the `/cso` skill (unless `--skip-security` flag is set).

Treat HIGH and CRITICAL findings as blocking. MEDIUM and LOW are reported but non-blocking.
Record any files modified by auto-fixes — needed for Step 8.

---

## Step 7: Code Review

Invoke the `/review` skill against the full branch diff.

Auto-fix mechanical issues. Surface judgment calls to the user.
Record files modified by auto-fixes — needed for Step 8.

---

## Step 8: Targeted Re-Review

If Steps 6 or 7 modified any files, re-run `/cso` and `/review` scoped to those files only.
Maximum 2 outer loops. If not converging: stop and surface to user.

If no files were modified in Steps 6–7: print "Re-review skipped — no fixes applied." and continue.

---

## Step 9: Build

Skip if `--skip-build` flag is set.

Run whichever is found:
- `package.json` script `build` → `npm run build`
- `go.mod` → `go build ./...`
- `Cargo.toml` → `cargo build`
- `Makefile` with a `build` target → `make build`
- None found → skip, note "No build command detected."

Do **not** auto-fix build failures. Surface to user.

---

## Step 10: Stage and Commit

Skip if `--dry-run`.

Stage all modified files (`git add -A`).
Read `git diff --cached` to write the commit message from the actual diff — do not rely on session memory.
Generate a conventional commit message. Show it to the user and ask for confirmation.
Commit after confirmation. Do not auto-push unless `--push` is set.

---

## Step 11: PR

If `--push`: push the branch and create a PR. PR body must include:
- Summary of the diff
- Checklist of which gates passed

If no `--push`: ask "Open a PR now? (yes/no)" and act accordingly.

---

## Final Summary

```
Dev Ship Pipeline — [branch]
=====================================
[ ] Typecheck   —
[ ] Lint        —
[ ] Tests       —
[ ] Security    —
[ ] Review      —
[ ] Re-Review   —
[ ] Build       —
[ ] Commit      —
```

Fill each with ✓/✗ and a short note. If `--dry-run`: note "DRY RUN — nothing committed."

---

## Failure Mode

When any gate blocks: print the gate name, finding, file and line. Stop.
Tell the user exactly what must be resolved to unblock.
