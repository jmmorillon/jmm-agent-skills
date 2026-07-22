# Devlog

## 2026-07-22 — Bootstrap machine, sous-agents et skill de synchro doc

- **`install.sh` devient un bootstrap complet.** En plus des symlinks de skills, `--global` installe désormais une liste versionnée de plugins tiers (superpowers, figma, code-review, context7, skill-creator, playwright, security-guidance, atlassian, chrome-devtools-mcp, frontend-design) depuis le marketplace officiel `anthropics/claude-plugins-official`, et symlinke les sous-agents. Objectif : réinstaller toute la config en une commande au changement de machine. Flags `--no-plugins` / `--no-agents` pour restreindre le périmètre.
- **Sous-agents versionnés.** Nouveau dossier `agents/` (fichiers `.md` plats, Claude Code uniquement) ; `code-improver` y a été déplacé depuis `~/.claude/agents/` puis re-symlinké. Les définitions d'agents sont maintenant suivies par git.
- **Abandon du préfixe `jmm-` sur les skills.** `jmm-obsidian-para-sorter` renommé en `obsidian-para-sorter` (le `name:` du frontmatter était déjà sans préfixe). Convention alignée sur `bruno-api-collection` : kebab-case simple, `name:` = nom du dossier.
- **Nouveau skill `project-docs-sync`.** Synchronise la documentation « vivante » d'un projet (instructions agent, README, DEVLOG, BACKLOG, doc de site) avec son état réel. Premier skill du repo à utiliser le pattern `references/` (progressive disclosure) pour les frameworks de doc.
- **Scaffolding initial du dépôt** et skill `bruno-api-collection` (collections d'API Bruno versionnées), plus `.gitignore`.

## 2026-05-14 — Initialisation

- Création du dépôt `jmm-agent-skills`.
