# Devlog

## 2026-09-18 — Skills tierces et audit de sécurité

- **Skills tierces versionnées dans `install.sh`.** Les 37 skills installées à la main via skills.sh (35 de `mattpocock/skills`, `find-skills`, `ccc`) n'étaient suivies nulle part : une nouvelle machine ne les retrouvait pas. Elles sont maintenant déclarées dans `THIRD_PARTY_SKILLS`, par source entière moins exclusions. Matt Pocock passe par skills.sh plutôt que par le plugin `mattpocock-skills` : le plugin n'est vu que par Claude Code, et installer les deux doublerait chaque skill (`tdd` et `mattpocock-skills:tdd`).
- **Audit de sécurité avant toute activation**, plugins et skills, à l'installation comme à la mise à jour : préparer → comparer → analyser le diff (filtre statique + `claude -p` isolée) → `[o/N]` → installer → vérifier que l'installé est l'analysé. Refus mémorisés par empreinte de contenu. Nouveau mode `--update` (remplace `--update-plugins`, gardé en alias), plus `--audit-installed`, `--reconsider`, `--no-llm`, `--no-third-party-skills`. Code dans `scripts/` (`lib.sh`, `audit.sh`), 61 tests dans `tests/run.sh`.
- **Ce que les relectures ont rattrapé.** Claude Code installe les `node_modules` de certains plugins dans leur cache : sans tolérance, `chrome-devtools-mcp` et `atlassian` auraient été désactivés à chaque mise à jour. La revue finale a trouvé des contournements de l'audit — un octet nul faisant passer un script pour binaire, un lien symbolique vers `~/.ssh` lu et envoyé au LLM, le filtre muet au-delà de ~24 000 fichiers (ARG_MAX), un diff tronqué accepté, un auditeur qui chargeait encore les serveurs MCP — tous fermés, chacun avec son test.
- **Écarts constatés sur les CLI** : le marketplace de plugins n'est pas un dépôt git (empreinte = sha256 du contenu, pas hash d'arbre) ; skills.sh 1.7 ne crée rien dans `~/.copilot/skills`, Copilot CLI lisant directement `~/.agents/skills`.
- **Vérifié** : installation, relance idempotente et désinstallation dans un `HOME` jetable ; puis un vrai `--update` — 31 skills mises à jour après audit, aucun signalement, 0 erreur, les 10 plugins à jour.

## 2026-09-18 — Mise à jour des plugins tiers

- **Nouveau mode `install.sh --update-plugins`.** Le bootstrap savait installer et désinstaller les plugins tiers, pas les mettre à jour. Le mode rafraîchit le marketplace puis boucle `claude plugin update <nom>@claude-plugins-official --scope user --json` sur la liste : le CLI ne prend qu'un plugin à la fois, il n'y a pas de `--all`. Il met à jour seulement — un plugin listé mais non installé est signalé, jamais ajouté, car installer reste le rôle de `--global`.
- **Mode autonome plutôt que flag de `--global`.** Il ne se combine ni avec `--global`/`--local` ni avec `--uninstall`/`--no-plugins` (exit 2), ne touche à aucun symlink, et n'exige pas le dossier `skills/` — le script reste donc exécutable depuis une copie isolée.
- **Sortie lue via un helper `sed`, pas `jq`** : `json_field` extrait les champs plats de la ligne `--json` (`updateOutcome`, `oldVersion`, `newVersion`, `failureCode`) pour éviter une dépendance de plus. Ce n'est pas un parseur JSON — il casse sur une valeur contenant un guillemet échappé, d'où le choix de rapporter `failureCode` plutôt que `message`.
- **Vérifié** : syntaxe, les deux combinaisons rejetées, la branche d'échec (faux plugin, `not_found`, sans interrompre la boucle) et un run réel — les 10 plugins étaient déjà à jour. La branche « maj » n'a pas pu être exercée, faute de plugin en retard.

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
