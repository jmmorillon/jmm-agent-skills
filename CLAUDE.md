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

**Third-party plugins (`--global` only).** Beyond the personal skills, `--global` also installs a versioned list of third-party Claude Code plugins (and third-party skills, see below) so the script doubles as a new-machine bootstrap — every one of them through the security audit. The list (`THIRD_PARTY_PLUGINS`) and its marketplace (`anthropics/claude-plugins-official`, exposed as `claude-plugins-official`) are declared at the top of `install.sh`; add or remove an entry there. Each is installed with `claude plugin install <name>@claude-plugins-official --scope user` (uninstall via `claude plugin uninstall … --yes`), so plugins are user-scoped and only make sense in `--global` — the `--local` mode never touches them. Notes:

- Requires the `claude` CLI on `PATH`; if absent, plugins are skipped with a warning and the skill symlinks still install.
- `--no-plugins` skips third-party plugins only (no plugin install/uninstall); `--global` still links the repo's skills and still installs third-party skills — add `--no-third-party-skills` to skip those too.
- `./install.sh --update` (alias `--update-plugins`) is a standalone mode (no `--global`/`--local`; rejects `--uninstall`): it refreshes the marketplace and runs every listed plugin and third-party skill through the audit pipeline (below). It touches no symlink. A listed plugin that isn't installed is reported `warn … (not_found)` and left alone — installing is `--global`'s job — but a skill newly published in a declared source *is* installed (that is what "whole source minus exclusions" means). It needs the repo (`scripts/audit.sh`), so it no longer runs from a lone copy of the script. Claude Code must be restarted for plugin updates to apply.
- JSON is read with `node -e` (the nested `marketplace.json` / `installed_plugins.json` / `~/.agents/.skill-lock.json`), never `jq`. `node` is already required by skills.sh.
- Idempotent: re-adding a known marketplace or re-installing a present plugin returns a benign error that is absorbed (`|| true` / `if…then`), so re-running is safe. Because `set -e` is active, gate the calls with `if [ … ]; then … fi`, never `[ … ] && …` (a false test would exit the script).
- Only the *list* is version-controlled; the `~/.claude/plugins/` cache is rebuilt from it and must not be committed.

**Sub-agents (`agents/`).** The repo also versions Claude Code sub-agent definitions as flat `.md` files under `agents/` (frontmatter `name`, `description`, `tools`, `model`, `memory`; body is the system prompt — see `agents/code-improver.md`). They are symlinked like skills but differ in two ways: they are **flat files, not directories**, and they are **Claude Code only** (no Copilot layer, no `~/.agents/` hub). `--global` links each into `~/.claude/agents/<name>.md`; `--local` into `<chemin>/.claude/agents/<name>.md`; `--no-agents` skips them. The same generic `link_skill`/`unlink_skill` helpers back both skills and agents (never overwrite a real file or a foreign symlink). To version a sub-agent that already exists as a real file in `~/.claude/agents/`, move it into `agents/` first, then re-run install so the symlink replaces the original.

**Third-party skills (`THIRD_PARTY_SKILLS`, `--global`/`--update` only).** Skills that aren't shipped as plugins are declared at the top of `install.sh` as `"owner/repo [-exclusion …]"` — the whole GitHub source minus the listed names — and installed with `npx skills add <repo> -g -s <names…> -a claude-code github-copilot -y`, the CLI pinned as `SKILLS_CLI="skills@1.7.0"` (bump it deliberately, never float to latest: it is what writes into the hub after the audit). A third-party skill named like one of this repo's skills (its hub entry is a symlink into `skills/`) is warned about and skipped — never diffed against or overwritten; exclude it from the source with `-<name>`. The name is read from the `SKILL.md` frontmatter only. skills.sh keeps a single copy in `~/.agents/skills/` (the hub): Codex, Cursor and Gemini read it directly, and so does Copilot CLI, since skills.sh ≥1.7 treats `github-copilot` as a "universal" agent that writes nothing to `~/.copilot/skills` (its changelog: "Support `.agents/skills` directory for auto-loading skills") — `-a claude-code` is the one agent that still needs a pointer, a relative symlink `~/.claude/skills/<name>` → the hub. Matt Pocock's skills are deliberately taken this way and **not** as the `mattpocock-skills` plugin, which only Claude Code sees: never list a source both here and in `THIRD_PARTY_PLUGINS`, or every skill exists twice (`tdd` and `mattpocock-skills:tdd`), doubling context and making triggering random. `--no-third-party-skills` skips them; `--global --uninstall` removes what `~/.agents/.skill-lock.json` attributes to each declared source.

