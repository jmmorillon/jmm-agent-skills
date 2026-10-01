# Analyse de contenu et Zettelkasten — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Créer deux skills : `/analyse-contenu` (analyse critique et fidèle d'un contenu externe, en chat) et `/zettelkasten` (écriture d'une note de littérature et de fiches permanentes dans `Connaissances/Prise de notes/` du vault Obsidian).

**Architecture:** Deux dossiers de skill sous `skills/`. Aucun code : le livrable est du prompt Markdown prescriptif. Les skills sont couplés par un **contrat d'analyse** (les 7 sections de sortie de `/analyse-contenu`, que `/zettelkasten` consomme). Les deux gabarits de fichiers n'appartiennent qu'à `/zettelkasten`, en `references/` (lus seulement au moment d'écrire).

**Tech Stack:** Markdown, frontmatter YAML. Vault Obsidian sur iCloud Drive. `install.sh` inchangé (sa boucle sur `skills/*/` ramasse les nouveaux dossiers).

**Spec:** `docs/superpowers/specs/2026-10-01-analyse-contenu-zettelkasten-design.md`

## Global Constraints

- **Langue** : français, dans les skills comme dans les fiches produites.
- **Nommage** : dossiers `skills/analyse-contenu/` et `skills/zettelkasten/` ; `name:` du frontmatter identique au dossier. Orthographe `zettelkasten`.
- **Dossier cible**, écrit en dur dans `/zettelkasten` :
  `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes`
  Espaces : toujours cité en shell. Absent → s'arrêter, ne rien créer ailleurs.
- **`/analyse-contenu` n'écrit rien dans le vault.**
- **`/zettelkasten` ne modifie aucun fichier existant**, `_INDEX.md` compris ; n'écrase jamais un fichier du même nom.
- **Plafond** : 10 idées / fiches maximum par contenu.
- **Web** : seulement en cas de doute, source primaire citée ; sinon « non vérifiable ».
- **Jamais d'analyse à partir du seul titre** ; vidéo/audio ou page inaccessible → demander la transcription.
- **Liens** : recherche dans `Prise de notes/` uniquement, liens à sens unique.
- **`id`** `AAAAMMJJHHmm` : premier = max(heure courante, plus grand `id` existant + 1), puis +1 minute par fichier.
- **Nom de fichier = `title` + `.md`** ; le `title` n'emploie jamais `:` (→ ` - `) ni `/ \ * ? " < > |`.
- **Types** : `literature-note` et `zettelkasten`. Suffixe de note de littérature : `(vidéo)`, `(article)`, `(livre)`, `(podcast)`, `(page)`.
- **Pas de test automatisé** dans ce dépôt : vérification par invariants `grep` puis fumigation manuelle dans un dossier temporaire (Task 3).

## Review Focus

