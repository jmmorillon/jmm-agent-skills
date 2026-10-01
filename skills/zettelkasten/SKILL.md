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
