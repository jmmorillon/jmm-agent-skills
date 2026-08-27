# Capture et révision de connaissances — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Créer deux skills, `/add-knowledge` et `/check-knowledge`, qui capturent une connaissance acquise en session dans le vault Obsidian de l'utilisateur puis l'interrogent plus tard sur ce qu'il n'a pas retenu.

**Architecture:** Deux dossiers de skill indépendants sous `skills/`, chacun avec un unique `SKILL.md`. Aucun code : le livrable est du prompt Markdown prescriptif. Les deux skills sont reliés non par du code partagé mais par un **contrat de fichiers dans le vault** — un gabarit de fiche et un index — que chacun redéclare intégralement pour rester lisible seul.

**Tech Stack:** Markdown. Frontmatter YAML (`name`, `description`). Vault Obsidian sur iCloud Drive. `install.sh` du dépôt (symlinks, déjà en place, non modifié).

**Spec:** `docs/superpowers/specs/2026-08-27-knowledge-capture-design.md`

## Global Constraints

Valeurs reprises telles quelles de la spec. Elles s'appliquent à toutes les tâches.

- **Langue** : français, dans les skills comme dans les fiches produites. Convention du dépôt (`CLAUDE.md` : « Author language is French »).
- **Nommage** : dossier de skill en kebab-case, et le `name:` du frontmatter est identique au nom du dossier.
- **Chemin du vault**, écrit en dur dans les deux skills :
  `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances`
  Il contient des espaces : toujours le citer en shell. Si le dossier est absent, le skill s'arrête et le signale ; il ne crée jamais d'arborescence ailleurs.
- **Périmètre d'écriture** : uniquement `_INDEX.md` et les fichiers thématiques créés par les skills. Les notes autonomes préexistantes (`Développement/GIT/`, `Développement/Skills IA/`, `Prise de notes/`, `Caméra LAPI.md`) sont référençables, jamais modifiées.
- **Trois niveaux de maîtrise** : `neuf`, `fragile`, `acquis`. Pas d'autre valeur.
- **Dates** au format `AAAA-MM-JJ`. Valeur absente : `—` (tiret cadratin).
- **Liens sans alias dans les tableaux Markdown** : `[[cible]]` et jamais `[[cible|libellé]]`, car le `|` casse la cellule.
- **Plafonds** : 10 candidats maximum en bilan de fin de session (`/add-knowledge`) ; 10 questions par défaut dans une session de révision (`/check-knowledge`) ; 30 jours avant de réinterroger une fiche `acquis`.
- **Jamais de batch** : une connaissance à la fois, une question à la fois.
- **Jamais d'écriture sans validation explicite** de l'utilisateur.
- **Pas de test automatisé dans ce dépôt.** Aucune tâche n'introduit de harnais de test. La vérification se fait par contrôle d'invariants (`grep`) sur les fichiers produits, puis par fumigation manuelle (Task 3).

## File Structure

| Fichier | Responsabilité | Task |
| --- | --- | --- |
| `skills/add-knowledge/SKILL.md` | Prompt de capture : détecter le moment, faire reformuler, rédiger la fiche, écrire le fichier thématique et la ligne d'index. | 1 |
| `skills/check-knowledge/SKILL.md` | Prompt d'interrogation : choisir quoi demander depuis l'index, poser, évaluer, mettre à jour l'état de révision. | 2 |

Pas d'autre fichier. **`install.sh` n'est pas modifié** : sa boucle `for src in "$SKILLS_SRC"/*/` (`install.sh:220`) ramasse tout nouveau dossier de skill. Il n'y a pas non plus d'index central de skills à mettre à jour (`CLAUDE.md` : « There is no central index or registry to update — discovery is by directory listing »).

---

### Task 1: Skill `/add-knowledge`

**Files:**
- Create: `skills/add-knowledge/SKILL.md`

