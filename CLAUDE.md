# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is a personal collection of authored agent skills (Claude Code / Claude Agent SDK skills), published at `github.com/jmmorillon/jmm-agent-skills`. Content is Markdown — no build, lint, or test toolchain.

## Installation script (`install.sh`)

The installer is symlink-based and idempotent. Two modes:

- `./install.sh --global` — per-skill symlinks at three levels:
  1. `~/.agents/skills/<name>` → `<repo>/skills/<name>` (the hub, absolute target)
  2. `~/.claude/skills/<name>` → `../../.agents/skills/<name>` (relative target, for portability)
  3. `~/.copilot/skills/<name>` → `../../.agents/skills/<name>`
- `./install.sh --local [chemin]` — for project-scoped installs. Creates `<chemin>/.claude/skills/<skill>` and `<chemin>/.copilot/skills/<skill>` as direct symlinks to this repo's skills (default `chemin` = cwd). No hub layer locally.
- Append `--uninstall` to either mode to remove only the symlinks this repo would have created. Symlinks pointing elsewhere and real files are skipped (never deleted).

**Why per-skill symlinks rather than a single directory-level symlink:** the user's setup already populates `~/.claude/skills/` and `~/.copilot/skills/` with per-skill symlinks pointing into `~/.agents/skills/` (e.g. `ccc`, `find-skills`). A directory-level symlink would clobber those. The relative target form `../../.agents/skills/<name>` is used to match the convention already in place — don't switch it to absolute.

**Third-party plugins (`--global` only).** Beyond the personal skills, `--global` also installs a versioned list of third-party Claude Code plugins so the script doubles as a new-machine bootstrap. The list (`THIRD_PARTY_PLUGINS`) and its marketplace (`anthropics/claude-plugins-official`, exposed as `claude-plugins-official`) are declared at the top of `install.sh`; add or remove an entry there. Each is installed with `claude plugin install <name>@claude-plugins-official --scope user` (uninstall via `claude plugin uninstall … --yes`), so plugins are user-scoped and only make sense in `--global` — the `--local` mode never touches them. Notes:

- Requires the `claude` CLI on `PATH`; if absent, plugins are skipped with a warning and the skill symlinks still install.
- `--no-plugins` limits `--global` to skill symlinks only (no plugin install/uninstall).
- `./install.sh --update-plugins` is a third, standalone mode (no `--global`/`--local`, and it rejects `--uninstall`/`--no-plugins`): it refreshes the marketplace (`claude plugin marketplace update`) then runs `claude plugin update <name>@claude-plugins-official --scope user --json` on each listed plugin. It touches no symlink and needs no `skills/` directory, so the script can be run from a copy anywhere. It updates only — a plugin in the list but not installed is reported as `warn … (not_found)`, never installed; installing is `--global`'s job. `claude plugin update` takes one plugin at a time (there is no `--all`), hence the loop. Claude Code must be restarted for updates to apply.
- Parsing is done with a `json_field` sed helper, not `jq` (no new dependency). It reads flat string fields of the `--json` line — `updateOutcome` (`up_to_date` vs updated), `oldVersion`, `newVersion`, `failureCode`. It is not a JSON parser: it breaks on a value containing an escaped quote, which is why failures report `failureCode` and not `message` (whose text embeds `\"`).
- Idempotent: re-adding a known marketplace or re-installing a present plugin returns a benign error that is absorbed (`|| true` / `if…then`), so re-running is safe. Because `set -e` is active, gate the calls with `if [ … ]; then … fi`, never `[ … ] && …` (a false test would exit the script).
- Only the *list* is version-controlled; the `~/.claude/plugins/` cache is rebuilt from it and must not be committed.

**Sub-agents (`agents/`).** The repo also versions Claude Code sub-agent definitions as flat `.md` files under `agents/` (frontmatter `name`, `description`, `tools`, `model`, `memory`; body is the system prompt — see `agents/code-improver.md`). They are symlinked like skills but differ in two ways: they are **flat files, not directories**, and they are **Claude Code only** (no Copilot layer, no `~/.agents/` hub). `--global` links each into `~/.claude/agents/<name>.md`; `--local` into `<chemin>/.claude/agents/<name>.md`; `--no-agents` skips them. The same generic `link_skill`/`unlink_skill` helpers back both skills and agents (never overwrite a real file or a foreign symlink). To version a sub-agent that already exists as a real file in `~/.claude/agents/`, move it into `agents/` first, then re-run install so the symlink replaces the original.

