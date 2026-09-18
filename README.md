# jmm-agent-skills

Collection personnelle de *skills* pour [Claude Code](https://claude.com/claude-code), le [Claude Agent SDK](https://docs.claude.com/) et GitHub Copilot CLI.

Chaque skill est un dossier dans `skills/`, exposé aux outils par symlink — pas de copie, pas de build. Modifie un `SKILL.md`, et le changement est immédiat pour les agents.

## Installation

```bash
git clone https://github.com/jmmorillon/jmm-agent-skills.git
cd jmm-agent-skills
./install.sh --global
```

`--global` crée trois symlinks par skill :

1. `~/.agents/skills/<nom>` → `<repo>/skills/<nom>` (le hub, source unique)
2. `~/.claude/skills/<nom>` → `../../.agents/skills/<nom>` (exposition à Claude Code)
3. `~/.copilot/skills/<nom>` → `../../.agents/skills/<nom>` (exposition à Copilot CLI)

Les deux outils voient la même skill, gérée à un seul endroit (le hub). Le script n'écrase **jamais** un fichier ou un symlink déjà présent qui ne lui appartient pas — il cohabite avec les skills installées par d'autres moyens.

### Plugins tiers (bootstrap machine)

En mode `--global`, le script installe aussi une liste versionnée de plugins Claude Code tiers, pour servir de bootstrap « nouvelle machine ». Ils proviennent tous du marketplace officiel `anthropics/claude-plugins-official` et sont installés en scope `user` via le CLI `claude` :

```bash
./install.sh --global               # skills perso + plugins tiers
./install.sh --global --no-plugins  # skills perso uniquement
./install.sh --update-plugins       # met à jour les plugins déjà installés
```

La liste (`superpowers`, `figma`, `frontend-design`, `code-review`, `context7`, `skill-creator`, `playwright`, `security-guidance`, `atlassian`, `chrome-devtools-mcp`) est déclarée en haut de `install.sh` : édite le tableau `THIRD_PARTY_PLUGINS` pour en ajouter ou en retirer.

- Nécessite le CLI `claude` dans le `PATH` ; s'il est absent, les plugins sont ignorés (avec un avertissement) et les symlinks de skills s'installent quand même.
- Les plugins étant en scope `user`, ils ne concernent que `--global` — le mode `--local` ne les touche jamais.
- `--update-plugins` s'utilise seul : il rafraîchit le marketplace puis met à jour chaque plugin de la liste, sans toucher aux symlinks. Il met à jour seulement — un plugin listé mais absent est signalé, pas installé. Redémarre Claude Code pour appliquer les mises à jour.
- Seule la *liste* est versionnée ; le cache `~/.claude/plugins/` est reconstruit à partir d'elle et n'a pas à être commité.

### Sous-agents

Le dépôt versionne aussi des définitions de **sous-agents** Claude Code, dans le dossier `agents/` (fichiers `.md` plats). Ils sont symlinkés comme les skills, avec deux différences : ce sont des fichiers (pas des dossiers) et ils ne concernent **que Claude Code** (pas de couche Copilot, pas de hub `~/.agents/`).

- `--global` → `~/.claude/agents/<nom>.md`
- `--local` → `<projet>/.claude/agents/<nom>.md`
- `--no-agents` → ne gère pas les sous-agents.

Pour versionner un sous-agent qui existe déjà comme fichier réel dans `~/.claude/agents/`, déplace-le d'abord dans `agents/`, puis relance `install.sh` : le symlink remplace l'original.

### Installation locale (projet)

Pour rendre une skill disponible uniquement dans un projet (sans pollution globale) :

```bash
./install.sh --local /chemin/vers/mon-projet
# (sans argument : utilise le répertoire courant)
```

Crée `<projet>/.claude/skills/<skill>` et `<projet>/.copilot/skills/<skill>` comme symlinks vers ce dépôt.

### Désinstallation

```bash
./install.sh --global --uninstall
./install.sh --local /chemin --uninstall
```

Retire uniquement les symlinks créés par ce dépôt. Ne touche jamais à un fichier réel ni à un symlink qui pointe ailleurs. En mode `--global`, désinstalle aussi les plugins tiers listés (sauf avec `--no-plugins`).

### Comportement du script

- **Idempotent** : relancer `install.sh` est sans effet si tout est déjà en place (marketplace déjà connu et plugin déjà installé compris).
- **Sûr** : si une cible existe déjà comme symlink pointant ailleurs, ou comme fichier réel, le script affiche un warning et passe — il ne supprime jamais ce qu'il n'a pas créé.
- `./install.sh --help` pour le détail des options.

## Skills disponibles

| Skill                                                                  | Description                                                                                                                                                                       |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`obsidian-para-sorter`](skills/obsidian-para-sorter/SKILL.md)         | Réorganise un lot de 20 notes Obsidian selon la méthode PARA (Projects / Areas / Resources / Archive) : classification, renommage, fusion, archivage, signalement des ambiguïtés. |
| [`bruno-api-collection`](skills/bruno-api-collection/SKILL.md)         | Crée et maintient une collection d'API Bruno (fichiers `.bru` versionnés dans le dépôt) : scaffolding, ajout/mise à jour de requêtes, synchronisation après changement de routes, rejeu d'appels tiers pour debug. |
| [`add-knowledge`](skills/add-knowledge/SKILL.md)                       | Capture dans un vault Obsidian une connaissance acquise en session (méthode de résolution, commande utile, notion mal maîtrisée) sous forme de fiche thématique incrémentale, et tient un index global. Fait reformuler l'utilisateur avant d'écrire. |
| [`check-knowledge`](skills/check-knowledge/SKILL.md)                   | Interroge l'utilisateur sur les connaissances capturées pour vérifier ce qu'il a retenu, et met à jour leur état de révision dans l'index. Compagnon de `add-knowledge`. |
| [`add-journal`](skills/add-journal/SKILL.md)                           | Tient le journal de bord d'un projet dans sa fiche du vault Obsidian : entrées datées et concises en puces dans la section `## Track Log`, liées aux autres fiches. Crée la fiche depuis le Modèle Projet si elle manque (`Projets/` en cours, `Domaines/` pour un projet ancien). Rien n'est écrit sans validation. |
| [`writing-pr`](skills/writing-pr/SKILL.md)                             | Rédige ou modifie le titre et le corps d'une Pull Request (`gh pr create` / `gh pr edit`, ou texte pour GitLab, Bitbucket…), en français par défaut : concis, puces, extraits de code et diagrammes Mermaid. |
| [`project-docs-sync`](skills/project-docs-sync/SKILL.md)               | Synchronise la documentation « vivante » d'un projet avec son état réel après du travail : instructions agent (CLAUDE.md, AGENTS.md…), README, DEVLOG, BACKLOG et doc de site (VitePress, VuePress, MkDocs, Docusaurus, Starlight…). Mise à jour ciblée, respecte l'existant, ne crée rien sans accord. |

