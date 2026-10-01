---
name: zettelkasten
description: À utiliser pour conserver dans le vault Obsidian « Second Cerveau 2 » les idées tirées d'un contenu externe (vidéo, article, livre, podcast, page web) sous forme Zettelkasten — une note de littérature et des fiches permanentes atomiques, liées entre elles, dans `Connaissances/Prise de notes/`. Déclenche ce skill quand l'utilisateur tape « /zettelkasten », accepte de conserver une analyse faite par /analyse-contenu, ou demande de « créer les fiches », « faire des fiches permanentes / Zettelkasten », « garder ces idées dans mon second cerveau ». Fonctionne aussi seul, pour une idée que l'utilisateur dicte. Ne l'utilise pas pour une connaissance acquise pendant une session de travail (c'est /add-knowledge), ni pour un journal de projet (c'est /add-journal).
---

# Zettelkasten

Tu transformes une analyse en fiches qui dureront.

Une idée lue n'est retenue que si elle est écrite seule, dans des mots simples, et reliée à ce qu'on sait déjà. Ton rôle : proposer ces fiches, les faire valider par l'utilisateur, puis les écrire dans son vault sans jamais toucher à ce qui existe.

## Emplacement

Dossier cible, fixe (noté `$D` dans la suite) :

```bash
D="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances/Prise de notes"
```

Le chemin contient des espaces : cite-le toujours entre guillemets.

**S'il est absent, arrête-toi et dis-le.** Ne crée jamais ce dossier ailleurs, ne devine pas un autre vault.

Tu n'écris **que des fichiers nouveaux** dans ce dossier. Tu ne modifies aucun fichier existant — ni fiche, ni note de littérature, ni `../_INDEX.md` (il appartient à `/add-knowledge`). Les liens vers les fiches existantes partent des nouvelles fiches ; le sens inverse est couvert par les backlinks d'Obsidian. Si tu remarques un défaut dans un fichier existant (YAML invalide, lien cassé), signale-le à l'utilisateur sans le corriger.

## Modes d'entrée

1. **Après une analyse.** La conversation contient une sortie de `/analyse-contenu` (sections Source, Thèse, Idées candidates, Faits solides, Points faibles, Non vérifiable, Avis proposé). Tu produis une note de littérature et ses fiches permanentes.
2. **Idée dictée.** Pas d'analyse dans la conversation : l'utilisateur te donne une idée. Tu produis **une fiche seule**, sans note de littérature. Les étapes marquées *(analyse)* ci-dessous ne s'appliquent pas.

Si l'utilisateur te donne un contenu brut à conserver sans analyse, propose d'abord `/analyse-contenu` : tu ne juges pas un contenu, tu écris ce qui a été jugé.

## Méthode

Dans cet ordre, sans sauter d'étape :

1. **Inventaire.** Vérifie le dossier (`test -d "$D"`), puis relève les fichiers existants — noms (y compris ceux sans frontmatter), `title`, `id`, `type`, `tags` :
   ```bash
   ls "$D"
   grep -H '^title:\|^id:\|^type:' "$D"/*.md 2>/dev/null
   grep -h '^  - "#' "$D"/*.md 2>/dev/null | sort | uniq -c | sort -rn
   ```
   Lis le corps des fichiers dont le nom est proche d'une idée à conserver, pour juger d'un doublon.
2. **Source** *(idée dictée)*. Si l'utilisateur ne l'a pas donnée, demande-la : note existante, lien, livre… S'il n'en a pas, le champ `source` sera omis.
3. **Propose la liste**, en deux groupes. Une idée est **couverte** si une fiche existante affirme la même chose ; si l'idée nouvelle ajoute une nuance ou un cas que la fiche n'a pas, c'est une fiche nouvelle, liée à l'existante.
   ```
   À créer (au plus 10) :
   1. <Titre-affirmation>
      Idée : <une phrase>
      Liens : [[<fiche existante>]], … (ou « aucun »)
   2. …

   Déjà couvertes — liées depuis la note de littérature, pas de fiche nouvelle :
   - <idée> → [[<fiche existante>]]
   ```
   Puis demande : « Je crée les fiches 1 à N ? Tu peux en renommer, en rejeter, ou me faire créer une idée couverte. » Pour une idée dictée, présente la fiche seule et demande : « Je la crée avec ce titre ? »

   **Si aucune fiche n'est à créer** *(analyse)*, dis-le et demande : « J'écris seulement la note de littérature, ou rien ? » **Attends la réponse.**
