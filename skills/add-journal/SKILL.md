---
name: add-journal
description: À utiliser pour consigner le suivi d'un projet dans sa fiche projet du vault Obsidian « Second Cerveau 2 », sous forme d'entrées de journal datées, concises et liées aux autres fiches, dans la section `## Track Log` — en créant la fiche si elle n'existe pas encore (dans `Projets/` pour un projet en cours, dans un sous-dossier de `Domaines/` pour un projet plus ancien). Déclenche ce skill quand l'utilisateur tape « /add-journal », demande de « noter ça dans le journal / le track log du projet », « journaliser », « garder une trace de l'avancement », « faire le point sur le projet X dans Obsidian », ou « créer la fiche projet ». Propose-le aussi spontanément, en une phrase, à la fin d'un travail notable rattaché à un projet identifiable (déploiement, décision, blocage levé, livraison) — même si l'utilisateur ne parle pas de journal. Ne l'utilise pas pour capturer une connaissance technique réutilisable (c'est /add-knowledge) ni pour classer des notes (c'est /obsidian-para-sorter).
---

# Add Journal

Tu tiens le journal de bord des projets de l'utilisateur.

Une session de travail avance un projet, mais le *pourquoi* et le *où on en est* s'évaporent avec elle : trois semaines plus tard, personne ne sait plus ce qui a été fait, décidé ou laissé en suspens. Ton rôle est de consigner cet avancement dans la fiche projet, **en quelques puces qu'on relit en dix secondes**, reliées aux fiches du vault qui donnent le détail.

## Emplacement

Vault, fixe :

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2
```

Le chemin contient des espaces : cite-le systématiquement en shell. **S'il est absent, arrête-toi et dis-le.** Ne devine pas un autre vault.

Dans ce vault :

```
Projets/                          <- projets en cours
  Coolify.md                      <- fiche projet à la racine
  Planète Dauphins/
    Planète Dauphin.md            <- fiche projet dans un sous-dossier
Domaines/                         <- projets plus anciens, rangés par domaine
  Novazeo/Agence/Archives/Jama 97.md
  Outils/Modèles Obsidian/Modèle Projet.md   <- gabarit de fiche, LECTURE SEULE
Journal/                          <- comptes rendus de réunion : HORS PÉRIMÈTRE
```

Le dossier racine `Journal/` n'a rien à voir avec ce skill : ce sont des comptes rendus datés. Tu n'y écris pas. Tu peux en revanche lier une réunion depuis une entrée.

## Ce que tu as le droit d'écrire

- **La section `## Track Log` de la fiche projet**, et rien d'autre dans une fiche existante. `Contexte`, `Tâches`, `Décisions (ADR)`, `Roadmap` appartiennent à l'utilisateur : tu ne les modifies pas, même si une entrée rend une tâche caduque. Signale-le plutôt dans ta proposition (« la tâche X semble faite — à cocher ? »).
- **Une fiche projet neuve**, créée à partir du Modèle Projet, quand aucune fiche n'existe.

Les entrées déjà présentes dans un Track Log ne sont **jamais réécrites ni reformatées**, même si leur format diffère du tien (`### 04/09/2026`, puces `- **02/09/2026** —`, blocs `■ Mars 2026`…). Ce sont les archives de l'utilisateur ; tu ajoutes, tu n'harmonises pas.

## Quand te déclencher

1. **Invocation explicite** — `/add-journal`, « note ça dans le journal du projet », « mets à jour le track log ».
2. **Proposition spontanée** — à la fin d'un travail notable rattaché à un projet identifiable (une mise en production, une décision tranchée, un blocage levé ou découvert, une livraison), propose en une phrase : « Je consigne ça dans le Track Log de *Projet* ? ». Si la réponse est non, n'insiste pas.

Si la conversation touche plusieurs projets, traite **un projet à la fois** : une fiche, une proposition, une validation.

## Méthode

1. **Identifie le projet.** Déduis-le de la demande et de la conversation. S'il est ambigu, demande — une question courte.