**Security audit.** Every plugin and third-party skill install or update goes through `préparer → comparer → analyser → décider → appliquer → vérifier`: the new version is staged in a temp dir (git clone of the skill source; for a plugin, the marketplace's relative path or a `{url, sha}` fetch), compared with the installed copy, audited by `scripts/audit.sh` on the **diff only** (whole tree on first install), then installed, then re-compared to catch a source that moved between audit and install (mismatch → skill removed / plugin **uninstalled**, not disabled: a disabled plugin would stay cached and pass as up to date next run, unaudited). A marketplace entry that itself declares components (`hooks`, `mcpServers`, `lspServers`, `commands`, `agents`, `skills`) is skipped as an error: that content lives in `marketplace.json`, is never staged or hashed, so never audited. Pieces:

- `scripts/lib.sh` — shared primitives. `list_files` is the **only** place listing ignored runtime artefacts (`.git`, `.in_use`, `.orphaned_at`, `__pycache__`, `.DS_Store`); add one there if the plugin cache or skills.sh starts writing a new marker, or every comparison will report a false difference. Its optional `--no-node-modules` flag additionally excludes `node_modules` (any depth): passed by plugin comparisons (up-to-date check and post-update concordance) when the staged source itself has none, since Claude Code installs some plugins' npm dependencies into their cache dir after install (`chrome-devtools-mcp`, `atlassian`); skills stay strict. Those dependencies are fetched after the audit and are never scanned at install/update time — only `--audit-installed` (below) sees them, and slowly (~30k files for `chrome-devtools-mcp`).
- `scripts/audit.sh <dir> [--against <old>] [--name <label>] [--no-llm]` — exit `0` clean · `1` grave findings · `2` analysis error (also asks: a failed audit never counts as approval). Static pass = `scripts/audit-patterns.txt` (tab-separated `gravité	regex	libellé`, `grave` asks, `note` only shows) + structural checks (hooks incl. `hooks:` in Markdown frontmatter, MCP and LSP servers, npm install scripts, invisible Unicode, new executables, cited domains). Symlinks are never followed (compared/hashed by link text, `lib.sh` too); one pointing outside the tree is grave. A binary (NUL byte) is grave unless it is a non-executable known media type. Files go to grep/perl through `xargs -0` so a huge tree can't hit ARG_MAX silently; a failed batch, a truncated (>200 KB) diff or an unreadable verdict all mean exit `2`. Then `claude -p --tools "" --strict-mcp-config --mcp-config '{"mcpServers":{}}' --disallowedTools 'mcp__*' --setting-sources "" --disable-slash-commands --no-session-persistence` (no tools, no MCP, no user/project settings hence no hooks or plugins, no skills) with `scripts/audit-prompt.md`; the item's name, static findings and diff are all inside the `<<<DIFF_DEBUT … DIFF_FIN>>>` fence as data, and only the `VERDICT: ok|suspect` line is parsed. `AUDIT_CLAUDE_BIN` swaps the binary (tests).
- Decision: grave → report, then `[o/N]` on stdin if it is a terminal. An explicit no is remembered in `~/.agents/.audit-refused` (`type:name hash date`, hash = content sha256, not version) and the item is skipped until its content changes; a no for lack of a terminal is **not** remembered. `--reconsider <name>` forgets it. `INSTALL_ANSWER=o|n` answers for tests.
- Already-installed items identical to their source are trusted and never audited; `--audit-installed` (optionally `--no-llm`) audits the existing base in full.
- Tests: `tests/run.sh` (static + fake-claude, deterministic, free) and `tests/run.sh --with-llm` (two real `claude -p` calls). Pipeline changes are checked by hand in a throwaway `HOME` (`HOME=$(mktemp -d) INSTALL_ANSWER=o ./install.sh --global --no-plugins --no-llm`) — never against the real `~/.claude` without asking.
- bash here is macOS's 3.2: no `mapfile`, and `"${arr[@]}"` on an empty array aborts under `set -u` — test `${#arr[@]}` first. Never prompt inside a `while … done < <(…)` loop (stdin is the command): collect into an array, then `for`.

Design rationale: `docs/superpowers/specs/2026-09-18-third-party-skills-audit-design.md`.

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
