# /dev-go — Scope Check Then Ship (generic)

Runs `/dev-scope` first, then `/dev-ship` if the scope looks right. No GLBA.
Works on any project — Node, Ruby, Python, Go, Rust.

Check `$ARGUMENTS` for flags. Route them:
- `--branch <name>`, `--quiet`, `--explain` → scope phase
- `--dry-run`, `--push`, `--skip-build`, `--skip-security` → ship phase (passed through)

---

## Step 1: Scope Analysis

Read `~/.claude/commands/dev-scope.md` and follow its instructions with applicable flags.

Capture the verdict: `ONE PR (CLEAN)`, `ONE PR (CAUTION)`, or `SPLIT INTO N PRs`.

---

## Step 2: Decision

### ONE PR (CLEAN)

Print:
```
Scope: clean. Proceeding to ship.
```

Read `~/.claude/commands/dev-ship.md` and follow its instructions with applicable flags.

---

### ONE PR (CAUTION)

Print the caution notes from the scope output.

Ask: **"Proceed to dev-ship despite the notes? (yes / no)"**

- Yes → follow `dev-ship.md` with applicable flags.
- No → stop. Print: "Stopped at scope. Run `/dev-ship` manually when ready."

---

### SPLIT INTO N PRs

Print the full split recommendation.

Stop. Print:
```
Scope recommends splitting before shipping.
Restructure the commits, then run /dev-ship (or /dev-go) on each branch.
```

---

## Tips

- Add a `## Scope Map` section to your project's `CLAUDE.md` for more accurate scope analysis.
- `/dev-go --branch <name>` is useful to analyze a branch before you start working on it.
- `/dev-go --dry-run` runs all checks without committing — good for CI or first-time use.

---

## Flags Reference

| Flag | Phase | Effect |
|------|-------|--------|
| `--branch <name>` | Scope | Analyze that branch vs default |
| `--quiet` | Scope | Verdict only |
| `--explain` | Scope | Verbose signal reasoning |
| `--dry-run` | Ship | All gates, nothing committed |
| `--push` | Ship | Push + open PR on success |
| `--skip-build` | Ship | Skip build step |
| `--skip-security` | Ship | Skip /cso |
