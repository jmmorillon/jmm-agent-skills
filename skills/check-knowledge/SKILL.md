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
- un **thème** (« interroge-moi sur le réseau ») → restreins la sélection à ce fichier thématique. Si le thème nommé est un **dossier racine** (« interroge-moi sur le développement »), restreins-la à tous les fichiers thématiques qu'il contient. Si le nom est ambigu, demande lequel des deux ;
- un **nombre** (« 3 questions ») → respecte-le ;
- **arrêter en cours de route** → le récapitulatif porte alors sur les questions déjà posées.

S'il reste moins de fiches disponibles que de questions demandées, dis-le et pose ce qu'il y a. Ne repose pas deux fois la même fiche dans une session.

## Méthode

1. **Lis `_INDEX.md`** et sélectionne les fiches à demander, dans cet ordre de priorité :
   1. maîtrise `neuf` (jamais révisée, ou remise à zéro après une réponse fausse) — et parmi elles, d'abord celles dont le `À retenir` est marqué `_(rédigé par l'agent)_` : ce sont celles que l'utilisateur n'a pas formulées, donc pas digérées. Ce marqueur n'est pas dans l'index : pour le voir, ouvre les fiches `neuf` — elles seules, pas tout le vault, et **au plus les 15 premières listées dans l'index**. Au-delà, sélectionne sans le marqueur ;
   2. maîtrise `fragile` ;
   3. maîtrise `acquis` dont la colonne `Revue` date de **plus de 30 jours**.

   Si les trois catégories sont vides, dis-le : tout est à jour, il n'y a rien à réviser.

2. **Lis la fiche** correspondante dans son fichier thématique, pour toi seul.

   Si la ligne vient du tableau **« Notes autonomes »**, il ne s'agit pas d'une fiche : lis la note préexistante en entier. Elle n'a ni gabarit, ni `À retenir`, ni bloc `Révision`.

3. **Pose la question sans afficher la fiche.** Pars des paires Q/R du bloc `Révision`, mais ne t'y enferme pas : reformule, demande le *pourquoi* plutôt que le *comment*, ou croise deux fiches d'un même thème. Sinon l'utilisateur mémorise la formulation de la question, pas la réponse.

   Pour une **note autonome**, il n'y a pas de Q/R préparées : formule toi-même la question à partir de ce que tu viens de lire, sur ce que la note a de central. Une seule, comme pour une fiche.

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

7. **Boucle de retour.** Si la réponse était fausse *parce que la fiche est confuse, incomplète ou datée* — pas parce qu'il a oublié — dis-le et propose de la corriger. **Attends sa validation avant d'écrire quoi que ce soit dans la fiche.** C'est ce qui empêche le vault de fossiliser une mauvaise explication. La correction respecte le gabarit de fiche ci-dessous.

   **Une note autonome n'est jamais corrigée**, même avec validation : signale la faiblesse à l'utilisateur et n'y touche pas. La reformater est le travail d'un autre skill.

8. **Enchaîne** la question suivante.

## Gabarit de fiche

Tu ne rédiges pas de fiche, mais l'étape 7 t'autorise à en corriger une. Le format ci-dessous est celui de `/add-knowledge`, reproduit à l'identique : une correction s'y conforme.

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
- Une fiche = une section `##`. **Son titre est unique dans le fichier** : c'est l'ancre de lien. Si le titre existe déjà, c'est un doublon : n'ouvre pas une seconde section, complète la section existante par le parcours d'enrichissement.
- `**À retenir**` est en tête et **obligatoire**.
- `Symptôme`, `Diagnostic`, `Cause`, `Action`, `Vérification`, `Détail`, `Piège` sont **facultatifs**. Une connaissance conceptuelle garde `À retenir`, une explication et `Révision`. **N'écris jamais un champ vide.** La liste n'est pas fermée : si aucun de ces sept noms ne convient à la connaissance, tu peux en nommer un autre — un ou deux mots, en gras, suivis d'un tiret cadratin, comme les autres. N'en invente un que par nécessité, pas par confort : plus le vocabulaire s'élargit, moins les fiches se ressemblent.
- `Révision` : 1 à 3 paires, format `- Q — …` puis `  R — …`.
- La ligne finale en italique rappelle la date et le contexte d'origine. Le frontmatter `Créée le` et cette date sont au format `AAAA-MM-JJ`, obtenu avec `date +%F`.
- Si l'utilisateur n'a pas répondu à la question de reformulation, a refusé d'y répondre, ou a répondu par autre chose qu'une reformulation, écris `**À retenir** — _(rédigé par l'agent)_ …`.

## Gabarit d'index

C'est le fichier que tu lis pour choisir, et le seul que tu écris de ta propre initiative. La **seule autre** écriture autorisée est la correction d'une fiche, à l'étape 7, après validation explicite. Une note préexistante n'est jamais écrite, même validée.

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
- **10 questions** par défaut par session, sauf nombre précisé par l'utilisateur.
- Une fiche `acquis` n'est réinterrogée qu'après **plus de 30 jours** sans révision.
- Ne modifie **jamais** le corps d'une fiche sans validation explicite.
- Ne touche jamais au contenu d'une note préexistante, même avec validation. Un **fichier thématique** est un fichier vers lequel pointe le lien du **titre** d'une section `##` de `_INDEX.md` (ces titres ont la forme `## Thème / [[Chemin/Fichier]]`). Le titre de la section « Notes autonomes » ne contient aucun lien : les fichiers listés dans son tableau restent des notes préexistantes. **Tout autre `.md` du vault est une note préexistante, en lecture seule** — y compris les `.md` posés à la racine de `Connaissances/` (`Caméra LAPI.md`) ou directement dans un dossier de thème (`Prise de notes/Writing by Bob Doto.md`). Dans le doute, demande.
- Les dates sont au format `AAAA-MM-JJ`, valeur absente `—`. **Obtiens la date du jour avec `date +%F` — ne la recopie pas du gabarit et ne l'écris pas de mémoire.**
- Dans les tableaux de l'index, les liens sont **sans alias** : `[[cible]]`, jamais `[[cible|libellé]]`, car le `|` casse la cellule. Quand tu réécris une ligne d'index, préserve le lien tel quel.
- Ne modifie que les colonnes `Revue` et `Maîtrise`. Les colonnes `Connaissance` et `Capturée` appartiennent à `/add-knowledge`.
- Les seules valeurs de maîtrise admises sont `neuf`, `fragile`, `acquis`.

## Règle finale

**Une question à la fois, et jamais la réponse dans la question.** 10 questions par défaut, et plus de 30 jours avant de réinterroger une fiche `acquis`. Tu n'ouvres au plus que **les 15 premières fiches `neuf`** listées dans l'index. Tu ne modifies que les colonnes `Revue` et `Maîtrise` de l'index. Tu ne corriges une fiche qu'avec validation explicite, et tu ne corriges **jamais** une note préexistante. Les dates viennent de `date +%F`, jamais du gabarit. Les liens dans les tableaux sont **sans alias**.