**Interfaces:**
- Consumes: rien (première tâche).
- Produces: le **contrat de fichiers** que Task 2 relit — gabarit de fiche (section `##` par connaissance, `**À retenir**` en tête, bloc `**Révision**` en paires `Q —` / `R —`) et gabarit d'index (`Connaissances/_INDEX.md`, une section `##` par fichier thématique, tableau à 4 colonnes `Connaissance | Capturée | Revue | Maîtrise`, plus un tableau `Notes autonomes` à 3 colonnes `Note | Revue | Maîtrise`).

- [ ] **Step 1: Créer le dossier du skill**

```bash
mkdir -p skills/add-knowledge
```

- [ ] **Step 2: Écrire `skills/add-knowledge/SKILL.md`**

Écrire ce contenu exact :

````markdown
---
name: add-knowledge
description: À utiliser pour capturer dans le vault Obsidian une connaissance acquise pendant une session — méthode de résolution d'un problème, commande utile, notion mal maîtrisée — sous forme de fiche thématique interrogeable plus tard. Déclenche ce skill quand l'utilisateur tape « /add-knowledge », ou demande de « noter ça », « retenir ça », « ajouter cette connaissance ». Propose-le aussi spontanément, sans qu'on te le demande, juste après avoir résolu un problème non trivial, répondu à une question du type « comment on fait ça ? », ou constaté que l'utilisateur bute une seconde fois sur la même chose — et lors d'un bilan de fin de session, pour ramasser ce qui n'a pas été capturé en chemin.
---

# Add Knowledge

Tu transformes une résolution en apprentissage.

Quand un problème est résolu au cours d'une session, la connaissance disparaît avec elle : ni la commande, ni le modèle mental qui la justifie ne survivent. Ton rôle est de fixer cette connaissance dans le vault Obsidian de l'utilisateur — mais surtout de la lui faire **formuler**, parce qu'une fiche qu'il n'a pas écrite ne fait que déplacer son ignorance dans un fichier.

## Emplacement

Dossier cible, fixe :

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances
```

Le chemin contient des espaces : cite-le systématiquement en shell.

**S'il est absent, arrête-toi et dis-le.** Ne crée jamais cette arborescence ailleurs, ne devine pas un autre vault.

Structure :

```
Connaissances/
  _INDEX.md                    <- sommaire + état de révision
  Développement/
    Réseau.md                  <- fichier thématique incrémental
    GIT/                       <- notes préexistantes, LECTURE SEULE
  IA/
  Prise de notes/
