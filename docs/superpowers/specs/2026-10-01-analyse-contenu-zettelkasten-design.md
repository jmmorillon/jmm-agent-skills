# Design — `/analyse-contenu` et `/zettelkasten`

Date : 2026-10-01

## Objectif

Transformer un contenu externe (vidéo, article, livre, podcast, page web) en connaissances durables dans le vault Obsidian « Second Cerveau 2 », en deux temps :

1. **`/analyse-contenu`** — analyse critique du contenu, fidèle à la source : ce qu'elle dit, ce qui est solide, ce qui est faible, ce qui ne peut pas être tranché. Sortie en chat uniquement.
2. **`/zettelkasten`** — conservation : écrit une note de littérature et des fiches permanentes atomiques dans `Connaissances/Prise de notes/`.

Le flux reproduit celui que l'utilisateur pratique déjà à la main (exemple de référence : `Les Entreprises Bullshit se sont faites tuer par l'IA (vidéo).md` et ses 7 fiches, dont `Avant d'attribuer un déclin à l'IA, chercher les causes concurrentes.md`).

## Décisions prises

| Question | Décision |
|---|---|
| Qui écrit la note de littérature ? | `/zettelkasten` (note de littérature + fiches permanentes). `/analyse-contenu` n'écrit rien dans le vault. |
| Vérification des affirmations | Connaissances du modèle ; recherche web **seulement en cas de doute** (chiffre, fait daté, fait récent), avec source primaire citée. Sinon : « non vérifiable », jamais tranché au hasard. |
| Rédaction | L'IA rédige, l'utilisateur valide : liste des fiches proposées (titre + idée en une phrase) à cocher / renommer / rejeter, puis « Mon avis » proposé et corrigé avant écriture. |
| Enchaînement | `/analyse-contenu` termine en proposant `/zettelkasten`. `/zettelkasten` reste invocable seul. |
| Liens | Recherche de fiches proches dans `Prise de notes/` uniquement ; liens **à sens unique** depuis les nouvelles fiches. Aucune fiche existante n'est modifiée (les backlinks Obsidian couvrent le sens inverse). |
| Lien sans contenu | Page web : récupération du texte. Vidéo / page inaccessible : demande de la transcription. Jamais d'analyse à partir du seul titre. |
| `_INDEX.md` | Non touché : il appartient à `/add-knowledge`, et `Prise de notes/` n'y figure pas. |
| Plafond | 10 fiches maximum par contenu ; au-delà, l'utilisateur trie. |
| Doublons | Si une fiche existante couvre déjà une idée, proposer de la lier plutôt que d'en créer une nouvelle. |
| Nom du skill | `zettelkasten` (orthographe du champ `type:` des fiches), pas « zettlekasten ». |

## Approche retenue

Deux skills couplés par un **contrat d'analyse** (la liste des sections que produit `/analyse-contenu`), et non par des gabarits dupliqués. Les gabarits de fichiers n'appartiennent qu'à `/zettelkasten`, en ressources `references/` (progressive disclosure), puisque lui seul écrit.

Écartées :
- Gabarits restatés dans les deux `SKILL.md` (modèle `add-knowledge`/`check-knowledge`) : inutile, `/analyse-contenu` n'écrit pas dans le vault.
- Fichier d'analyse intermédiaire sur disque : fichier de plus à gérer, sans bénéfice dans une même conversation.

Différence avec `/add-knowledge` : celui-ci capture ce qui est appris **pendant une session de travail**, dans des fichiers thématiques incrémentaux. `/zettelkasten` capture des idées tirées d'un **contenu externe**, en fiches atomiques. Les descriptions des deux skills doivent le dire pour éviter les déclenchements croisés.

## Fichiers

```
skills/
  analyse-contenu/
    SKILL.md
  zettelkasten/
    SKILL.md
    references/
      note-litterature.md     <- gabarit de note de littérature
      fiche-permanente.md     <- gabarit de fiche permanente
