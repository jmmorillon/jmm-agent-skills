---
name: project-docs-sync
description: À utiliser pour synchroniser la documentation « vivante » d'un projet avec son état réel après du travail : fichiers d'instructions agent (CLAUDE.md, AGENTS.md…), README.md, DEVLOG.md, BACKLOG.md et la documentation de site éventuelle (VitePress, VuePress, MkDocs, Docusaurus, Starlight…). Déclenche ce skill dès que l'utilisateur demande de « mettre à jour la doc », « mettre à jour le devlog / le backlog / le README », « synchroniser la documentation », « documenter ce qu'on vient de faire » ou de rafraîchir les instructions du projet — et propose-le spontanément après une tâche d'ampleur (nouvelle feature, refactor, changement de structure ou de dépendances), même si l'utilisateur ne le demande pas explicitement.
---

# Project Docs Sync

Tu maintiens la documentation « vivante » d'un dépôt alignée avec son état réel. Après une session de travail, plusieurs fichiers finissent en décalage avec le code : le README décrit une commande qui a changé, le DEVLOG ne mentionne pas la feature d'hier, le BACKLOG liste une tâche déjà faite, les instructions agent ignorent un nouveau dossier. Ton rôle est de résorber ces écarts — pas de tout réécrire, mais de mettre chaque document à jour là où la réalité l'a dépassé.

## Principe directeur : mise à jour chirurgicale, pas réécriture

La documentation existante encode des décisions, un ton, une structure que quelqu'un a choisis. La respecter est plus important que d'imposer un format « idéal ». Concrètement :

- **Modifie le minimum nécessaire.** Touche les passages devenus faux ou incomplets, laisse le reste intact. Un diff court et ciblé est plus facile à relire et à faire confiance qu'une refonte.
- **Épouse le style en place** : langue, ton, densité de titres, conventions de nommage, format des listes. Si le projet écrit en français, tu écris en français ; s'il numérote ses entrées de devlog d'une certaine façon, tu continues pareil.
- **N'invente rien.** Ne documente que ce que tu peux étayer par le code, l'historique git ou la conversation. Dans le doute, signale l'incertitude plutôt que de combler avec une supposition.
- **Ne crée pas de fichier sans accord.** Si un DEVLOG/BACKLOG/doc pertinent manque, propose-le et attends le feu vert (voir « Fichiers absents »).
- **Ne commite pas.** Tu mets à jour les fichiers ; laisser le commit à l'utilisateur, comme pour tout changement.

## Méthode

### 1. Inventaire

Repère ce qui existe réellement à la racine (et aux emplacements usuels) avant d'agir :

- **Instructions agent** : `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/*`, `.cursorrules`. Un projet peut en avoir plusieurs — traite chacun présent.
- **README** : `README.md` (ou `README.rst`, `README.txt`).
- **Journal** : `DEVLOG.md`, `CHANGELOG.md` (attention : un CHANGELOG suit souvent un format strict type *Keep a Changelog* — respecte-le).
- **Backlog** : `BACKLOG.md`, `TODO.md`, `ROADMAP.md`.
- **Documentation de site** : détecte le framework (voir table ci-dessous). S'il y en a un, lis `references/doc-frameworks.md` pour savoir où vivent les pages et comment les mettre à jour.

Détermine aussi la **langue dominante** du projet (à partir des fichiers existants) et tiens-t'y.

Table de détection rapide de la doc de site :

| Indice (fichier / dépendance) | Framework | Détail |
| --- | --- | --- |
| `.vitepress/config.*` | VitePress | `references/doc-frameworks.md` |
| `.vuepress/config.*` | VuePress | `references/doc-frameworks.md` |
| `mkdocs.yml` | MkDocs | `references/doc-frameworks.md` |
| `docusaurus.config.*` | Docusaurus | `references/doc-frameworks.md` |
| `astro.config.*` + dép. `@astrojs/starlight` | Starlight | `references/doc-frameworks.md` |
| `docs/` sans config connue | Doc « brute » (Markdown simple) | Mets à jour les `.md` concernés directement |

### 2. Rassemble la matière

La mise à jour doit refléter ce qui a *réellement* changé. Croise trois sources :

1. **La conversation en cours** : ce que vous venez de faire ensemble est la source la plus fraîche et la plus fiable de « ce qui a changé ».
2. **L'historique git** : `git status`, `git log` et `git diff` depuis le dernier repère documenté (dernière entrée de DEVLOG, dernier tag, ou les derniers commits). C'est ce qui révèle les changements non encore consignés.
3. **L'état du dépôt** : compare ce que disent les docs actuelles à la structure réelle (dossiers, scripts, dépendances, commandes). Les écarts sont ta liste de travail.

Si tu es exécuté sans accès à la conversation d'origine (par ex. dispatché dans un sous-agent au contexte neuf), appuie-toi davantage sur `git diff`/`git log` et signale que le « pourquoi » des changements peut manquer.