```

**Tu n'écris que dans `_INDEX.md` et dans les fichiers thématiques.** Les notes préexistantes (celles qui vivent dans des sous-dossiers comme `GIT/` ou `Skills IA/`, une note par sujet) sont référençables depuis l'index, jamais modifiées. Les reformater est le travail d'un autre skill.

## Quand te déclencher

Trois portes d'entrée, un seul parcours ensuite.

1. **Invocation explicite** — l'utilisateur tape `/add-knowledge` ou te demande de retenir quelque chose.
2. **Proposition spontanée** — tu proposes toi-même la capture, en une phrase, quand :
   - un problème non trivial vient d'être résolu (une erreur diagnostiquée, une commande trouvée après tâtonnement) ;
   - l'utilisateur a posé une question du type « comment on fait ça ? » et a obtenu sa réponse ;
   - il bute une seconde fois sur quelque chose de déjà rencontré.

   Propose, n'impose pas : une phrase, et tu enchaînes si la réponse est non.
3. **Bilan de fin de session** — quand l'utilisateur clôt la session, liste les connaissances candidates repérées en chemin. **10 candidats maximum.** La liste sert à trier ; elle n'autorise pas le traitement en lot.

## Méthode

Pour chaque connaissance, dans cet ordre :

1. **Isole une connaissance.** Une seule. En mode bilan, présente d'abord la liste numérotée, laisse l'utilisateur choisir, puis traite ses choix un par un.

2. **Lis `_INDEX.md`** avant toute autre chose. Il te donne les thèmes existants et te permet de détecter un doublon. Si une fiche proche existe déjà, **propose de l'enrichir** plutôt que d'en créer une seconde — et dis laquelle.

3. **Pose la question de reformulation.** Une seule, exactement dans cet esprit :

   > En une ou deux phrases, avec tes mots : qu'est-ce qu'il faut retenir de ça ?

   C'est le cœur du skill. N'en pose pas d'autres, n'enchaîne pas sur un interrogatoire.

4. **Rédige la fiche** au gabarit ci-dessous :
   - le `À retenir` reprend la formulation de l'utilisateur. Si elle contient une erreur, corrige-la **et signale la correction explicitement** sous la fiche, en une ligne — c'est là que l'apprentissage se joue ;
   - le corps technique (symptôme, diagnostic, commandes, vérification, piège) est de ta plume : c'est du factuel, autant qu'il soit exact ;
   - rédige 1 à 3 paires Q/R de révision.

5. **Présente la fiche entière** et attends la décision : valider, corriger, annuler.

6. **Écris**, uniquement si validé :
   - ajoute la section **à la fin** du fichier thématique. Ne réordonne rien : l'index est la vue navigable ;
   - crée le fichier thématique s'il n'existe pas, avec son frontmatter ;
   - ajoute la ligne d'index, maîtrise `neuf`.

7. **Confirme en une ligne** : titre de la fiche, fichier, thème.

## Choix du thème

Réutilise un fichier thématique existant dès qu'il convient. N'en crée un nouveau que si aucun ne correspond clairement **et** que le sujet justifie un regroupement (au moins 2-3 fiches attendues à terme). Sinon, place la fiche dans le fichier thématique le plus proche.

Créer un **nouveau dossier de thème racine** demande l'accord explicite de l'utilisateur.

Respecte les conventions du vault : accents et espaces dans les noms (`Développement`, `Prise de notes`), tags hiérarchiques (`Dev/Réseau`).

## Gabarit de fiche

```markdown
---
Titre: Réseau
Tags:
  - Dev/Réseau
Créée le: 2026-08-27
---

# Réseau

## Libérer un port TCP occupé

**À retenir** — Un port est tenu par un *processus*, pas par un projet.
Tant que le process tourne, le port reste pris, même si j'ai fermé
l'onglet et oublié le projet.

**Symptôme** — `address already in use` au démarrage du serveur.
**Diagnostic** — `lsof -i :8791` → PID + nom du process.
**Action** — `kill <PID>`, puis `kill -9 <PID>` s'il résiste.
**Vérification** — `lsof -i :8791` ne renvoie plus rien.
**Piège** — si un watcher relance le serveur, le port se rouvre aussitôt :
couper le watcher d'abord.

**Révision**
- Q — Quelle commande donne le processus qui tient le port 8791 ?
  R — `lsof -i :8791`
- Q — Pourquoi un port peut-il rester pris après avoir fermé le projet ?
  R — Le process tourne toujours ; le port appartient au process.

_Capturée le 2026-08-27 — contexte : serveur PHP de email-api-check._
```

Règles de format :

- Le frontmatter est **au niveau du fichier thématique**, pas de la fiche. Tu ne l'écris qu'à la création du fichier.
- Une fiche = une section `##`. **Son titre est unique dans le fichier** : c'est l'ancre de lien. Si le titre existe déjà, c'est un doublon — retourne à l'étape 2.
- `**À retenir**` est en tête et **obligatoire**.
- `Symptôme`, `Diagnostic`, `Action`, `Vérification`, `Piège` sont **facultatifs**. Une connaissance conceptuelle garde `À retenir`, une explication et `Révision`. **N'écris jamais un champ vide.**
- `Révision` : 1 à 3 paires, format `- Q — …` puis `  R — …`.
- La ligne finale en italique rappelle la date et le contexte d'origine.
- Si l'utilisateur a passé la reformulation, écris `**À retenir** — _(rédigé par l'agent)_ …`.

## Gabarit d'index

`Connaissances/_INDEX.md` :

```markdown
# Index des connaissances

