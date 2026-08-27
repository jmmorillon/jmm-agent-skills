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
  Caméra LAPI.md               <- note préexistante à la racine, LECTURE SEULE
  Développement/
    Réseau.md                  <- fichier thématique incrémental
    GIT/                       <- notes préexistantes, LECTURE SEULE
  IA/
  Prise de notes/
    Writing by Bob Doto.md     <- note préexistante, LECTURE SEULE
```

**Tu n'écris que dans `_INDEX.md` et dans les fichiers thématiques.** Un **fichier thématique** est un fichier dont le nom est le titre d'une section `##` de `_INDEX.md`, ou que tu crées toi-même. **Tout autre `.md` du vault est une note préexistante, en lecture seule** — y compris les `.md` posés à la racine de `Connaissances/` (`Caméra LAPI.md`) ou directement dans un dossier de thème (`Prise de notes/Writing by Bob Doto.md`). Dans le doute, demande.

Les notes préexistantes sont référençables depuis l'index, jamais modifiées. Les reformater est le travail d'un autre skill.

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

   Si l'utilisateur ne répond pas, décline, ou répond par autre chose qu'une reformulation, n'insiste pas et ne repose pas la question : rédige un `À retenir` de ta plume, marqué `_(rédigé par l'agent)_`, et signale-le dans la ligne de confirmation finale.

   **En enrichissement, ne pose pas cette question** : le `À retenir` de la fiche existante reste tel quel. Une fiche n'a qu'un seul `À retenir`.

4. **Rédige la fiche** au gabarit ci-dessous.

   **Nouvelle fiche** :
   - le `À retenir` reprend la formulation de l'utilisateur. Si elle contient une erreur, corrige-la **et signale la correction explicitement** sous la fiche, en une ligne — c'est là que l'apprentissage se joue ;
   - le corps technique (symptôme, diagnostic, commandes, vérification, piège) est de ta plume : c'est du factuel, autant qu'il soit exact ;
   - rédige 1 à 3 paires Q/R de révision.

   **En enrichissement**, tu ne rédiges que ce qui s'ajoute : le complément de corps technique, de ta plume, et les paires Q/R nouvelles. Le `À retenir` et la ligne de contexte d'origine restent tels quels — les limites d'écriture sont à l'étape 6.

5. **Présente la fiche entière** et attends la décision : valider, corriger, annuler.

6. **Écris**, uniquement si validé.

   **Nouvelle fiche** :
   - ajoute la section **à la fin** du fichier thématique. Ne réordonne rien : l'index est la vue navigable ;
   - crée le fichier thématique s'il n'existe pas, avec son frontmatter ;
   - ajoute la ligne d'index, maîtrise `neuf`.

   **En enrichissement** : complète la section existante (ajoute au corps technique, ajoute des paires Q/R sans dépasser 3 au total), sans réécrire le `À retenir` ni la ligne de contexte d'origine. **N'ajoute pas de ligne d'index** — elle existe déjà ; ne touche ni à `Capturée`, ni à `Revue`, ni à `Maîtrise`. Signale-le à l'utilisateur : la fiche a changé, sa maîtrise enregistrée ne reflète plus tout à fait son contenu.

7. **Confirme en une ligne** : titre de la fiche, fichier, thème.

## Choix du thème

Réutilise un fichier thématique existant dès qu'il convient. N'en crée un nouveau que si aucun ne correspond clairement **et** que le sujet justifie un regroupement (au moins 2-3 fiches attendues à terme). Sinon, place la fiche dans le fichier thématique existant le plus proche — un **fichier thématique** au sens ci-dessus, jamais une note préexistante.

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
- Une fiche = une section `##`. **Son titre est unique dans le fichier** : c'est l'ancre de lien. Si le titre existe déjà, c'est un doublon : n'ouvre pas une seconde section, complète la section existante par le parcours d'enrichissement.
- `**À retenir**` est en tête et **obligatoire**.
- `Symptôme`, `Diagnostic`, `Action`, `Vérification`, `Piège` sont **facultatifs**. Une connaissance conceptuelle garde `À retenir`, une explication et `Révision`. **N'écris jamais un champ vide.**
- `Révision` : 1 à 3 paires, format `- Q — …` puis `  R — …`.
- La ligne finale en italique rappelle la date et le contexte d'origine. Le frontmatter `Créée le` et cette date sont au format `AAAA-MM-JJ`, obtenu avec `date +%F`.
- Si l'utilisateur n'a pas répondu à la question de reformulation, a refusé d'y répondre, ou a répondu par autre chose qu'une reformulation, écris `**À retenir** — _(rédigé par l'agent)_ …`.

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
- Les dates sont au format `AAAA-MM-JJ`, valeur absente `—`. **Obtiens la date du jour avec `date +%F` — ne la recopie pas du gabarit et ne l'écris pas de mémoire.**
- Les colonnes `Revue` et `Maîtrise` appartiennent à `/check-knowledge`. Tu les initialises, tu ne les fais pas évoluer.
- Crée `_INDEX.md` avec son en-tête s'il n'existe pas.
- Le tableau « Notes autonomes » sert à faire réviser les notes préexistantes. Tu n'y ajoutes une ligne **qu'à la demande explicite de l'utilisateur**, jamais spontanément : aucune étape de la méthode n'y conduit. La ligne se crée avec `Revue` à `—` et maîtrise `neuf`, et n'entraîne **aucune écriture dans la note elle-même**.

