---
name: retro
description: Review logged friction (tool failures, user corrections) for the current repo and propose diffs that improve the forged skills, CLAUDE.md, and the forge-skills/retro skills themselves. Use after a few sessions, or when asked for a retrospective.
disable-model-invocation: true
---

# retro

Turn recorded friction into concrete, reviewable improvements. **Propose, never auto-apply.**

## Inputs
- Friction log: `~/.claude/forge/friction/<repo-slug>.jsonl` (written by the `friction-log.mjs` hook;
  slug = repo root without the leading `/`, non-alphanumerics replaced by `-`).
  Each line: `kind` (`tool_failure` | `correction`), `ts`, `session`, and the error or prompt snippet.
- Forged skills: `<repo>/.claude/skills/*/SKILL.md` containing a `forged-by:` marker.
- Meta skills: `~/.claude/skills/forge-skills/SKILL.md` and this file.
- Last retro marker: `~/.claude/forge/retro-state.json` (`{"<slug>": "<ISO ts of last processed entry>"}`).

## Steps
1. Read only log entries newer than the marker. If fewer than ~5 entries, say so and stop.
2. **Cluster** them: same tool+target or same complaint repeated = a pattern. Ignore one-offs.
3. For each pattern, decide the smallest fix and where it belongs:
   - repo fact (command, path, pitfall) → the matching forged skill, or `<repo>-gotchas`;
   - a rule about how Claude should behave in this repo → a line in the repo's `CLAUDE.md` (propose only);
   - the forging process itself was wrong (missed a build command, bloated output, unverified claim)
     → a diff to `~/.claude/skills/forge-skills/SKILL.md`;
   - the retro process was wrong (noisy clustering, bad threshold) → a diff to this file.
4. Show **one unified diff per file**, each with a one-line reason and the evidence (count and example
   entries). Prefer removing or tightening text over adding; keep skills under ~60 lines.
5. Ask which diffs to apply (all / some / none). Apply only the approved ones. Bump the
   `forged-by` date in changed forged skills.
6. Write the marker with the newest processed timestamp, whether or not anything was applied.
7. Never change hooks, settings or permissions from here, and never commit.