_Maintenu par /add-knowledge et /check-knowledge. Une ligne = une fiche._

## Développement / [[Développement/Réseau]]

| Connaissance | Capturée | Revue | Maîtrise |
| --- | --- | --- | --- |
| [[Développement/Réseau#Libérer un port TCP occupé]] | 2026-08-27 | — | neuf |

## Notes autonomes (hors système, en lecture seule)

| Note | Revue | Maîtrise |
| --- | --- | --- |
| [[Développement/GIT/Utilisation de Git Worktree avec des Agents IA Multiples]] | — | neuf |
```

Règles :

- **Liens sans alias dans les tableaux.** `[[cible]]`, jamais `[[cible|libellé]]` : le `|` serait lu comme un séparateur de colonne et casserait la cellule. C'est l'erreur la plus facile à commettre ici.
- Une section `##` par fichier thématique, sections dans l'ordre alphabétique.
- Maîtrise à la création : toujours `neuf`. Colonne `Revue` : `—`.
- Les colonnes `Revue` et `Maîtrise` appartiennent à `/check-knowledge`. Tu les initialises, tu ne les fais pas évoluer.
- Crée `_INDEX.md` avec son en-tête s'il n'existe pas.
- Le tableau « Notes autonomes » sert à faire réviser les notes préexistantes. Tu peux y ajouter une ligne, jamais toucher la note elle-même.

## Contraintes

- **Une connaissance à la fois.** Pas de batch, même en mode bilan.
- **N'invente rien.** Ne documente que ce qui a réellement eu lieu dans la conversation. Une commande qui n'a pas été exécutée est signalée comme non vérifiée, ou tu demandes.
- **Aucune écriture sans validation explicite.**
- Ne modifie jamais une note préexistante.
- N'efface jamais une fiche. Enrichir ≠ remplacer.
- Si le vault est absent ou inaccessible, arrête-toi et dis-le.

## Sortie obligatoire

Réponds en français. Avant d'écrire, présente exactement ce bloc :

---

**Connaissance** : _titre de la fiche_
**Fichier** : `Développement/Réseau.md` _(existant / **nouveau**)_
**Action** : nouvelle fiche / enrichissement de « _titre existant_ »

```markdown
_la fiche complète, au gabarit_
```

_Correction apportée à ta formulation_ : _(une ligne, uniquement s'il y en a une)_

→ **Valider, corriger ou annuler ?**

---

Après écriture, une seule ligne de confirmation :

`✓ « Libérer un port TCP occupé » → Développement/Réseau.md — index à jour (neuf)`

## Règle finale

**Une connaissance à la fois. 10 candidats maximum en bilan de fin de session.** Tu poses **une seule** question de reformulation. Tu n'écris rien sans validation explicite. Tu ne touches jamais aux notes préexistantes. Dans les tableaux de l'index, les liens sont **sans alias**.
````

- [ ] **Step 3: Vérifier les invariants du fichier produit**

Run :

```bash
head -3 skills/add-knowledge/SKILL.md
grep -c 'name: add-knowledge' skills/add-knowledge/SKILL.md
grep -c 'Second cerveau 2' skills/add-knowledge/SKILL.md
grep -c '10 candidats' skills/add-knowledge/SKILL.md
grep -c 'sans alias' skills/add-knowledge/SKILL.md
grep -n 'Règle finale' skills/add-knowledge/SKILL.md
```

Expected : la première ligne est `---` et la deuxième `name: add-knowledge` ; chacun des quatre `grep -c` renvoie au moins `1` ; `Règle finale` apparaît **une fois, dans le dernier tiers du fichier** (convention du dépôt : la limite non évidente est réaffirmée en clôture).

- [ ] **Step 4: Vérifier qu'aucun lien aliasé n'a été écrit dans un tableau**

Run :

```bash
grep -n '\[\[[^]]*|' skills/add-knowledge/SKILL.md
```

Expected : **exactement une ligne**, celle qui *interdit* cette forme (`[[cible|libellé]]` cité comme contre-exemple). Toute autre ligne remontée est un vrai lien aliasé, à corriger.

- [ ] **Step 5: Vérifier que le vault cible existe**

Run :

```bash
ls -d "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances"
```

Expected : le chemin s'affiche. S'il échoue, **ne corrige pas le skill** — signale-le, le chemin de la spec est peut-être devenu faux (iCloud peut renommer, le vault peut être délocalisé) et c'est une décision de l'utilisateur.

- [ ] **Step 6: Commit**

```bash
git add skills/add-knowledge/SKILL.md
git commit -m "feat: skill add-knowledge — capture d'une connaissance dans le vault"
```

---

### Task 2: Skill `/check-knowledge`

**Files:**
- Create: `skills/check-knowledge/SKILL.md`

**Interfaces:**
- Consumes: le contrat de fichiers produit par Task 1 — `Connaissances/_INDEX.md` (sections `##` par fichier thématique, tableau `Connaissance | Capturée | Revue | Maîtrise`, tableau `Note | Revue | Maîtrise`), et le bloc `**Révision**` en paires `- Q — …` / `  R — …` dans chaque fiche.
- Produces: les colonnes `Revue` (date `AAAA-MM-JJ`) et `Maîtrise` (`neuf` / `fragile` / `acquis`) de l'index, mises à jour après chaque réponse.

- [ ] **Step 1: Créer le dossier du skill**

```bash
mkdir -p skills/check-knowledge
```

- [ ] **Step 2: Écrire `skills/check-knowledge/SKILL.md`**

Écrire ce contenu exact :

````markdown
---
name: check-knowledge
description: À utiliser pour interroger l'utilisateur sur les connaissances capturées dans son vault Obsidian et vérifier ce qu'il a réellement retenu. Déclenche ce skill quand il tape « /check-knowledge », ou demande « interroge-moi », « teste-moi », « fais-moi réviser », « est-ce que j'ai retenu ? » — éventuellement en précisant un thème (« interroge-moi sur le réseau ») ou un nombre de questions. Ne le déclenche pas de toi-même : réviser se décide, ça ne s'impose pas au milieu d'un travail.
---

# Check Knowledge

Tu vérifies ce que l'utilisateur a réellement retenu — pas ce qui est écrit dans son vault.

Une fiche relue n'est pas une fiche sue. Ton rôle est de poser des questions dont la réponse ne se trouve pas sous les yeux, d'évaluer sans complaisance, et de tenir à jour ce qui est acquis et ce qui glisse.

## Emplacement

Dossier cible, fixe :

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances
```

Le chemin contient des espaces : cite-le systématiquement en shell.

**S'il est absent, ou si `_INDEX.md` n'existe pas, arrête-toi et dis-le** — il n'y a rien à réviser, et c'est `/add-knowledge` qui crée l'index.

## Session

Par défaut **10 questions, une à la fois**. L'utilisateur peut préciser :
- un **thème** (« interroge-moi sur le réseau ») → restreins la sélection à ce fichier thématique ;
- un **nombre** (« 3 questions ») → respecte-le ;
- **arrêter en cours de route** → le récapitulatif porte alors sur les questions déjà posées.

S'il reste moins de fiches disponibles que de questions demandées, dis-le et pose ce qu'il y a. Ne repose pas deux fois la même fiche dans une session.

## Méthode

1. **Lis `_INDEX.md`** et sélectionne les fiches à demander, dans cet ordre de priorité :
   1. maîtrise `neuf` (jamais révisée) — et parmi elles, d'abord celles dont le `À retenir` est marqué `_(rédigé par l'agent)_` : ce sont celles que l'utilisateur n'a pas formulées, donc pas digérées. Ce marqueur n'est pas dans l'index : pour le voir, ouvre les fiches `neuf` — elles seules, pas tout le vault ;
   2. maîtrise `fragile` ;
   3. maîtrise `acquis` dont la colonne `Revue` date de **plus de 30 jours**.

   Si les trois catégories sont vides, dis-le : tout est à jour, il n'y a rien à réviser.

2. **Lis la fiche** correspondante dans son fichier thématique, pour toi seul.

3. **Pose la question sans afficher la fiche.** Pars des paires Q/R du bloc `Révision`, mais ne t'y enferme pas : reformule, demande le *pourquoi* plutôt que le *comment*, ou croise deux fiches d'un même thème. Sinon l'utilisateur mémorise la formulation de la question, pas la réponse.

   **Ne donne jamais la réponse dans l'énoncé.** Pas d'indice, pas de commande citée, pas de choix multiple sauf s'il le demande.

4. **Attends la réponse.** Une question à la fois. N'enchaîne pas.

5. **Évalue** en comparant à la fiche : ce qui est juste, ce qui manque, ce qui est faux. Factuel, sur la réponse — jamais sur la personne. S'il sèche, donne la réponse complète : une révision n'est pas un examen.

6. **Mets à jour l'index** :

   | Réponse | Nouvelle maîtrise |
   | --- | --- |
   | juste et complète | `acquis` |
   | approximative ou partielle | `fragile` |
   | fausse, ou « je ne sais pas » | `neuf` |

   Plus la date du jour dans la colonne `Revue`. Une fiche `acquis` répondue faussement redescend donc à `neuf`.

7. **Boucle de retour.** Si la réponse était fausse *parce que la fiche est confuse, incomplète ou datée* — pas parce qu'il a oublié — dis-le et propose de la corriger. **Attends sa validation avant d'écrire quoi que ce soit dans la fiche.** C'est ce qui empêche le vault de fossiliser une mauvaise explication.

8. **Enchaîne** la question suivante.

## Gabarit d'index

C'est le fichier que tu lis pour choisir, et la seule chose que tu écris.

```markdown
# Index des connaissances

_Maintenu par /add-knowledge et /check-knowledge. Une ligne = une fiche._

## Développement / [[Développement/Réseau]]

| Connaissance | Capturée | Revue | Maîtrise |
| --- | --- | --- | --- |
| [[Développement/Réseau#Libérer un port TCP occupé]] | 2026-08-27 | — | neuf |

## Notes autonomes (hors système, en lecture seule)

| Note | Revue | Maîtrise |
| --- | --- | --- |
| [[Développement/GIT/Utilisation de Git Worktree avec des Agents IA Multiples]] | — | neuf |
```

Tu modifies **une cellule `Revue` et une cellule `Maîtrise`** par question, rien d'autre. Tu ne réordonnes pas les lignes, tu n'en ajoutes pas, tu n'en supprimes pas.

## Sortie obligatoire

Réponds en français.

Pour poser une question :

---

**Question 3/10** — _Développement / Réseau_

_l'énoncé, sans indice_

---

Après la réponse de l'utilisateur :

---

**Verdict** : juste / approximatif / faux

_Ce qui était juste_ : _(une ligne)_
_Ce qui manquait_ : _(une ligne, si applicable)_

**Index** : « Libérer un port TCP occupé » → `acquis` (2026-08-27)

---

En fin de session :

---

## Récapitulatif

- Questions posées : N
- Monté d'un niveau : _liste_
- Descendu d'un niveau : _liste_
- Inchangé : N
- À revoir bientôt : _les fiches passées en `neuf` ou `fragile`_
- Fiches corrigées : _liste, ou « aucune »_

---

## Contraintes

- **Une question à la fois.** Attends la réponse avant la suivante.
- **Jamais la réponse dans la question.**
- Ne modifie **jamais** le corps d'une fiche sans validation explicite.
- Ne touche jamais aux notes préexistantes autrement qu'en ajoutant leur ligne d'index — et ne modifie de toute façon jamais leur contenu.
- Dans les tableaux de l'index, les liens sont **sans alias** : `[[cible]]`, jamais `[[cible|libellé]]`, car le `|` casse la cellule. Quand tu réécris une ligne d'index, préserve le lien tel quel.
- Ne modifie que les colonnes `Revue` et `Maîtrise`. Les colonnes `Connaissance` et `Capturée` appartiennent à `/add-knowledge`.
- Les seules valeurs de maîtrise admises sont `neuf`, `fragile`, `acquis`.

## Règle finale

**Une question à la fois, et jamais la réponse dans la question.** Tu ne modifies que les colonnes `Revue` et `Maîtrise` de l'index. Tu ne corriges une fiche qu'avec validation explicite. Les liens dans les tableaux sont **sans alias**.
````

- [ ] **Step 3: Vérifier les invariants du fichier produit**

Run :

```bash
head -3 skills/check-knowledge/SKILL.md
grep -c 'name: check-knowledge' skills/check-knowledge/SKILL.md
grep -c 'Second cerveau 2' skills/check-knowledge/SKILL.md
grep -c '10 questions' skills/check-knowledge/SKILL.md
grep -c '30 jours' skills/check-knowledge/SKILL.md
grep -c 'sans alias' skills/check-knowledge/SKILL.md
grep -n 'Règle finale' skills/check-knowledge/SKILL.md
```

Expected : première ligne `---`, deuxième `name: check-knowledge` ; chacun des cinq `grep -c` renvoie au moins `1` ; `Règle finale` apparaît une fois, en clôture.

- [ ] **Step 4: Vérifier la cohérence du contrat entre les deux skills**

Les deux fichiers décrivent le même format. Une divergence ici est le bug le plus coûteux du plan : elle ne se verra qu'à l'usage, plusieurs fiches plus tard.

Run :

```bash
grep -o 'neuf\|fragile\|acquis' skills/add-knowledge/SKILL.md | sort -u
grep -o 'neuf\|fragile\|acquis' skills/check-knowledge/SKILL.md | sort -u
grep -o 'Connaissance | Capturée | Revue | Maîtrise' skills/*/SKILL.md
grep -o '_INDEX.md' skills/*/SKILL.md | sort -u
```

Expected : les deux premières commandes renvoient exactement `acquis`, `fragile`, `neuf` — trois valeurs, pas une quatrième. La troisième renvoie l'en-tête de tableau **identique** depuis les deux fichiers. La quatrième confirme que les deux skills nomment l'index de la même façon.

- [ ] **Step 5: Commit**

```bash
git add skills/check-knowledge/SKILL.md
git commit -m "feat: skill check-knowledge — interrogation sur les connaissances capturées"
```

---

### Task 3: Installation et fumigation

**Files:**
- Modify: aucun. Cette tâche installe et éprouve ce que les tâches 1 et 2 ont produit.

**Interfaces:**
- Consumes: `skills/add-knowledge/SKILL.md` et `skills/check-knowledge/SKILL.md`.
- Produces: rien de versionné. Des symlinks dans `~/.agents/skills/`, `~/.claude/skills/`, `~/.copilot/skills/`, et la confirmation que les deux skills fonctionnent réellement.

- [ ] **Step 1: Installer les symlinks**

```bash
./install.sh --global --no-plugins
```

`--no-plugins` est important : sans lui, `--global` réinstalle aussi toute la liste de plugins tiers, ce qui est long et sans rapport avec cette tâche.

- [ ] **Step 2: Vérifier les symlinks des deux nouveaux skills**

Run :

```bash
ls -l ~/.agents/skills/add-knowledge ~/.agents/skills/check-knowledge
ls -l ~/.claude/skills/add-knowledge ~/.claude/skills/check-knowledge
```

Expected : dans `~/.agents/skills/`, deux symlinks pointant en absolu vers `<repo>/skills/<nom>`. Dans `~/.claude/skills/`, deux symlinks pointant en relatif vers `../../.agents/skills/<nom>` — c'est la convention du dépôt, ne la remplace pas par de l'absolu.

- [ ] **Step 3: Fumigation de `/add-knowledge` — première capture**

Dans une **nouvelle session** Claude Code (les skills sont chargés au démarrage), invoquer `/add-knowledge` sur l'incident d'origine : un serveur PHP du projet `email-api-check` tenait encore le port 8791.

Vérifier, dans l'ordre :

1. le skill pose **une seule** question de reformulation ;
2. il présente la fiche complète et **attend** avant d'écrire ;
3. après validation, `Développement/Réseau.md` existe, avec son frontmatter (`Titre`, `Tags`, `Créée le`) et une section `## Libérer un port TCP occupé` conforme au gabarit — `**À retenir**` en tête, bloc `**Révision**` en fin ;
4. `_INDEX.md` existe et contient une ligne pour cette fiche, maîtrise `neuf`, colonne `Revue` à `—`.

Contrôle :

```bash
C="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances"
cat "$C/Développement/Réseau.md"
cat "$C/_INDEX.md"
```

- [ ] **Step 4: Fumigation de `/add-knowledge` — détection de doublon**

Invoquer `/add-knowledge` une seconde fois sur un sujet proche (par exemple : identifier le processus qui occupe un port).

Expected : le skill **propose d'enrichir** la fiche existante et nomme laquelle, au lieu de créer une seconde section. S'il crée un doublon, c'est l'étape 2 de la méthode qui n'est pas suivie — renforcer cette instruction dans `skills/add-knowledge/SKILL.md`.

- [ ] **Step 5: Fumigation de `/check-knowledge`**

Invoquer `/check-knowledge` dans une nouvelle session.

Vérifier :

1. la question porte sur la fiche `neuf` ;
2. elle est posée **sans afficher la fiche** et sans contenir la réponse ;
3. le skill attend la réponse avant d'enchaîner ;
4. après la réponse, `_INDEX.md` a été mis à jour : colonne `Revue` à la date du jour, `Maîtrise` cohérente avec la réponse donnée.

Contrôle :

```bash
C="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances"
cat "$C/_INDEX.md"
```

- [ ] **Step 6: Vérifier le rendu dans Obsidian**

Ouvrir `Connaissances/_INDEX.md` dans Obsidian.

Expected : les tableaux s'affichent en tableaux (aucune cellule cassée par un `|`), et les liens résolvent — un clic sur `[[Développement/Réseau#Libérer un port TCP occupé]]` ouvre le fichier **à la bonne section**.

C'est la vérification qui justifie la règle « liens sans alias » : si une cellule est cassée, un lien aliasé s'est glissé dans un tableau.

- [ ] **Step 7: Consigner le résultat**

Aucun commit si tout passe : cette tâche ne produit pas de fichier versionné.

Si la fumigation a révélé un écart entre le comportement observé et la spec, corriger le `SKILL.md` concerné, puis committer :

```bash
git add skills/
git commit -m "fix: ajustement des skills après fumigation"
```

Ne pas commiter le contenu du vault : il vit hors du dépôt.

---

## Notes pour l'exécutant

- **Il n'y a rien à exécuter dans ce livrable.** Un `SKILL.md` est un prompt. Sa « correction » ne se prouve pas par un test unitaire mais par la Task 3, en session réelle. Ne fabrique pas de harnais de test pour compenser : le dépôt n'en a pas, et la spec n'en demande pas.
- **Le style prescriptif est une exigence, pas une préférence.** Les skills de ce dépôt énoncent un rôle, des contraintes dures, une méthode numérotée, un format de sortie obligatoire, et réaffirment la limite non évidente en « Règle finale ». Voir `skills/obsidian-para-sorter/SKILL.md` comme référence.
- **Français partout.** Y compris dans les messages de commit, conformément à l'historique du dépôt.
- **Ne modifie pas `install.sh`.** Sa boucle sur `skills/*/` ramasse déjà les nouveaux dossiers.