2. **Cherche la fiche** dans `Projets/` et `Domaines/`, sous-dossiers compris : par nom de fichier et par titre `# …`, sans tenir compte de la casse ni des accents, en tolérant les variantes proches (`Planète Dauphins` / `Planète Dauphin`).
   - Un seul candidat évident → c'est la fiche.
   - Plusieurs candidats → liste-les et demande.
   - Aucun → passe par la création (étape 3).

   Une fiche projet se reconnaît à son frontmatter (`statut`, `domaine`, `créé`) et/ou à ses sections du Modèle Projet. Une note d'intervention (`Interventions/AAAAMMJJ - …`) ou un compte rendu n'est pas une fiche projet : ne journalise pas dedans, sauf demande explicite.

3. **Si la fiche n'existe pas**, prépare sa création :
   - **Projet en cours** → `Projets/<Nom du projet>.md`.
   - **Projet plus ancien** → un sous-dossier existant de `Domaines/`. Liste les sous-dossiers (`find` sur 2-3 niveaux) et propose le plus pertinent ; n'invente pas de nouveau sous-dossier sans accord explicite.
   - Si tu ne sais pas s'il est en cours ou ancien, demande.
   - **Lis `Domaines/Outils/Modèles Obsidian/Modèle Projet.md` au moment de créer** — ne reconstruis pas le gabarit de mémoire, il peut avoir évolué. Remplace `{{title}}` par le nom du projet, `{{date}}` par la date du jour (`date +%F`), choisis `statut` (`actif` pour un projet en cours ; pour un projet ancien, reprends ce que dit l'utilisateur, sinon propose une valeur dans le bloc de proposition — c'est la validation qui tranche, inutile de poser une question à part) et `domaine` au format du vault (`"#pro"`, `"#perso"`, `"#assoc"`). Laisse les autres sections vides, sauf `Contexte` si l'utilisateur t'a donné de quoi l'amorcer en une ou deux phrases.
   - Nomme le fichier comme le vault : accents et espaces conservés, pas de kebab-case.

4. **Lis la fiche** (si elle existe) : son Track Log pour savoir où insérer et éviter de répéter une entrée déjà écrite, et le reste pour le contexte — mais sans y écrire.

5. **Rédige l'entrée** au gabarit ci-dessous.
   - **N'invente rien.** Ne consigne que ce qui a réellement eu lieu dans la conversation ou ce que l'utilisateur t'a dit. Une action envisagée mais non faite s'écrit comme telle (« Reste : … », « À faire : … »).
   - **Sois concis.** 1 à 6 puces, une ligne chacune autant que possible. Ce qui compte : ce qui a été fait, décidé, bloqué, et la suite. Pas de récit, pas de dump de commandes — si une commande ou une méthode mérite d'être retenue, propose `/add-knowledge` et lie la fiche de connaissance plutôt que de la recopier.
   - **Lie** les notes du vault qui éclairent l'entrée (serveur, intervention, réunion, fiche de connaissance, autre projet). **Vérifie que chaque cible existe** avant d'écrire le lien (`find` par nom de fichier) ; un lien vers une note inexistante crée une page fantôme. Lien par nom de fichier sans extension, `[[Nom]]` ; si ce nom existe à plusieurs endroits du vault, utilise le chemin (`[[Domaines/…/Nom]]`). Un lien vers une section : `[[Nom#Titre de section]]`.
   - **Date** : celle du jour par `date +%F`, ou celle que désigne l'utilisateur (« hier », « vendredi dernier ») calculée à partir de `date +%F` — jamais de mémoire.

6. **Présente la proposition** (bloc de sortie ci-dessous) et attends : valider, corriger, annuler.

7. **Écris**, uniquement si validé, avec l'outil d'édition (pas de réécriture complète du fichier) :
   - Section `## Track Log` présente → insère l'entrée **juste sous le titre de section**, au-dessus des entrées existantes : la plus récente en haut.
   - Un titre `### AAAA-MM-JJ` de la même date existe déjà **en tête** du Track Log → ajoute tes puces à la fin de ses puces au lieu de créer un second titre.
   - Section absente → ajoute-la en fin de fiche, précédée de `---` comme les autres sections du Modèle Projet.
   - Fiche neuve → crée le fichier complet (gabarit + entrée dans son Track Log).

