# Devlog

## 2026-09-14 — Journal de projet et rédaction de PR

- **Nouveau skill `add-journal`.** Consigne l'avancement d'un projet dans sa fiche du vault Obsidian. Plutôt que d'inventer une section, il réutilise `## Track Log`, déjà présente dans le Modèle Projet du vault et dans 28 fiches — mais tenue dans quatre formats différents. Arbitrage : un format imposé pour les nouvelles entrées (`### AAAA-MM-JJ` + 1 à 6 puces, la plus récente en haut), sans jamais reformater l'existant. Le skill lit le Modèle Projet dans le vault au moment de créer une fiche au lieu de le recopier : pas de gabarit dupliqué à tenir synchronisé, contrairement au couple `add-knowledge` / `check-knowledge`.
- **Évalué sur des copies du vault** (3 cas, avec et sans skill) : 29/29 assertions avec le skill contre 21/29 sans. Sans skill, l'agent ajoute en bas, rédige en paragraphes, coche des tâches et tranche des ADR de lui-même.
- **Optimisation de la description non concluante.** Les 5 itérations de `run_loop.py` plafonnent au même score sur le jeu de test ; le rappel reste quasi nul quelle que soit la description. Le harnais lance `claude -p` depuis ce dépôt, sans le vault : l'agent répond directement au lieu d'ouvrir le skill. Description d'origine conservée — le déclenchement est à juger à l'usage.
- **Nouveau skill `writing-pr`** : titre et corps de Pull Request, en français par défaut, concis (puces, extraits, Mermaid).

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