## Contraintes

- **Une connaissance à la fois.** Pas de batch, même en mode bilan.
- **N'invente rien.** Ne documente que ce qui a réellement eu lieu dans la conversation. Une commande qui n'a pas été exécutée est signalée comme non vérifiée, ou tu demandes.
- **Aucune écriture sans validation explicite.**
- Ne modifie jamais une note préexistante.
- N'efface jamais une fiche. Enrichir ≠ remplacer.
- Si le vault est absent ou inaccessible, arrête-toi et dis-le.

## Sortie obligatoire

Réponds en français. Avant d'écrire une fiche, présente exactement ce bloc :

---

**Connaissance** : _titre de la fiche_
**Fichier** : `Développement/Réseau.md` _(existant / **nouveau**)_
**Nouveau dossier de thème racine** : `Nom du dossier/` — **ton accord explicite est requis** _(cette ligne uniquement s'il faut en créer un)_
**Action** : nouvelle fiche / enrichissement de « _titre existant_ »

```markdown
_la fiche complète, au gabarit_
```

_Correction apportée à ta formulation_ : _(une ligne, uniquement s'il y en a une)_

→ **Valider, corriger ou annuler ?**

---

Avant d'inscrire une note préexistante au tableau « Notes autonomes » — à la demande explicite de l'utilisateur uniquement — présente exactement ce bloc, plus court :

---

**Note préexistante** : `Développement/GIT/Utilisation de Git Worktree avec des Agents IA Multiples.md`
**Action** : inscription au tableau « Notes autonomes » de `_INDEX.md` — aucune écriture dans la note

`| [[Développement/GIT/Utilisation de Git Worktree avec des Agents IA Multiples]] | — | neuf |`

→ **Valider, corriger ou annuler ?**

---

Après écriture, une seule ligne de confirmation.

Nouvelle fiche :

`✓ « Libérer un port TCP occupé » → Développement/Réseau.md — index à jour (neuf)`

Enrichissement :

`✓ « Libérer un port TCP occupé » complétée → Développement/Réseau.md — aucune ligne d'index ajoutée, maîtrise inchangée (elle ne reflète plus tout à fait la fiche)`

## Règle finale

**Une connaissance à la fois. 10 candidats maximum en bilan de fin de session.** Tu poses **une seule** question de reformulation. Tu n'écris rien sans validation explicite. Tu n'écris que dans `_INDEX.md` et dans les fichiers thématiques : tu ne touches jamais aux notes préexistantes. En enrichissement, tu n'ajoutes **aucune** ligne d'index. Les dates viennent de `date +%F`, jamais du gabarit. Dans les tableaux de l'index, les liens sont **sans alias**.