1. **Contenu très long ou tronqué** (transcription d'1 h, fichier lu partiellement) — l'utilisateur attend que l'analyse porte sur tout le contenu, ou dise explicitement ce qui n'a pas été lu. → règle « lire en entier, sinon le dire » dans Task 2, vérifiée en Task 3.
2. **Transcription sans horodatage** — aucun repère ne doit être inventé ; la ligne d'idée n'a alors pas de lien horodaté. → règle dans Task 1 et Task 2, cas de fumigation Task 3.
3. **Titre de source contenant `:` ou `/`** (« IA : le krach… ») — le fichier doit se créer sans erreur, `title` = nom de fichier. → règle Task 1, cas Task 3.
4. **`/zettelkasten` invoqué sans analyse dans la conversation** — mode « idée dictée » : une fiche seule, pas de note de littérature inventée. → règle Task 1, cas Task 3.
5. **Idée déjà couverte par une fiche existante** — proposer le lien, ne pas dupliquer, ne pas modifier l'existante. → règle Task 1, cas Task 3 (contenu de test recouvrant une fiche existante).

## File Structure

| Fichier | Responsabilité | Task |
| --- | --- | --- |
| `skills/zettelkasten/references/fiche-permanente.md` | Gabarit de fiche permanente | 1 |
| `skills/zettelkasten/references/note-litterature.md` | Gabarit de note de littérature | 1 |
| `skills/zettelkasten/SKILL.md` | Valider les fiches avec l'utilisateur, écrire note + fiches | 1 |
| `skills/analyse-contenu/SKILL.md` | Résoudre l'entrée, analyser fidèlement, rendre le contrat | 2 |
| `README.md` (tableau « Skills disponibles ») | Deux lignes | 3 |

---

### Task 1: Skill `zettelkasten` et ses gabarits

**Files:**
- Create: `skills/zettelkasten/references/fiche-permanente.md`
- Create: `skills/zettelkasten/references/note-litterature.md`
- Create: `skills/zettelkasten/SKILL.md`

**Interfaces:**
- Consumes : le contrat d'analyse (sections `Source`, `Thèse`, `Idées candidates`, `Faits solides`, `Points faibles`, `Non vérifiable`, `Avis proposé`), défini en Task 2.
- Produces : chemins `references/fiche-permanente.md` et `references/note-litterature.md`, cités tels quels dans `SKILL.md`.

- [ ] **Step 1: Écrire `skills/zettelkasten/references/fiche-permanente.md`**

`````markdown
# Gabarit — fiche permanente

Remplace chaque `<…>`. Supprime les blocs marqués « facultatif » s'ils ne servent pas. Ne laisse jamais de section vide.

```markdown
---
id: <AAAAMMJJHHmm>
title: <affirmation, sans « : »>
type: zettelkasten
tags:
  - "#<tag>"
source: "[[<titre de la note de littérature>]]"
date_created: <AAAA-MM-JJ>
---
# <affirmation, identique au title>

<L'idée en 1 à 3 phrases simples, compréhensible sans avoir vu la source.>

<Facultatif — développement : conditions, critères ou étapes, en liste à puces, mots-clés en **gras**.>

**Exemples tirés de <la vidéo / l'article / le livre> :**
- <exemple concret donné par la source>

<Facultatif — règle pratique ou indice qui découle de l'idée, en une phrase.>

## Liens

- [[<fiche existante>]] : <pourquoi elle est liée, en une proposition>.
```

## Règles

- **Une fiche = une idée.** Si tu as besoin de « et » dans le titre pour relier deux thèses, ce sont deux fiches.
- **Titre = affirmation** qu'on peut citer seule (« Raccorder prend plus de temps que produire »), pas un sujet (« Le raccordement »).
- **`source`** : lien wiki vers la note de littérature ; en mode « idée dictée », ce que l'utilisateur indique (lien wiki vers une note existante, ou texte brut entre guillemets).
- **Exemples** : uniquement ceux de la source, présentés comme tels. Aucun exemple inventé.
- **`## Liens`** : seulement vers des fichiers existants de `Prise de notes/` (ou vers des fiches créées dans le même lot). Aucune fiche liée pertinente → supprime la section.
- **Tags** : 2 à 4, en minuscules, sans accents, mots séparés par `-`, préfixés `#`, entre guillemets. Réutilise d'abord les tags déjà présents dans `Prise de notes/`.
`````

- [ ] **Step 2: Écrire `skills/zettelkasten/references/note-litterature.md`**

`````markdown
# Gabarit — note de littérature

Remplace chaque `<…>`. Une section sans contenu est supprimée, jamais laissée vide.

```markdown
---
id: <AAAAMMJJHHmm>
title: <titre de la source, sans « : »> (<vidéo|article|livre|podcast|page>)
aliases:
  - <alias court, facultatif>
type: literature-note
tags:
  - "#<tag>"
source: <description de la source, ex. Vidéo YouTube « … » de <auteur>>
date_created: <AAAA-MM-JJ>
---
[<titre original exact>](<url>)

# <titre, identique au title>

> [!abstract] Thèse de <la vidéo / l'article / le livre…>
> <thèse en 2-3 phrases>
>
> **Mon avis :** <avis validé par l'utilisateur>

## Idées extraites → fiches permanentes

- [<MM:SS>](<url horodatée>) <idée en une phrase> → [[<titre de la fiche>]]
- <idée sans repère> → [[<titre de la fiche>]]
- <idée déjà couverte> → [[<fiche existante>]] (fiche existante)

## Faits solides (vérifiés dans l'ensemble)

- <fait> <(source : …) si vérifié par recherche web>

## Points faibles

- <affirmation> : <raison>.

## Non vérifiable

- <affirmation>

## Liens

- [[<note existante>]] : <pourquoi>.
```

## Règles

- **Ligne d'URL** en tête du corps : seulement si la source a une URL. Sinon, supprime la ligne.
- **Repères horodatés** : seulement s'ils figurent dans la transcription fournie. URL horodatée YouTube : `<url>&t=<secondes>s`. Page de livre : `p. <n>` sans lien. Jamais de repère reconstitué.
- **Leçon tirée de l'analyse** (et non de la source, par ex. tirée des points faibles) : ligne sans repère, préfixée « Leçon tirée des faiblesses de la source → ».
- **« Mon avis »** : le texte validé par l'utilisateur, mot pour mot.
`````

- [ ] **Step 3: Écrire `skills/zettelkasten/SKILL.md`**

`````markdown
---
name: zettelkasten
description: À utiliser pour conserver dans le vault Obsidian « Second Cerveau 2 » les idées tirées d'un contenu externe (vidéo, article, livre, podcast, page web) sous forme Zettelkasten — une note de littérature et des fiches permanentes atomiques, liées entre elles, dans `Connaissances/Prise de notes/`. Déclenche ce skill quand l'utilisateur tape « /zettelkasten », accepte de conserver une analyse faite par /analyse-contenu, ou demande de « créer les fiches », « faire des fiches permanentes / Zettelkasten », « garder ces idées dans mon second cerveau ». Fonctionne aussi seul, pour une idée que l'utilisateur dicte. Ne l'utilise pas pour une connaissance acquise pendant une session de travail (c'est /add-knowledge), ni pour un journal de projet (c'est /add-journal).
---

# Zettelkasten

Tu transformes une analyse en fiches qui dureront.

Une idée lue n'est retenue que si elle est écrite seule, dans des mots simples, et reliée à ce qu'on sait déjà. Ton rôle : proposer ces fiches, les faire valider par l'utilisateur, puis les écrire dans son vault sans jamais toucher à ce qui existe.

## Emplacement

Dossier cible, fixe :

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes
```

Le chemin contient des espaces : cite-le systématiquement en shell.

**S'il est absent, arrête-toi et dis-le.** Ne crée jamais ce dossier ailleurs, ne devine pas un autre vault.

Tu n'écris **que des fichiers nouveaux** dans ce dossier. Tu ne modifies aucun fichier existant — ni fiche, ni note de littérature, ni `../_INDEX.md` (il appartient à `/add-knowledge`). Les liens vers les fiches existantes partent des nouvelles fiches ; le sens inverse est couvert par les backlinks d'Obsidian.

## Modes d'entrée

1. **Après une analyse.** La conversation contient une sortie de `/analyse-contenu` (sections Source, Thèse, Idées candidates, Faits solides, Points faibles, Non vérifiable, Avis proposé). Tu produis une note de littérature et ses fiches permanentes.
2. **Idée dictée.** Pas d'analyse dans la conversation : l'utilisateur te donne une idée. Tu produis **une fiche seule**, sans note de littérature. Demande-lui la source s'il ne l'a pas donnée (note existante, lien, livre…) ; s'il n'en a pas, omets le champ `source`.

Si l'utilisateur te donne un contenu brut à conserver sans analyse, propose d'abord `/analyse-contenu` : tu ne juges pas un contenu, tu écris ce qui a été jugé.

## Méthode

Dans cet ordre, sans sauter d'étape :

1. **Vérifie le dossier** (`test -d`), puis lis les fiches existantes : titres, `id`, `type`, `tags`.
   ```bash
   D="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes"
   grep -H '^title:\|^id:\|^type:' "$D"/*.md
   grep -h '^  - "#' "$D"/*.md | sort | uniq -c | sort -rn
   ```
   Lis le corps des fiches dont le titre est proche d'une idée candidate, pour juger d'un doublon.
2. **Propose la liste des fiches**, numérotée, 10 au maximum :
   ```
   1. <Titre-affirmation>
      Idée : <une phrase>
      Liens : [[<fiche existante>]], … (ou « aucun »)
   2. …
   ⚠ 3. Déjà couvert par [[<fiche existante>]] → je la lierai depuis la note de littérature au lieu de créer une fiche.
   ```
   Puis demande : quelles fiches garder, renommer, rejeter ? **Attends la réponse.**
3. **Propose l'encadré** « Thèse » et « Mon avis » (à partir de la Thèse et de l'Avis proposé de l'analyse). **Attends la validation ou la correction.** En mode idée dictée, saute cette étape.
4. **Calcule les `id`** : premier `id` = max(heure courante `date +%Y%m%d%H%M`, plus grand `id` existant + 1) ; la note de littérature prend le premier, chaque fiche le suivant (+1 minute, en respectant le passage à l'heure). Vérifie qu'aucun n'existe déjà.
5. **Lis les gabarits** `references/note-litterature.md` et `references/fiche-permanente.md` (chemins relatifs à ce skill), et rédige en les suivant exactement.
6. **Vérifie avant d'écrire** : pour chaque fichier, `test -e "$D/<title>.md"`. S'il existe, **n'écris pas** : demande un autre titre.
7. **Écris** la note de littérature puis les fiches. La liste « Idées extraites → fiches permanentes » de la note pointe vers chaque fiche créée ; chaque fiche a `source: "[[<titre de la note de littérature>]]"`.
8. **Contrôle** : chaque `[[lien]]` écrit correspond à un fichier présent dans `$D` ; corrige sinon.

## Règles d'écriture

- **Titre** : une affirmation citable seule. Jamais de `:` (remplace par ` - `), jamais `/ \ * ? " < > |`. Le nom de fichier est le titre + `.md`, à l'identique.
- **Note de littérature** : titre suffixé par le type — `(vidéo)`, `(article)`, `(livre)`, `(podcast)`, `(page)`.
- **Fidélité** : tu ne reprends que ce que contient l'analyse validée. Pas de fait, d'exemple, de chiffre ou de repère horodaté ajouté.
- **Langage simple** : phrases courtes, compréhensibles sans avoir vu la source.
- **Tags** : réutilise d'abord ceux qui existent ; 2 à 4 par fichier.
- **Date** : `date_created` = date du jour, `AAAA-MM-JJ`.

## Contraintes

- **10 fiches maximum par contenu.** Au-delà, demande à l'utilisateur de trier.
- **Rien n'est écrit sans validation** de la liste (étape 2) et de l'avis (étape 3).
- **Aucun fichier existant modifié, aucun fichier écrasé.**
- Dossier absent → arrêt.

## Sortie obligatoire

Après écriture :

```
Créés dans Prise de notes/ :
- <titre> (literature-note, id <id>)
- <titre> (zettelkasten, id <id>)
- …
Liées à des fiches existantes : [[…]], [[…]] (ou « aucune »)
Non créées (déjà couvertes) : [[…]] (ou « aucune »)
```

## Règle finale

Une fiche = une idée, validée par l'utilisateur, écrite dans un fichier **nouveau**. Jamais plus de 10 fiches par contenu, jamais un fichier existant modifié ou écrasé, jamais un fait que l'analyse ne contient pas.
`````

- [ ] **Step 4: Vérifier les invariants**

```bash
S=skills/zettelkasten
head -3 $S/SKILL.md | grep -q '^name: zettelkasten$' && echo ok-name
grep -c 'Prise de notes' $S/SKILL.md                     # ≥ 2
grep -q 'references/note-litterature.md' $S/SKILL.md && grep -q 'references/fiche-permanente.md' $S/SKILL.md && echo ok-refs
test -f $S/references/note-litterature.md && test -f $S/references/fiche-permanente.md && echo ok-files
grep -c '10' $S/SKILL.md                                 # ≥ 2 (Contraintes + Règle finale)
grep -q 'type: literature-note' $S/references/note-litterature.md && grep -q 'type: zettelkasten' $S/references/fiche-permanente.md && echo ok-types
grep -n 'zettlekasten' -r $S || echo ok-orthographe
```
Expected : `ok-name`, `ok-refs`, `ok-files`, `ok-types`, `ok-orthographe`, et les deux comptes ≥ 2.

- [ ] **Step 5: Commit**

```bash
git add skills/zettelkasten
git commit -m "feat: ajoute le skill zettelkasten et ses gabarits

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Skill `analyse-contenu`

**Files:**
- Create: `skills/analyse-contenu/SKILL.md`

**Interfaces:**
- Produces : le contrat d'analyse — 7 sections titrées exactement `Source`, `Thèse`, `Idées candidates`, `Faits solides`, `Points faibles`, `Non vérifiable`, `Avis proposé` — que Task 1 consomme.

- [ ] **Step 1: Écrire `skills/analyse-contenu/SKILL.md`**

`````markdown
---
name: analyse-contenu
description: À utiliser pour analyser de façon critique et fidèle un contenu externe — vidéo (transcription), article, livre, podcast, page web — désigné par un lien, un titre ou un thème et fourni par copier-coller ou en fichier : thèse, idées tangibles à retenir, faits solides, points faibles, ce qui reste invérifiable. Déclenche ce skill quand l'utilisateur tape « /analyse-contenu », demande « analyse ce contenu / cette vidéo / cet article », « qu'est-ce qu'il faut retenir de ça ? », « c'est fiable ? », « démêle le vrai du faux ». N'écrit rien dans le vault : la conservation est le travail de /zettelkasten, proposé à la fin. Ne l'utilise pas pour une connaissance acquise pendant une session de travail (c'est /add-knowledge).
---

# Analyse de contenu

Tu es un lecteur critique et scrupuleux.

L'utilisateur veut savoir ce qu'un contenu apporte vraiment : ce qu'il affirme, ce qui tient, ce qui ne tient pas, et ce qui mérite d'être retenu. Ton rôle : rendre une analyse **fidèle** — sans imaginer, sans spéculer, sans déformer — qui servira ensuite à écrire des fiches. Une analyse qui invente un chiffre ou prête à l'auteur une idée qu'il n'a pas dite est pire que pas d'analyse.

## Entrée

L'utilisateur fournit un lien, un titre ou un thème, et normalement le contenu. Résous l'entrée ainsi :

| Ce qui est fourni | Ce que tu fais |
| --- | --- |
| Contenu collé ou fichier | Tu l'analyses. Lis le fichier **en entier** (par tranches s'il est long). |
| Lien vers une page web, sans contenu | Tu récupères le texte de la page, puis tu l'analyses. |
| Lien vidéo ou audio, sans transcription | Tu t'arrêtes et demandes la transcription (ou le texte). |
| Page inaccessible, paywall, texte vide | Tu t'arrêtes, tu dis pourquoi, tu demandes le texte. |
| Titre ou thème seul | Tu demandes le contenu. **Tu n'analyses jamais de mémoire.** |

Si tu n'as pu lire qu'une partie du contenu, dis-le en tête de la sortie et précise jusqu'où tu as lu.

## Contraintes

- **Trois registres, jamais mélangés** : *ce que dit la source* (Thèse, Idées candidates), *ce que tu en sais* (Faits solides, Points faibles), *ce que tu ne peux pas trancher* (Non vérifiable).
- **Fidélité** : chaque idée attribuée à la source doit s'y trouver. Pas d'idée ajoutée, pas de nuance retirée, pas de conclusion plus forte que celle de l'auteur.
- **Aucune invention** : ne complète jamais un chiffre, une date, un nom, une citation ; n'invente aucune source.
- **Web seulement en cas de doute** : pour un chiffre, un fait daté ou un fait récent dont tu n'es pas sûr, cherche une source primaire et cite-la. Sans source fiable trouvée : « Non vérifiable ». Ne tranche jamais au hasard.
- **Repères** : garde l'horodatage, la page ou la section quand la source les donne. N'en reconstitue jamais.
- **10 idées candidates maximum.**
- **Tu n'écris rien dans le vault.**

## Méthode

1. **Identifie la source** : titre exact, type (vidéo, article, livre, podcast, page), auteur s'il est indiqué, lien.
2. **Lis tout le contenu** avant d'écrire quoi que ce soit.
3. **Formule la thèse** en 2-3 phrases, avec les mots de l'auteur quand c'est possible.
4. **Relève les affirmations vérifiables** (chiffres, faits, dates, causalités) et classe chacune : solide, faible (avec la raison : fausse, sans source, comparaison bancale, contradiction, conflit d'intérêts, cause concurrente ignorée), ou non vérifiable.
5. **Choisis les idées candidates.** Une idée mérite d'être retenue si elle est **tangible** (fait établi, mécanisme, méthode, critère de décision) et **réutilisable hors de ce contenu**. Écarte les opinions non argumentées, les anecdotes sans portée, les chiffres faibles. Formule chacune comme une affirmation simple. Une leçon tirée des points faibles peut être une idée : marque-la « (leçon tirée de l'analyse) », elle n'est pas attribuée à la source.
6. **Propose un avis** : 1-2 phrases sur la valeur du contenu (ce qui est utile, ce qui ne l'est pas), présentées comme une proposition à corriger.

## Sortie obligatoire

Exactement ces sections, dans cet ordre. Une section sans contenu porte « Aucun. »

```
## Source
<Titre exact> — <type> — <auteur ou « auteur non indiqué »> — <lien ou « pas de lien »>
<Si lecture partielle : « Lu jusqu'à <repère> sur <total>. »>

## Thèse
<2-3 phrases>

## Idées candidates
1. <affirmation> — <repère : MM:SS, p. n, section… ou « sans repère »>
2. …

## Faits solides
- <fait> <(source : …) si vérifié par recherche>

## Points faibles
- <affirmation> : <raison>

## Non vérifiable
- <affirmation>

## Avis proposé
<1-2 phrases>
```

Puis, sur une ligne : « Je conserve ces idées avec /zettelkasten ? »

## Règle finale

Rien que la source dans « ce que dit la source », rien d'inventé nulle part, « Non vérifiable » plutôt qu'une supposition, 10 idées candidates au maximum — et aucune écriture dans le vault.
`````

- [ ] **Step 2: Vérifier les invariants**

```bash
S=skills/analyse-contenu/SKILL.md
head -3 $S | grep -q '^name: analyse-contenu$' && echo ok-name
for h in Source Thèse 'Idées candidates' 'Faits solides' 'Points faibles' 'Non vérifiable' 'Avis proposé'; do grep -q "^## $h$" $S && echo "ok-$h"; done
grep -q '/zettelkasten' $S && echo ok-handoff
grep -c '10' $S                                          # ≥ 2
```
Expected : `ok-name`, 7 lignes `ok-…`, `ok-handoff`, compte ≥ 2. Les en-têtes `## …` du contrat se trouvent dans le bloc de sortie, d'où le `^## ` exact.

- [ ] **Step 3: Vérifier la cohérence du contrat entre les deux skills**

```bash
for h in Source Thèse 'Idées candidates' 'Faits solides' 'Points faibles' 'Non vérifiable' 'Avis proposé'; do grep -q "$h" skills/zettelkasten/SKILL.md || echo "MANQUE dans zettelkasten : $h"; done
```
Expected : aucune sortie.

- [ ] **Step 4: Commit**

```bash
git add skills/analyse-contenu
git commit -m "feat: ajoute le skill analyse-contenu

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: README et fumigation manuelle

**Files:**
- Modify: `README.md` (tableau « Skills disponibles », après la ligne `add-journal`)

**Interfaces:**
- Consumes : les deux skills des Tasks 1 et 2.

- [ ] **Step 1: Ajouter deux lignes au tableau du README, après `add-journal`**

```markdown
| [`analyse-contenu`](skills/analyse-contenu/SKILL.md)                   | Analyse critique et fidèle d'un contenu externe (vidéo, article, livre, podcast, page) fourni par lien, collage ou fichier : thèse, idées tangibles, faits solides, points faibles, non vérifiable. Recherche web seulement en cas de doute. N'écrit rien ; propose `zettelkasten`. |
| [`zettelkasten`](skills/zettelkasten/SKILL.md)                         | Conserve une analyse dans le vault Obsidian sous forme Zettelkasten : une note de littérature et des fiches permanentes atomiques dans `Connaissances/Prise de notes/`, d'après des gabarits fournis en `references/`. Fiches validées une à une, aucun fichier existant modifié. |
```

- [ ] **Step 2: Préparer un bac à sable**

```bash
SB=/private/tmp/claude-501/zk-test   # ou le scratchpad de la session
rm -rf "$SB"; mkdir -p "$SB/Prise de notes"
cp "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes/"*.md "$SB/Prise de notes/"
ls "$SB/Prise de notes" | wc -l      # 16
```

Écrire `$SB/contenu-test.md` — article fictif, **sans horodatage**, avec un titre contenant `:`, une idée qui recoupe une fiche existante, un chiffre sans source et un fait solide :

```markdown
Titre : IA : pourquoi les centres de données attendent le réseau
Auteur : non indiqué — article de blog

Les centres de données pour l'IA se construisent en deux ans, mais leur raccordement au réseau électrique demande souvent cinq à dix ans. Le facteur limitant n'est donc pas la puce mais le câble.

Selon l'auteur, « 92 % des projets de data centers sont retardés par le réseau ».

La puissance d'un centre se compte en MW installés ; sa consommation réelle dépend de son taux d'utilisation, toujours inférieur à 100 %.

L'auteur conclut que la flexibilité — décaler les calculs aux heures creuses — permettrait de raccorder plus vite.
```

- [ ] **Step 3: Fumigation `/analyse-contenu`**

Dans une session Claude Code, invoquer `/analyse-contenu` sur `$SB/contenu-test.md`. Contrôler :
- les 7 sections présentes, dans l'ordre ;
- « 92 % » en Points faibles ou Non vérifiable, jamais en Faits solides sans source citée ;
- aucune idée candidate avec un horodatage (le texte n'en a pas) → « sans repère » ;
- aucune idée absente du texte attribuée à la source ;
- la dernière ligne propose `/zettelkasten`.

- [ ] **Step 4: Fumigation `/zettelkasten` dans le bac à sable**

Accepter la proposition, en précisant : « Pour ce test, utilise `$SB/Prise de notes` comme dossier cible au lieu du vault. » Contrôler :
- liste proposée avant toute écriture, attente de validation ;
- l'idée de raccordement signalée comme couverte par `[[Raccorder prend plus de temps que produire]]` (et/ou flexibilité par `[[La flexibilité est le gisement de capacité le moins cher]]`), pas dupliquée ;
- note de littérature nommée `IA - pourquoi les centres de données attendent le réseau (article).md` (`:` remplacé) ;

```bash
cd "$SB/Prise de notes"
ls | wc -l                                               # 16 + fichiers créés
git diff --no-index --stat "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes" . | grep -v ' (new)\|^ .*=> ' ; # aucun fichier existant modifié
grep -h '^id:' *.md | sort | uniq -d                     # aucune sortie : ids uniques
for f in *.md; do t=$(sed -n 's/^title: //p' "$f"); [ "$t.md" = "$f" ] || echo "title≠fichier : $f"; done
grep -oh '\[\[[^]|]*' *.md | sed 's/\[\[//' | sort -u | while read -r l; do [ -e "$l.md" ] || echo "lien cassé : $l"; done
```
Expected : ids sans doublon, aucun `title≠fichier`, aucun lien cassé (les liens vers des notes hors `Prise de notes/` déjà présents dans les fiches existantes, comme `[[Bob Doto]]`, peuvent apparaître : ne compter que ceux des nouveaux fichiers). Contrôler aussi que le diff ne montre que des fichiers ajoutés.

- [ ] **Step 5: Fumigation du mode « idée dictée »**

Nouvelle session, sans analyse : `/zettelkasten` « Une estimation sans source ne vaut pas un chiffre » (dossier cible = bac à sable). Contrôler : une seule fiche, pas de note de littérature, le skill demande une source.

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: référence analyse-contenu et zettelkasten dans le README

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Un essai réel dans le vault (dossier cible réel) se fait ensuite avec l'accord explicite de l'utilisateur.