Si tu ne trouves aucun changement à documenter, dis-le et arrête-toi — ne fabrique pas d'entrées pour justifier une exécution.

### 3. Mets à jour chaque cible présente

Pour chaque fichier trouvé à l'étape 1, applique les principes de la section « Cibles » ci-dessous. Fais des éditions ponctuelles, pas des remplacements de fichier entier.

### 4. Traite les fichiers absents (avec accord)

Si un document manifestement pertinent manque — par ex. le projet a une vraie activité mais pas de DEVLOG, ou un backlog vit éparpillé dans la conversation — **propose** de le créer avec un squelette, en une phrase, et attends la réponse. Ne crée jamais d'office. Un projet peut délibérément ne pas vouloir de tel ou tel fichier.

### 5. Rends compte

Termine par le récapitulatif décrit dans « Sortie obligatoire ».

## Cibles

### Instructions agent (CLAUDE.md, AGENTS.md, …)

Ces fichiers pilotent le comportement des agents dans le projet. Garde-les alignés avec la **structure et les conventions réelles** : nouvelles commandes de build/test/lint, arborescence, points d'entrée, règles de style, garde-fous. Corrige ce qui est devenu faux (une commande renommée, un dossier déplacé).

- Ne transforme pas ce fichier en copie du README : il s'adresse à un agent qui code, pas à un humain qui découvre le projet. Vise l'actionnable et le non-évident.
- Si plusieurs fichiers d'instructions coexistent (CLAUDE.md + AGENTS.md), garde-les cohérents entre eux ; ne laisse pas l'un contredire l'autre.

### README.md

Le README décrit le projet **tel qu'il est maintenant** pour quelqu'un qui arrive. Mets à jour : la description, l'installation, l'usage, la liste des fonctionnalités/commandes, les prérequis. Retire ce qui n'existe plus. Si le README a un index ou une table des matières, tiens-le à jour.

### DEVLOG.md (journal de développement)

Le DEVLOG raconte *ce qui a été fait*, en général en entrées datées **antéchronologiques** (la plus récente en haut). Ajoute une entrée pour le travail récent non encore consigné.

- **Respecte le format existant** : structure d'en-tête, granularité (par jour ? par version ? par feature ?), présence ou non de dates, style des puces.
- À défaut de format établi, applique la convention par défaut (voir « Conventions par défaut »).
- Décris le *quoi* et le *pourquoi* d'un changement, pas seulement le *comment* — une entrée utile explique la décision, pas juste le diff.

### BACKLOG.md (tâches à venir)

Le BACKLOG liste *ce qui reste à faire*. Après du travail, il faut le réconcilier : **coche/retire** ce qui est terminé, **ajoute** les tâches nouvellement apparues (dette technique repérée, suites logiques), **reformule** ce qui a évolué.

- Respecte l'organisation existante (sections, priorités, labels, cases à cocher).
- À défaut, applique la convention par défaut.
- Ne supprime pas silencieusement une tâche non faite : si tu penses qu'elle est caduque, déplace-la ou signale-la, ne l'efface pas.

### Documentation de site

Si le projet a un site de doc (VitePress, VuePress, MkDocs, Docusaurus, Starlight…), lis `references/doc-frameworks.md` pour localiser les pages et comprendre les conventions (sidebar/navigation, frontmatter, emplacement des fichiers). Mets à jour les pages concernées par les changements et, si une page nouvelle est justifiée, ajoute-la à la navigation. Là encore : édition ciblée, pas refonte.

## Conventions par défaut (uniquement si le fichier n'a pas déjà un format)

Ces gabarits ne s'appliquent qu'à un fichier neuf ou sans structure établie. Un fichier existant garde son propre format.

**DEVLOG.md** — entrées antéchronologiques, datées :

```markdown
# Devlog

## AAAA-MM-JJ — <titre court de la session>

- <changement notable, avec le pourquoi si utile>
- <autre changement>
```

**BACKLOG.md** — tâches par sections, cases à cocher :

```markdown
# Backlog

## À faire
- [ ] <tâche>

## En cours
- [ ] <tâche>

## Fait
- [x] <tâche terminée>
```

## Sortie obligatoire

Termine toujours par un récapitulatif compact, une ligne par fichier, groupé par action :

```
Synchronisation terminée.
Modifiés :
  - README.md — <ce qui a changé, en quelques mots>
  - DEVLOG.md — entrée ajoutée pour <sujet>
Créés (après accord) :
  - BACKLOG.md — squelette initial
Ignorés :
  - AGENTS.md — aucun changement nécessaire
  - doc de site — aucun framework détecté
```

Si tu n'as rien changé, dis-le franchement plutôt que de gonfler le rapport.

## Règle finale

Reste **conservateur** : mise à jour ciblée plutôt que réécriture, style et langue existants préservés, rien d'inventé. **Ne crée jamais un fichier absent sans l'accord explicite de l'utilisateur**, et **ne commite pas** — le commit reste sa décision.
