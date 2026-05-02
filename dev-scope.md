# /dev-scope — PR Scope Analyzer (generic)

Analyzes a diff and recommends whether to ship as one PR or split into several.
Works on any project. Read-only — never modifies files or staging area.

Check `$ARGUMENTS` for flags:
- `--branch <name>` — diff that branch vs the repo's default branch
- `--commits <n>` — analyze the last n commits on the current branch
- `--quiet` — verdict line only
- `--explain` — verbose reasoning per signal
- Default — uncommitted + staged changes vs HEAD

---

## Step 1: Gather the Diff

```bash
# Default:
git diff HEAD --stat && git diff HEAD --name-only

# --branch <name>:
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
git diff $BASE...<name> --stat && git diff $BASE...<name> --name-only

# --commits <n>:
git log -n <n> --oneline
git diff HEAD~<n>...HEAD --stat && git diff HEAD~<n>...HEAD --name-only
```

**Stop early if:**
- No changes → "Nothing to scope. Working tree is clean."
- Single file changed → short verdict, skip full analysis
- Only lockfiles / generated files (`*.lock`, `package-lock.json`, `build/`, `dist/`, `.next/`) → note them; they ride along with whatever produced them

---

## Step 2: Classify Files (Trunk / Branch / Leaf)

**First: check CLAUDE.md for a project-defined mapping.**
Look for a section like `## Scope Map`, `## Trunk / Branch / Leaf`, or `## Module Structure`. If found, use those definitions. If not found, fall back to heuristics:

**TRUNK heuristics (cross-cutting, used by many modules):**
- Root-level `middleware.*`, `app.*, `main.*`, `index.*`
- Directories: `lib/`, `core/`, `shared/`, `common/`, `utils/`, `types/`, `helpers/`
- Auth/permission files: any file with `auth`, `permission`, `policy`, `session`, `token` in the name
- Database/ORM layer: `db/`, `database/`, `schema.*`, `models/` (if not feature-specific)
- Config: `config/`, `env.*`, `settings.*`

**BRANCH heuristics (feature-area, semi-independent):**
- Named feature directories: `features/<name>/`, `modules/<name>/`, `app/<feature>/`, `pages/<feature>/`
- Domain-specific service directories: `services/<domain>/`, `api/<domain>/`

**LEAF heuristics (isolated, minimal dependencies):**
- Individual route files, page components, email templates
- One-off scripts, migration files (unless they touch schema directly)
- Test files, docs, config files (`tsconfig.json`, `vitest.config.ts`, `Makefile`, etc.)
- Changelog, version files, lockfiles

---

## Step 3: Run Six Signals

**Signal A — Multiple unrelated feature domains touched.**
Flag if 2+ distinct branch-level directories are modified with no shared new trunk dependency linking them.

**Signal B — Mixed change types without supporting relationship.**
Classify each file: `feature` / `fix` / `refactor` / `test` / `chore` / `docs`. Flag if more than one type appears where the types don't support each other (feature + its own tests = fine; feature + unrelated bugfix = flag).

**Signal C — Leaf or branch change also touching trunk.**
Flag if trunk files (auth, permissions, core types, central config) were modified alongside predominantly branch/leaf-level work. Name the specific trunk files.

**Signal D — Cannot write a single commit message without "and".**
Attempt: `<type>(<scope>): <subject>`. If the subject requires "and" to link unrelated things, flag it and show the candidate messages.

**Signal E — Mixed risk profiles.**
High-risk: auth files, permission files, database schema, dependency updates, security-relevant utilities. Flag if high-risk changes are bundled with low-risk changes (copy tweaks, styling, comments).

**Signal F — Review urgency.**
If high-risk files are present, ask once: "Are any of these changes time-sensitive (security fix, blocking bug)?" If yes, flag urgency candidates.

---

## Step 4: Cohesion (Suppress Splitting)

Hold the split if:
- All changes serve one user-visible outcome
- A new function and its only call site are both in the diff
- A new type and the code that uses it are both in the diff
- Tests are alongside the code they cover
- Splitting would produce a non-compiling intermediate state

---

## Step 5: Verdict

- **ONE PR (CLEAN):** No signals, or all suppressed by cohesion
- **ONE PR (CAUTION):** 1–2 weak signals; shippable but worth noting
- **SPLIT INTO N PRs:** 2+ confirmed signals, or any Signal C or E hit

For split: group files into proposed PRs with name, file list, draft commit message, rationale, and shipping order.

---

## Output

```
Dev Scope — [source]
==============================================
Files: N  |  Lines: +X / -Y  |  Primary area: [area]
Trunk/Branch/Leaf map: [CLAUDE.md custom | heuristic]

Signals:
[!] A: [description]
[ ] B: not detected
...

Verdict: ONE PR (CLEAN) | ONE PR (CAUTION) | SPLIT INTO N PRs
[reasoning / proposed split]
```

**Add a `## Scope Map` section to CLAUDE.md** to define your project's own trunk/branch/leaf mapping and get more accurate analysis than the generic heuristics.
