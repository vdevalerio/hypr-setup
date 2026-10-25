---
name: forge-skills
description: Generate lean, repo-specific skills for the current repository (build/test/run commands, conventions, gotchas) under .claude/skills/. Use when starting work in a repo that has no forged skills yet, or when asked to "forge skills".
disable-model-invocation: true
---

# forge-skills

Create a small set of **lean** skills for the repository in the current directory, so future sessions
start with the repo's real commands and conventions instead of re-exploring it.

## Rules
- Nothing is written outside `<repo>/.claude/skills/` and `<repo>/.git/info/exclude`.
- Never touch tracked files, never commit. Forged skills stay local: add `.claude/skills/` to
  `.git/info/exclude` (not `.gitignore`) if it is not already there and the repo has no tracked `.claude/skills`.
- Keep every SKILL.md under ~60 lines. Facts only, each one verified in the repo (cite `path:line`).
  No generic advice ("write clean code"), nothing already obvious from file names.
- Do not call the `growth_opera` tools; this is tooling work, not ticket work.

## Steps
1. **Explore cheaply.** Delegate to the `pesquisador` agent: root layout, languages, package manager,
   how to build / test / lint / run, entry points, folder conventions, CI config. Also read
   `README`, `CLAUDE.md` and `git log --oneline -20` for commit style and branch naming.
2. **Read friction history.** If `~/.claude/forge/friction/<repo-slug>.jsonl` exists (slug = repo root
   path without the leading `/`, non-alphanumerics replaced by `-`), summarise recurring failures; each
   one is a candidate for a gotcha.
3. **Pick 2-4 skills**, only those that carry real information, for example:
   - `<repo>-workflow`: build/test/lint/run commands, branch and commit conventions.
   - `<repo>-architecture`: where things live, data flow, entry points.
   - `<repo>-gotchas`: verified pitfalls and their fixes (from friction history and code reading).
   Skip a skill if you would have to invent its content.
4. **Write each** to `.claude/skills/<repo>-<topic>/SKILL.md` with frontmatter
   `name`, a `description` that says *when* to use it, and a final line
   `<!-- forged-by: forge-skills v1 · YYYY-MM-DD -->` (used by /retro to find forged skills).
5. **Report** in a few lines: skills created, one line each, and what you could not verify.
   Suggest `/retro` after a few sessions to refine them.

## Self-improvement
This skill improves only through `/retro`, which proposes diffs to this file and to the forged
skills. Changes are applied only after the user approves the diff. Never edit this file on your own.
