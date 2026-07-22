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

Retire uniquement les symlinks créés par ce dépôt. Ne touche jamais à un fichier réel ni à un symlink qui pointe ailleurs.

### Comportement du script

- **Idempotent** : relancer `install.sh` est sans effet si tout est déjà en place.
- **Sûr** : si une cible existe déjà comme symlink pointant ailleurs, ou comme fichier réel, le script affiche un warning et passe — il ne supprime jamais ce qu'il n'a pas créé.
- `./install.sh --help` pour le détail des options.

## Skills disponibles

| Skill                                                                  | Description                                                                                                                                                                       |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`jmm-obsidian-para-sorter`](skills/jmm-obsidian-para-sorter/SKILL.md) | Réorganise un lot de 20 notes Obsidian selon la méthode PARA (Projects / Areas / Resources / Archive) : classification, renommage, fusion, archivage, signalement des ambiguïtés. |

## Structure d'une skill

```text
skills/<slug>/
└── SKILL.md
```

Le `SKILL.md` commence par un frontmatter YAML lu par les agents pour décider quand activer la skill :

```yaml
---
name: <slug-sans-prefixe-jmm>
description: <une phrase qui décrit quand utiliser la skill>
---
```

Le corps qui suit est le prompt chargé dans l'agent au moment où la skill s'active. Voir [`skills/jmm-obsidian-para-sorter/SKILL.md`](skills/jmm-obsidian-para-sorter/SKILL.md) pour un exemple de mise en forme (rôle, contraintes, méthode, sortie obligatoire).

### Convention de nommage

- Dossier : `jmm-<sujet>-<usage>` (préfixe personnel `jmm-`)
- `name:` dans le frontmatter : même slug, **sans** le préfixe `jmm-`

## Licence

[Apache License 2.0](LICENSE)
