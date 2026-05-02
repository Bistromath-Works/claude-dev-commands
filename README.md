# claude-dev-commands

Three Claude Code slash commands that give any project a scope-check + pre-commit pipeline. Language-agnostic — works with Node, Ruby, Python, Go, Rust, or anything with a build system.

## Commands

### `/dev-scope` — PR scope analyzer

Analyzes your diff and recommends whether to ship as one PR or split into several. Read-only — never touches your files or staging area.

```
/dev-scope
/dev-scope --branch feature/my-branch
/dev-scope --commits 3 --explain
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--branch <name>` | Diff that branch vs the repo's default branch |
| `--commits <n>` | Analyze the last n commits on the current branch |
| `--quiet` | Verdict line only |
| `--explain` | Verbose reasoning per signal |

---

### `/dev-ship` — pre-commit gate

Runs typecheck → lint → tests → security audit → code review → build → commit. Each step is gated: a failure stops the pipeline and tells you exactly what to fix.

```
/dev-ship
/dev-ship --dry-run
/dev-ship --push
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--dry-run` | Run all gates, no staging/commit/push |
| `--push` | Push + open PR after a successful commit |
| `--skip-build` | Skip the build step |
| `--skip-security` | Skip `/cso` (use on a known-clean diff) |

---

### `/dev-go` — scope check then ship

Runs `/dev-scope` first. If the scope is clean, proceeds to `/dev-ship` automatically. If scope returns CAUTION, asks before proceeding. If it recommends a split, stops and tells you how to restructure.

```
/dev-go
/dev-go --dry-run
/dev-go --push
/dev-go --branch feature/my-branch --explain
```

**Flags:**

| Flag | Phase | Effect |
|------|-------|--------|
| `--branch <name>` | Scope | Analyze that branch vs default |
| `--quiet` | Scope | Verdict only |
| `--explain` | Scope | Verbose signal reasoning |
| `--dry-run` | Ship | All gates, nothing committed |
| `--push` | Ship | Push + open PR on success |
| `--skip-build` | Ship | Skip build step |
| `--skip-security` | Ship | Skip `/cso` |

---

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- [gstack](https://garryslist.org) installed — required for the `/cso` security audit and `/review` code review steps in `/dev-ship`

If gstack is not installed, pass `--skip-security` to skip the `/cso` step.

---

## Installation

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/ArthurDentsTowel/claude-dev-commands/main/install.sh | bash
```

This copies `dev-scope.md`, `dev-ship.md`, and `dev-go.md` into `~/.claude/commands/`.

**Manual install:**

```bash
cp dev-scope.md dev-ship.md dev-go.md ~/.claude/commands/
```

---

## Customizing scope analysis

`/dev-scope` classifies files as Trunk, Branch, or Leaf to detect when a diff mixes concerns that should be separate PRs. By default it uses generic heuristics (`lib/`, `auth`, `schema.*`, etc.).

For more accurate results, add a `## Scope Map` section to your project's `CLAUDE.md`:

```markdown
## Scope Map

**Trunk** (cross-cutting — flag when mixed with branch/leaf work):
- `src/lib/`, `src/types/`, `src/middleware.ts`
- Any file with `auth`, `permissions`, or `schema` in the path

**Branch** (feature areas — independent of each other):
- `src/app/dashboard/`, `src/app/settings/`, `src/app/reports/`

**Leaf** (isolated — fine to bundle with their parent branch):
- Individual route files, email templates, migration files, test files
```

When a `## Scope Map` section is present, `/dev-scope` uses your definitions instead of the heuristics.

---

## How this differs from gstack `/ship`

`/dev-ship` is a pre-commit gate, not a full ship workflow.

| | `/dev-ship` | gstack `/ship` |
|--|-------------|----------------|
| Typecheck / lint / tests | ✓ | ✓ |
| Security audit | ✓ | ✓ |
| Code review | ✓ | ✓ |
| Commit | ✓ | ✓ |
| Version bump | — | ✓ |
| CHANGELOG update | — | ✓ |
| PR creation | optional (`--push`) | ✓ |

Use `/dev-ship` (or `/dev-go`) as a pre-commit gate during development. Use `/ship` when you're ready to formally land a release with a version bump and changelog entry.

---

## License

MIT — see [LICENSE](LICENSE).