8. **Confirme en une ligne.**

## Gabarit d'entrée

```markdown
## Track Log

### 2026-09-14
- POC Coolify installé sur [[AG09]] — Docker et reverse proxy isolés du parc ISPConfig
- Compte restreint de Mathieu : déploiement d'un site statique OK, aucun accès serveur
- Décision : self-hosted plutôt que Cloud (cf. ADR-1)
- Reste : tester le rollback d'un déploiement raté

### 2026-08-31
- Défrichage du README : pilotage SSH, configuration réversible sur le serveur
- Bloquant : modèle de permissions non documenté
```

Règles de format :

- Un titre `### AAAA-MM-JJ` par jour, **date seule** dans le titre, format ISO `AAAA-MM-JJ`.
- Sous le titre, des puces `- `. Pas de sous-titres, pas de paragraphes. Une sous-puce (tabulation) est admise pour un détail qui dépend de la puce parente — pas plus d'un niveau.
- Préfixes facultatifs, à n'utiliser que quand ils éclairent : `Décision :`, `Bloquant :`, `Reste :`. N'en invente pas d'autres par confort.
- Une valeur précise (version, URL, montant, nom de serveur) vaut mieux qu'un adjectif. Un bloc de code n'a pas sa place dans une entrée.
- Plus récente en haut. Une ligne vide entre deux titres de jour. Pas de `---` après la dernière entrée : ce séparateur précède les sections `##`, il ne les clôt pas.
- Un fait absent de la demande mais tiré du vault (nom de domaine, référence d'une tâche) est admis s'il précise l'entrée ; une interprétation (retard calculé, jugement) ne l'est pas.

## Contraintes

- **Un projet à la fois.** Une fiche, une proposition, une validation.
- **Aucune écriture sans validation explicite** — ni entrée, ni fiche neuve.
- Dans une fiche existante, tu n'écris que dans `## Track Log`. Tu ne réécris jamais une entrée existante.
- Tu ne modifies jamais le Modèle Projet ni aucune note hors de la fiche cible.
- Aucun lien vers une note dont tu n'as pas vérifié l'existence.
- Pas de nouveau sous-dossier dans `Domaines/` ou `Projets/` sans accord explicite.
- Si le vault est absent ou inaccessible, arrête-toi et dis-le.

## Sortie obligatoire

Réponds en français. Avant d'écrire, présente exactement ce bloc :

---

**Projet** : _nom du projet_
**Fiche** : `Projets/Coolify.md` _(existante / **nouvelle**)_
**Nouveau sous-dossier** : `Domaines/…/` — **ton accord explicite est requis** _(cette ligne uniquement s'il faut en créer un)_
**Insertion** : en tête du Track Log / sous le titre du jour existant / section Track Log créée en fin de fiche / fiche neuve

```markdown
_l'entrée complète, au gabarit — ou la fiche complète si elle est neuve_
```

_Liens vérifiés_ : `[[AG09]]` → `Domaines/Novazeo/Infrastructure/Serveurs/AG09.md` _(une ligne par lien)_
_À signaler_ : _(une ligne, uniquement si utile — tâche qui semble faite, connaissance à capturer avec /add-knowledge)_

→ **Valider, corriger ou annuler ?**

---

Après écriture, une seule ligne :

`✓ Track Log de « Coolify » → Projets/Coolify.md — entrée du 2026-09-14 (4 puces)`

Fiche neuve :

`✓ Fiche « Coolify » créée → Projets/Coolify.md — entrée du 2026-09-14 (4 puces)`

## Règle finale

**Un projet à la fois. Rien n'est écrit sans validation explicite.** Dans une fiche existante, tu n'écris que dans `## Track Log`, en tête, sans jamais toucher aux entrées existantes. Entrées concises : **1 à 6 puces** sous un titre `### AAAA-MM-JJ`, date issue de `date +%F`. Chaque `[[lien]]` pointe vers une note dont tu as vérifié l'existence. Pour une fiche neuve, tu lis le Modèle Projet dans le vault et tu fais valider l'emplacement : `Projets/` pour un projet en cours, un sous-dossier existant de `Domaines/` pour un projet ancien.
