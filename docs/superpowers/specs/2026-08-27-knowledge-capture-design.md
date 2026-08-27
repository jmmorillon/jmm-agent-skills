# Capture et révision de connaissances — `/add-knowledge` et `/check-knowledge`

_Design validé le 2026-08-27._

## Problème

Une connaissance acquise en résolvant un problème avec un agent disparaît avec la
session. L'exemple déclencheur : un port TCP resté occupé par un serveur PHP
oublié. Le problème est résolu, mais rien n'est retenu — ni la commande
(`lsof -i :PORT`), ni le modèle mental (« un port est tenu par un processus, pas
par un projet »). Le même incident se reproduira, et l'agent le résoudra à
nouveau à la place de l'utilisateur.

L'objectif n'est donc pas d'archiver des solutions, mais de **transformer une
résolution en apprentissage**, puis de vérifier que l'apprentissage a tenu.

## Objectifs

1. Capturer une connaissance au moment où elle est fraîche, dans le vault
   Obsidian de l'utilisateur, sous une forme relisible et interrogeable.
2. Faire formuler la connaissance par l'utilisateur — pas seulement par l'agent.
3. Permettre, plus tard, une interrogation ciblée sur ce qui n'est pas acquis.

## Non-objectifs

- Pas de hook Claude Code ni de capture automatique sans intervention.
- Pas d'algorithme de répétition espacée à intervalles calculés (SM-2 ou
  similaire). Trois niveaux de maîtrise et une date suffisent.
- Pas de reprise ou de réécriture des notes déjà présentes dans le vault.
- Pas d'interface, pas de plugin Obsidian, pas de base de données. Du Markdown.

## Emplacement et périmètre d'écriture

Vault cible (chemin écrit en dur dans les deux skills) :

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Second cerveau 2/Second Cerveau 2/Connaissances
```

Si ce dossier est absent, le skill s'arrête et le signale. Il ne crée jamais
d'arborescence ailleurs.

Arborescence :

```
Connaissances/
  _INDEX.md                    <- sommaire + état de révision
  Développement/
    Réseau.md                  <- fichier thématique incrémental
    Shell.md
    GIT/                       <- notes existantes, en lecture seule
    Skills IA/                 <- notes existantes, en lecture seule
  IA/
  Prise de notes/
```

**Périmètre d'écriture strict.** Les skills n'écrivent que dans `_INDEX.md` et
dans les fichiers thématiques qu'ils ont eux-mêmes créés. Les notes autonomes
préexistantes sont référençables depuis l'index, jamais modifiées.

**Conventions du vault** à respecter : accents et espaces dans les noms de
dossiers, tags hiérarchiques (`Dev/Réseau`), frontmatter avec `Titre`, `Tags`,
`Créée le`.

## Format d'une fiche

Une fiche = une section `##` dans un fichier thématique. Le titre de section est
unique dans le fichier : il sert d'ancre de lien, aucun identifiant artificiel
n'est nécessaire.

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

- **`À retenir` est en tête** et obligatoire. C'est la formulation de
  l'utilisateur, corrigée si nécessaire, et c'est ce qu'il doit voir en premier
  en relisant.
- `Symptôme` / `Diagnostic` / `Action` / `Vérification` / `Piège` sont
  **facultatifs**. Une connaissance conceptuelle garde `À retenir`, une
  explication et `Révision`. Aucun champ vide n'est écrit.
- `Révision` contient 1 à 3 paires Q/R, rédigées à la capture. Elles sont un
  point de départ pour `/check-knowledge`, pas une limite.
- La ligne de contexte finale rappelle d'où vient la fiche.
- Si l'utilisateur n'a pas formulé le `À retenir` lui-même, la fiche le signale
  (`**À retenir** — _(rédigé par l'agent)_ …`).

## Format de l'index

`Connaissances/_INDEX.md` :

```markdown
# Index des connaissances

_Maintenu par /add-knowledge et /check-knowledge. Une ligne = une fiche._

## Développement / [[Développement/Réseau]]

| Connaissance | Capturée | Revue | Maîtrise |
| --- | --- | --- | --- |
| [[Développement/Réseau#Libérer un port TCP occupé]] | 2026-08-27 | — | neuf |
| [[Développement/Réseau#Trouver son IP locale]] | 2026-08-12 | 2026-08-25 | acquis |

## Notes autonomes (hors système, en lecture seule)

| Note | Revue | Maîtrise |
| --- | --- | --- |
| [[Développement/GIT/Utilisation de Git Worktree avec des Agents IA Multiples]] | — | neuf |
```

Règles :

- **Liens sans alias dans les tableaux.** Un `[[cible|libellé]]` casse la
  cellule : le `|` est lu comme séparateur de colonne. Cette règle est inscrite
  explicitement dans les deux skills.
- Trois niveaux de maîtrise : `neuf` (jamais révisé), `fragile` (révisé, réponse
  incomplète ou fausse), `acquis` (répondu juste).
- Dates au format `AAAA-MM-JJ`, `—` quand la valeur est absente.
- Une section `##` par fichier thématique, dans l'ordre alphabétique.
- Le second tableau permet d'interroger l'utilisateur sur ses notes
  préexistantes sans que `/add-knowledge` ait à les toucher.

**Séparation des écrivains** : `/add-knowledge` crée les lignes ; les colonnes
`Revue` et `Maîtrise` appartiennent à `/check-knowledge`.

## `/add-knowledge`

### Déclenchement

Trois portes d'entrée, encodées dans la `description` du frontmatter :

