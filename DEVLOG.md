# Devlog

## 2026-08-27 — Capture et révision de connaissances

- **Deux nouveaux skills, `add-knowledge` et `check-knowledge`.** Le premier capture dans le vault Obsidian une connaissance acquise en session — fiche thématique incrémentale sous `Connaissances/`, plus une ligne dans un index global. Le second interroge plus tard sur ce qui n'est pas acquis et tient à jour l'état de révision. Le point qui a demandé le plus d'arbitrage n'est pas le format mais la *méthode d'ajout* : le skill fait reformuler l'utilisateur avec ses mots avant d'écrire, parce qu'une fiche qu'il n'a pas formulée ne fait que déplacer son ignorance dans un fichier.
- **Contrat de fichiers dupliqué volontairement.** Les deux skills partagent un gabarit de fiche et un gabarit d'index, recopiés intégralement dans chacun : un `SKILL.md` est chargé seul dans le contexte d'un agent, il ne peut pas importer l'autre. À connaître avant d'éditer l'un des deux — voir `CLAUDE.md`.
- **Premier usage du cycle spec → plan → exécution par sous-agents** (`docs/superpowers/`). La revue a rattrapé deux défauts qui échappaient au protocole de vérification prévu : la clôture d'écriture ne couvrait pas deux notes réelles du vault (une note à la racine, un `.md` posé dans un dossier de thème), et aucun des deux skills ne disait d'aller chercher la date du jour — défaut masqué par une fumigation tombant pile sur la date des exemples.

## 2026-07-22 — Bootstrap machine, sous-agents et skill de synchro doc

- **`install.sh` devient un bootstrap complet.** En plus des symlinks de skills, `--global` installe désormais une liste versionnée de plugins tiers (superpowers, figma, code-review, context7, skill-creator, playwright, security-guidance, atlassian, chrome-devtools-mcp, frontend-design) depuis le marketplace officiel `anthropics/claude-plugins-official`, et symlinke les sous-agents. Objectif : réinstaller toute la config en une commande au changement de machine. Flags `--no-plugins` / `--no-agents` pour restreindre le périmètre.
- **Sous-agents versionnés.** Nouveau dossier `agents/` (fichiers `.md` plats, Claude Code uniquement) ; `code-improver` y a été déplacé depuis `~/.claude/agents/` puis re-symlinké. Les définitions d'agents sont maintenant suivies par git.
- **Abandon du préfixe `jmm-` sur les skills.** `jmm-obsidian-para-sorter` renommé en `obsidian-para-sorter` (le `name:` du frontmatter était déjà sans préfixe). Convention alignée sur `bruno-api-collection` : kebab-case simple, `name:` = nom du dossier.
- **Nouveau skill `project-docs-sync`.** Synchronise la documentation « vivante » d'un projet (instructions agent, README, DEVLOG, BACKLOG, doc de site) avec son état réel. Premier skill du repo à utiliser le pattern `references/` (progressive disclosure) pour les frameworks de doc.
- **Scaffolding initial du dépôt** et skill `bruno-api-collection` (collections d'API Bruno versionnées), plus `.gitignore`.

## 2026-05-14 — Initialisation

- Création du dépôt `jmm-agent-skills`.