## Sous-agents disponibles

| Sous-agent                                          | Description                                                                                                                                          |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`code-improver`](agents/code-improver.md)          | Reviewer *read-only* : scanne les fichiers et propose des améliorations (lisibilité, performance, bonnes pratiques) avec code avant/après. Ne modifie jamais de fichiers. |

## Structure d'une skill

```text
skills/<slug>/
├── SKILL.md
└── references/        # optionnel : détails chargés à la demande (progressive disclosure)
```

Le `SKILL.md` est le point d'entrée. Une skill peut aussi embarquer un dossier `references/` dont le contenu n'est lu que lorsque c'est nécessaire — voir [`skills/project-docs-sync/`](skills/project-docs-sync/SKILL.md), qui ne charge sa fiche sur les frameworks de doc qu'une fois un site détecté.

Le `SKILL.md` commence par un frontmatter YAML lu par les agents pour décider quand activer la skill :

```yaml
---
name: <slug>
description: <une phrase qui décrit quand utiliser la skill>
---
```

Le corps qui suit est le prompt chargé dans l'agent au moment où la skill s'active. Voir [`skills/obsidian-para-sorter/SKILL.md`](skills/obsidian-para-sorter/SKILL.md) pour un exemple de mise en forme (rôle, contraintes, méthode, sortie obligatoire).

### Convention de nommage

- Dossier : `<sujet>-<usage>` en kebab-case, sans préfixe personnel (ex. `obsidian-para-sorter`, `bruno-api-collection`)
- `name:` dans le frontmatter : identique au nom du dossier

## Licence

[Apache License 2.0](LICENSE)