1. **Invocation explicite** — l'utilisateur tape `/add-knowledge` juste après
   avoir compris quelque chose.
2. **Proposition spontanée** — l'agent propose la capture quand un problème non
   trivial vient d'être résolu, qu'une question du type « comment on fait ça ? »
   a trouvé sa réponse, ou qu'une erreur déjà commise se répète. Même mécanique
   que `project-docs-sync` après une tâche d'ampleur.
3. **Bilan de fin de session** — quand l'utilisateur clôt une session, l'agent
   propose les connaissances candidates repérées en chemin.

### Parcours

1. **Isoler la connaissance** dans ce qui vient de se passer. Une seule à la
   fois. En mode bilan : 5 candidats maximum, traités un par un.
2. **Lire `_INDEX.md`** avant toute chose — thèmes existants et détection de
   doublon. Si une fiche proche existe, proposer de **l'enrichir** plutôt que
   d'en créer une seconde.
3. **Poser la question de reformulation**, une seule : « En une ou deux phrases,
   avec tes mots : qu'est-ce qu'il faut retenir de ça ? »
4. **Rédiger la fiche** : le `À retenir` de l'utilisateur en tête (corrigé si
   nécessaire, avec la correction signalée explicitement), le corps technique
   rédigé par l'agent, les Q/R de révision.
5. **Présenter la fiche entière** et attendre : valider / corriger / annuler.
6. **Écrire** : section ajoutée à la fin du fichier thématique (pas de
   réordonnancement — l'index est la vue navigable), puis ligne d'index en
   `neuf`.
7. **Confirmer en une ligne** : fiche, fichier, thème.

### Choix du thème

Réutiliser un fichier thématique existant dès qu'il convient. N'en créer un
nouveau que si aucun ne correspond clairement et que le sujet justifie un
regroupement. Créer un nouveau dossier de thème racine demande l'accord de
l'utilisateur.

### Garde-fous

- **Reformulation passée** : la fiche est écrite quand même, le `À retenir` est
  marqué comme rédigé par l'agent, et ces fiches sont prioritaires en révision.
- **Rien d'inventé** : seul ce qui a réellement eu lieu dans la conversation est
  documenté. Une commande non exécutée est signalée comme non vérifiée, ou
  l'agent demande.
- Aucune écriture sans validation explicite.

## `/check-knowledge`

### Parcours

Par défaut 5 questions, une à la fois. L'utilisateur peut préciser un thème
(« interroge-moi sur le réseau ») ou un nombre.

1. **Lire `_INDEX.md`** et sélectionner : d'abord les `neuf`, puis les
   `fragile`, puis les `acquis` non revus depuis plus de 30 jours.
2. **Poser la question sans afficher la fiche.** Partir des Q/R écrites, mais
   s'autoriser à les reformuler, à demander le *pourquoi* plutôt que le
   *comment*, ou à croiser deux fiches d'un même thème — sinon l'utilisateur
   mémorise la formulation de la question, pas la réponse.
3. **Attendre la réponse**, puis comparer à la fiche : ce qui est juste, ce qui
   manque, ce qui est faux. Factuel, sans commentaire sur la personne.
4. **Mettre à jour l'index** : réponse juste et complète → `acquis` ;
   approximative ou partielle → `fragile` ; fausse → `neuf`. Plus la date du
   jour. Une fiche `acquis` répondue faussement redescend donc à `neuf`.
5. **Boucle de retour** : si la réponse était fausse *parce que la fiche est
   confuse, incomplète ou datée*, le dire et proposer de la corriger, avec
   validation. C'est ce qui empêche le vault de fossiliser une mauvaise
   explication.
6. **Récapitulatif de fin** : ce qui a monté, ce qui a baissé, ce qu'il faudrait
   revoir bientôt.

### Garde-fous

- Une question à la fois, attendre la réponse avant la suivante.
- Ne jamais donner la réponse dans l'énoncé de la question.
- Ne pas modifier le corps d'une fiche sans validation explicite.

## Règles finales (réaffirmées en fin de chaque skill)

Selon la convention du dépôt, les limites non évidentes sont répétées en clôture
de skill :

- une connaissance / une question à la fois, jamais de batch ;
- aucune écriture dans le vault sans validation explicite ;
- ne jamais modifier les notes autonomes existantes ;
- liens sans alias dans les tableaux de l'index.

## Livrables

- `skills/add-knowledge/SKILL.md`
- `skills/check-knowledge/SKILL.md`

**Aucune modification d'`install.sh`** : la boucle `for src in "$SKILLS_SRC"/*/`
(`install.sh:220`) ramasse automatiquement tout nouveau dossier de skill.

## Vérification

Il n'y a ni test ni build dans ce dépôt. La vérification est manuelle :

1. Lancer `/add-knowledge` sur l'incident du port 8791 et confirmer que la fiche
   produite correspond au gabarit de la section « Format d'une fiche », que le
   fichier thématique est créé au bon endroit et que la ligne d'index apparaît
   en `neuf`.
2. Lancer `/add-knowledge` une seconde fois sur un sujet proche et confirmer que
   l'enrichissement est proposé au lieu d'un doublon.
3. Lancer `/check-knowledge` et confirmer que la question porte sur la fiche
   `neuf`, qu'elle est posée sans afficher la fiche, et que l'index est mis à
   jour après la réponse.
4. Ouvrir `_INDEX.md` dans Obsidian et confirmer que les tableaux s'affichent
   correctement et que les liens résolvent vers les bonnes ancres.