4. **Encadré** *(analyse)*. Propose la Thèse et le « Mon avis » (à partir de la Thèse et de l'Avis proposé de l'analyse). L'utilisateur peut corriger l'une et l'autre. **Attends la validation.**
5. **`id`.** Premier `id` = le plus grand entre l'heure courante et (plus grand `id` existant + 1 minute). Le premier fichier écrit le prend (la note de littérature s'il y en a une), chaque fichier suivant ajoute 1 minute (le passage à l'heure ou au jour suivant se fait naturellement) :
   ```bash
   date +%Y%m%d%H%M                                   # heure courante
   date -j -v+1M -f %Y%m%d%H%M 202610011559 +%Y%m%d%H%M  # +1 minute → 202610011600
   ```
   Un `id` peut ainsi dépasser l'heure réelle : c'est voulu, il doit rester unique et croissant.
6. **Rédige** en suivant exactement les gabarits `references/note-litterature.md` *(analyse)* et `references/fiche-permanente.md` (chemins relatifs à ce skill), et les règles ci-dessous.
7. **Vérifie avant d'écrire** : pour chaque fichier, `test -e "$D/<title>.md"`. S'il existe, **n'écris pas** : demande un autre titre.
8. **Écris** la note de littérature *(analyse)* puis les fiches.
9. **Contrôle** : chaque `[[lien]]` écrit correspond à un fichier présent dans `$D` ; corrige sinon.

## Règles d'écriture

- **Titres** : jamais de `:` (remplace par ` - `), jamais `/ \ * ? " < > |`. Le nom de fichier est le titre + `.md`, à l'identique.
  - **Fiche** : titre = une affirmation citable seule. Pour une idée dictée qui est déjà une affirmation, garde la formulation de l'utilisateur.
  - **Note de littérature** : titre = celui de la source, suffixé par le type — `(vidéo)`, `(article)`, `(livre)`, `(podcast)`, `(page)`.
- **YAML** : toute valeur qui contient `:`, `«`, `#`, ou commence par `[`, s'écrit entre guillemets doubles (un `"` intérieur devient `\"`). `source` est toujours entre guillemets.
- **Fidélité** :
  - *Après une analyse* : tu ne reprends que ce que contient l'analyse validée. Pas de fait, d'exemple, de chiffre ou de repère ajouté. Une section « Aucun. » de l'analyse disparaît de la note.
  - *Idée dictée* : tu développes uniquement ce que l'utilisateur a dit ou validé. Toute phrase ajoutée (reformulation, règle pratique) figure dans la proposition de l'étape 3.
  - *Réserves de l'analyse* : une raison tirée des Points faibles (ce que l'analyste sait, pas ce que dit la source) n'entre dans une fiche que signalée comme telle, en une ligne commençant par « **Réserve :** ».
  - *Liens* : la justification d'un lien peut décrire le contenu de la fiche liée, que tu as lue. Les liens proposés à l'étape 3 peuvent viser des fiches existantes ou des fiches du même lot.
- **Langage simple** : phrases courtes, compréhensibles sans avoir vu la source.
- **Tags** (note et fiches) : 2 à 4, en minuscules, sans accents, mots séparés par `-`, préfixés `#`, entre guillemets. Réutilise un tag existant seulement s'il veut dire la même chose ; sinon crée-en un.
- **Date** : `date_created` = date du jour, `AAAA-MM-JJ`.

## Contraintes

- **10 fiches nouvelles maximum par contenu.** Au-delà, demande à l'utilisateur de trier. Les idées couvertes ne comptent pas.
- **Rien n'est écrit sans validation** de la liste (étape 3) et, après une analyse, de l'encadré (étape 4).
- **Aucun fichier existant modifié, aucun fichier écrasé.**
- Dossier absent → arrêt.

## Sortie obligatoire

Après écriture :

```
Créés dans Prise de notes/ :
- <titre> (literature-note, id <id>)
- <titre> (zettelkasten, id <id>)
(ou « aucun fichier »)
Idées couvertes par une fiche existante : [[…]], … (ou « aucune »)
Autres liens vers l'existant : [[…]], … (ou « aucun »)
```

Les deux dernières listes sont disjointes. Ajoute, le cas échéant, les défauts repérés dans des fichiers existants.

## Règle finale

Une fiche = une idée, validée par l'utilisateur, écrite dans un fichier **nouveau**. Jamais plus de 10 fiches nouvelles par contenu, jamais un fichier existant modifié ou écrasé, jamais un fait que l'analyse ou l'utilisateur n'a pas donné.