```

## `/analyse-contenu`

**Entrée.** Un lien, un titre ou un thème, et le contenu (copié-collé ou fichier joint). Résolution du contenu :
- contenu fourni → l'analyser ;
- lien vers une page web, sans contenu → récupérer le texte de la page ;
- lien vidéo / audio, ou page inaccessible / derrière paywall → s'arrêter et demander la transcription ou le texte ;
- titre ou thème seul → demander le contenu. Ne jamais analyser de mémoire.

**Contraintes (fidélité).**
- Rapporter uniquement ce que dit le contenu. Ne pas ajouter d'idées absentes de la source dans la partie « ce que dit la source ».
- Toujours séparer trois registres : *ce que dit la source* / *ce que le modèle en sait* / *ce qui ne peut pas être tranché*.
- Ne jamais compléter un chiffre, une date, un nom ; ne jamais inventer de source ni de citation.
- Recherche web seulement pour un point douteux ; citer la source primaire trouvée. À défaut : « non vérifiable ».
- Garder les repères de la source (horodatage d'une transcription, numéro de page, section) quand ils existent ; ne pas en inventer.

**Sortie obligatoire** (le contrat lu par `/zettelkasten`), en chat :

1. **Source** — titre, type (vidéo, article, livre, podcast, page), auteur si connu, lien.
2. **Thèse** — la thèse du contenu en 2-3 phrases, fidèle.
3. **Idées candidates** — 10 maximum ; pour chacune : une affirmation en une phrase, le repère dans la source (horodatage, page, passage) s'il existe.
4. **Faits solides** — affirmations vérifiées (par connaissance ou source citée).
5. **Points faibles** — affirmations fausses, non sourcées, comparaisons bancales, contradictions, conflits d'intérêts ; chacun avec la raison.
6. **Non vérifiable** — ce qui n'a pu être tranché.
7. **Avis proposé** — 1-2 phrases d'évaluation de la valeur du contenu, présentées comme une proposition à corriger.

Puis une phrase : proposer de conserver avec `/zettelkasten`.

## `/zettelkasten`

**Emplacement fixe :**
```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes
```
Chemin avec espaces : toujours cité en shell. Absent → s'arrêter et le dire ; ne jamais le créer ailleurs.

**Deux modes d'entrée.**
- **Après une analyse** présente dans la conversation (contrat ci-dessus) → note de littérature + fiches.
- **Idée dictée** sans analyse → une fiche seule ; `source` = ce que l'utilisateur indique (lien wiki vers une note existante, ou texte brut). Pas de note de littérature créée dans ce mode.

**Méthode.**
1. Lire `Prise de notes/` (titres + frontmatter) pour repérer fiches proches et doublons.
2. Présenter la liste numérotée des fiches proposées (10 max) : titre-affirmation, idée en une phrase, liens envisagés vers des fiches existantes, et « déjà couvert par [[…]] » le cas échéant.
3. L'utilisateur coche, renomme, rejette.
4. Proposer l'encadré « Thèse + Mon avis » ; l'utilisateur corrige.
5. Lire les gabarits dans `references/`, rédiger, puis écrire :
   - la note de littérature, dont « Idées extraites → fiches permanentes » liste chaque fiche créée (avec son lien horodaté s'il existe) ;
   - chaque fiche, avec `source: "[[<titre de la note de littérature>]]"`.
6. Afficher la liste des fichiers créés.

**Règles d'écriture.**
- `id` = `AAAAMMJJHHmm`, unique : la note de littérature prend l'heure courante, chaque fiche la minute suivante (incrément de 1 par fiche), en vérifiant qu'aucun fichier de `Prise de notes/` ne porte déjà cet `id`.
- Nom de fichier = `title`, caractères interdits dans un nom de fichier (`/ \ : * ? " < > |`) remplacés par ` - ` ou supprimés ; le `title` du frontmatter garde la forme lisible.
- Note de littérature : titre suffixé par le type — `(vidéo)`, `(article)`, `(livre)`, `(podcast)`.
- Si un fichier du même nom existe : ne jamais écraser ; demander un autre titre.
- Ne modifier **aucun** fichier existant, `_INDEX.md` compris.
- Tags : réutiliser en priorité ceux déjà présents dans `Prise de notes/`, en minuscules, sans accents, préfixés `#`.
- Une fiche = une idée, formulée avec des mots simples, titre en affirmation ; exemples tirés de la source, signalés comme tels.

## Gabarits (dérivés des notes réelles)

**`references/fiche-permanente.md`** — d'après `Avant d'attribuer un déclin à l'IA, chercher les causes concurrentes.md` :

```markdown
---
id: AAAAMMJJHHmm
title: <affirmation>
type: zettelkasten
tags:
  - "#tag"
source: "[[<note de littérature>]]"
date_created: AAAA-MM-JJ
---
# <affirmation>

<L'idée en 1-3 phrases.>

<Développement : conditions, liste à puces avec mots-clés en gras si utile.>

**Exemples tirés de <la source> :**
- …

<Facultatif : indice / règle pratique qui en découle.>

## Liens

- [[<fiche existante>]] : <pourquoi elle est liée>.
```

**`references/note-litterature.md`** — d'après `Les Entreprises Bullshit se sont faites tuer par l'IA (vidéo).md` :

```markdown
---
id: AAAAMMJJHHmm
title: <titre> (<type>)
aliases:
  - <alias court>
type: literature-note
tags:
  - "#tag"
source: <description de la source>
date_created: AAAA-MM-JJ
---
[<titre original>](<url>)

# <titre> (<type>)

> [!abstract] Thèse de <la vidéo / l'article…>
> <thèse>
>
> **Mon avis :** <avis validé>

## Idées extraites → fiches permanentes

- [<repère>](<url horodatée>) <idée> → [[<fiche>]]

## Faits solides (vérifiés dans l'ensemble)

- …

## Points faibles

- …

## Liens

- [[<note existante>]] : <pourquoi>.
```

Sections vides (pas de faits solides, pas de liens) : omises plutôt que remplies de vide.

## Vérification

Pas de toolchain de test dans le repo. Vérification manuelle :
1. Lancer `/analyse-contenu` sur un contenu réel (transcription collée) et contrôler que la sortie suit les 7 sections et que rien n'est inventé (repères absents → pas de repère).
2. Lancer `/zettelkasten` en le faisant écrire **d'abord dans un dossier temporaire** (copie de `Prise de notes/`), contrôler frontmatter, `id` uniques, liens wiki résolus, aucun fichier existant modifié.
3. Puis un essai réel dans le vault, avec accord de l'utilisateur.