## Skill layout

Each skill lives in its own directory under `skills/<skill-slug>/` and ships a `SKILL.md` as its entry point. The frontmatter format used in this repo (see `skills/obsidian-para-sorter/SKILL.md`):

```yaml
---
name: <skill-slug>           # kebab-case, matches the directory name
description: <one-sentence>   # used by Claude to decide when to activate the skill
---
```

The body that follows is the prompt loaded into the agent when the skill activates. Sections observed in the existing skill — "Mission", "Contraintes", "Méthode", "Sortie obligatoire", "Règle finale" — are prescriptive and constrain the agent's output format. When editing or adding a skill, keep that prescriptive style: state the role, the hard constraints (limits, what not to do), the procedure, and the required output shape.

A skill may bundle resources next to its `SKILL.md` for progressive disclosure — most commonly a `references/` directory holding detail loaded only when needed (see `skills/project-docs-sync/references/doc-frameworks.md`, read only once a doc-site framework is detected). Keep `SKILL.md` lean and point to the reference file from the body; the resource stays out of context until the skill actually needs it.

**Paired skills sharing a file contract.** `add-knowledge` and `check-knowledge` are two skills coupled by a convention rather than by code: they read and write the same files in the user's Obsidian vault (a fiche gabarit and an index gabarit), and each `SKILL.md` restates both gabarits **in full**. This duplication is deliberate — a skill is loaded alone into an agent's context and cannot import another one, so factoring the shared blocks out would leave each skill incomplete at execution time. The consequence is the part worth remembering: **any change to a shared gabarit must be mirrored in both files**, and nothing in this repo detects drift. When editing one, diff the corresponding block against the other:

```bash
gab() { awk '/^## Gabarit de fiche/{g=1} g&&/^```markdown/{p=1} p{print} p&&/^```$/{exit}' "$1"; }
diff <(gab skills/add-knowledge/SKILL.md) <(gab skills/check-knowledge/SKILL.md)
```

Compare the **fenced block**, not the whole section: a naive `sed` range over the section reports a false alarm, because each skill legitimately introduces the gabarit with its own framing sentence (`check-knowledge` says it does not author fiches, only corrects them). The fenced blocks and the "Règles de format" lists are what must stay byte-identical.

The design rationale behind these two lives in `docs/superpowers/specs/2026-08-27-knowledge-capture-design.md` — that spec is the authority if the skills and it ever disagree.

**`add-journal` reads its template from the vault, on purpose.** It writes project entries into the `## Track Log` of project notes and, when creating a note, reads `Domaines/Outils/Modèles Obsidian/Modèle Projet.md` live instead of restating it. Don't inline that template into the `SKILL.md`: the user edits it in Obsidian, and a copy would drift silently. Only the entry format (`### AAAA-MM-JJ` + bullets) is owned by the skill.

**Description optimization doesn't work for vault skills.** skill-creator's `run_loop.py` runs `claude -p` from this repo, where the vault is absent; the agent answers directly instead of opening the skill, so recall stays near zero whatever the description. For `add-journal` all 5 iterations tied — judge triggering in real sessions instead.

## Conventions

- **Author language is French.** The existing skill is written in French; preserve that voice when editing it. New skills may be French or English, but match the language to the skill's intended audience.
- **Skill directory naming.** Plain kebab-case `<topic>-<purpose>`, no personal prefix (e.g. `obsidian-para-sorter`, `bruno-api-collection`). The frontmatter `name:` matches the directory name exactly.
- **Hard limits in the prompt itself.** The existing skill enforces a 20-note batch limit by stating it both in "Contraintes" and re-asserting it in the closing "Règle finale". When a skill has a non-obvious cap or guardrail, repeat it at the end so the agent doesn't drift past it.

## When adding a new skill

1. Create `skills/<slug>/SKILL.md` with the frontmatter above.
2. There is no central index or registry to update — discovery is by directory listing.
3. No tests to run; verify by invoking the skill in a Claude Code session and confirming the output matches the "Sortie obligatoire" / required-output section.
