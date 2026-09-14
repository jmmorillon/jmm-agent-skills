---
name: writing-pr
description: À utiliser pour rédiger ou modifier le titre et le corps d'une Pull Request (GitHub `gh pr create` / `gh pr edit`, ou texte à coller dans GitLab, Bitbucket…), en français par défaut (ou dans la langue que l'utilisateur précise), concis, à base de puces, extraits de code et diagrammes Mermaid. Déclenche ce skill dès que l'utilisateur demande d'« ouvrir une PR », « créer la pull request », « écrire / rédiger / réécrire la description de la PR », « mettre à jour le titre de la PR », « préparer la MR », ou qu'une branche est prête à être poussée pour revue — même s'il ne parle que de « la description » ou du « message de squash ». Ne l'utilise pas pour un simple message de commit hors PR ni pour relire le code d'une PR (code review).
---

# Writing PR

Tu rédiges le titre et le corps d'une Pull Request. Le lecteur est un relecteur pressé qui doit comprendre **ce qui change, pourquoi, et où regarder** en moins d'une minute — puis, des mois plus tard, quelqu'un qui tombe sur le commit de squash via `git blame`. Écris pour ces deux personnes, pas pour raconter ta session de travail.

## Contraintes

- **Français par défaut.** Titre et corps en français, sauf si l'utilisateur demande une autre langue (« rédige la PR en anglais », « in English »). Dans ce cas, tout passe dans cette langue, y compris les titres de rubriques des gabarits ci-dessous, qu'il faut traduire. Seule une demande explicite change la langue : ni la langue du code, ni celle des commits, ni celle de la conversation ne comptent. Les identifiants (fonctions, fichiers, commandes, flags) restent tels quels, entre backticks.
- **Concis, pas de dissertation.** Des puces courtes plutôt que des paragraphes. Si une phrase n'aide pas le relecteur à décider ou à comprendre, supprime-la. Seule exception : les changements volumineux ou à risque (voir « Mode article »).
- **Ne mentionne pas l'exécution des tests.** Pas de « tests passés », « j'ai lancé la suite », ni de section « Plan de test » cochée. La CI le montre déjà ; le répéter ajoute du bruit et une affirmation invérifiable. Mentionner des tests *ajoutés ou modifiés* comme partie du changement reste légitime.
- **Seul le commit de squash final compte.** Décris l'état final du diff par rapport à la branche cible, pas le chemin pour y arriver : pas de « d'abord j'ai essayé X », « corrigé suite à la review », « fixup », ni de liste des commits intermédiaires. Une approche abandonnée ne mérite une ligne que si elle explique un choix que le relecteur remettrait sinon en question.
- **N'invente rien.** Pas de chiffres de benchmark, de captures ou de liens de ticket que tu n'as pas. Si une donnée manque, laisse un emplacement explicite (`<!-- capture avant à ajouter -->`) et signale-le.

## Méthode

### 1. Rassemble la matière

- **Branche cible** : celle de la PR existante (`gh pr view --json baseRefName,title,body`), sinon la branche par défaut (`gh repo view --json defaultBranchRef` ou `git symbolic-ref refs/remotes/origin/HEAD`).
- **Le diff final** : `git diff <cible>...HEAD --stat` puis le diff utile. C'est la source de vérité — le squash ne contiendra que ça.
- **Le pourquoi** : la conversation en cours, les messages de commit, le ticket lié s'il est cité. Le diff dit *quoi*, rarement *pourquoi*.
- **Modification d'une PR existante** : lis le titre et le corps actuels. Conserve ce qui est encore juste (liens de tickets, captures fournies par un humain, mentions `Closes #…`), réécris ce que le diff final a rendu faux ou superflu.
- **Conventions du dépôt** : un `.github/pull_request_template.md` s'impose (remplis ses rubriques dans la langue retenue, sans rubrique « tests exécutés » vide pour autant) ; le style des titres suit celui de `git log` (ex. `feat: …`, `fix(auth): …`).

### 2. Classe le changement

Choisis la forme selon la nature du diff — plusieurs peuvent se cumuler :

| Nature | Forme |
| --- | --- |
| Changement courant | Corps standard (ci-dessous) |
| Changement visuel (UI, rendu, style, sortie graphique) | Corps standard + tableau avant/après avec images |
| Changement de performance / benchmark | Corps standard + tableau avant/après chiffré |
| Volumineux ou à haut risque | Mode article |

Est « volumineux ou à haut risque » : migration de données ou de schéma, changement d'architecture ou d'API publique, sécurité/authentification, facturation, suppression de fonctionnalité, ou diff assez large pour qu'un relecteur ne puisse pas le tenir en tête. Dans le doute, demande-toi : « un relecteur qui n'a pas suivi le sujet peut-il valider ça avec trois puces ? » Si non, mode article.

### 3. Rédige le titre

C'est le titre du commit de squash : impératif ou nominal, ≤ 72 caractères, qui dit l'effet et pas la tâche (« Met en cache les avatars côté CDN » plutôt que « Travail sur les avatars »). Suis le préfixe de convention du dépôt s'il en a un.

### 4. Rédige le corps

**Corps standard :**

```markdown
<Une ou deux phrases : le problème et ce que la PR y apporte.>

## Changements

- <changement principal, formulé du point de vue de l'effet>
- <changement secondaire>
- <`fichier` ou `fonction` clé si ça guide la relecture>

## Points d'attention

- <ce qui mérite l'œil du relecteur : choix discutable, effet de bord, config à changer>
```

- Omets « Points d'attention » s'il n'y a rien à signaler — une rubrique vide est du bruit.
- **Extraits de code** quand ils disent plus vite qu'une phrase : nouvelle signature d'API, exemple d'appel, changement de config. Quelques lignes, pas le diff recopié (le relecteur l'a déjà).
- **Diagramme Mermaid** quand le changement touche un flux, une séquence, des états ou des dépendances entre composants. Un `flowchart` ou `sequenceDiagram` de 5 à 10 nœuds vaut mieux qu'une explication en prose. Ne mets pas de diagramme décoratif pour un changement localisé.

**Changement visuel — tableau avant/après :**

```markdown
| Avant | Après |
| --- | --- |
| <img src="URL_AVANT" width="400"> | <img src="URL_APRÈS" width="400"> |
```

Utilise les captures fournies par l'utilisateur ou déjà présentes dans la PR. Si tu n'en as pas, laisse les emplacements en commentaire et dis à l'utilisateur quelles vues capturer (une ligne par écran ou état modifié).

**Benchmark — tableau avant/après :**

La référence « avant » se mesure **sur la branche cible**, pas sur un ancien commit de la branche de travail : c'est ce contre quoi le squash sera fusionné. Mesure les deux dans les mêmes conditions (ex. un `git worktree` de la branche cible), ou reprends des mesures fournies par l'utilisateur en précisant leur provenance.

```markdown
| Mesure | `main` | Cette PR | Écart |
| --- | --- | --- | --- |
| p50 latence | 120 ms | 84 ms | −30 % |
| Mémoire max | 512 Mo | 498 Mo | −3 % |
```

Ajoute sous le tableau une ligne sur les conditions (machine, jeu de données, nombre d'itérations) — sans elle les chiffres ne sont pas interprétables.

**Mode article (volumineux ou à haut risque) :**

Écris comme un billet de blog technique : un relecteur doit pouvoir comprendre le raisonnement sans avoir suivi le sujet. Reste dense — « article » ne veut pas dire délayé.

```markdown
## Contexte
<Le problème, pourquoi maintenant, ce qui ne marche pas avec l'existant.>

## Approche
<La solution retenue, avec diagramme Mermaid de l'architecture ou du flux.>

## Alternatives écartées
- <option> — <pourquoi non>

## Risques et atténuation
- <risque> — <mitigation, flag, rollback>

## Déploiement
<Ordre des étapes, migration, feature flag, retour arrière.>
```

Les puces, extraits de code et diagrammes restent de mise à l'intérieur des sections.

### 5. Publie ou présente

- Si l'utilisateur a demandé de créer ou mettre à jour la PR : écris le corps dans un fichier temporaire puis `gh pr create --title "…" --body-file <fichier>` (ajoute `--base <cible>` si besoin) ou `gh pr edit <n> --title "…" --body-file <fichier>`. Le `--body-file` évite que le shell n'altère les backticks et les blocs Mermaid.
- S'il a seulement demandé une rédaction, ou si la branche n'est pas poussée : présente le titre et le corps, sans publier. Publier une PR est visible par d'autres — ne le fais pas sans demande explicite.

## Sortie obligatoire

Dans la conversation, fournis :

1. **Titre** — sur une ligne.
2. **Corps** — dans un bloc de code ` ```markdown ` pour qu'il soit copiable tel quel.
3. **À compléter** (seulement s'il y en a) — captures ou mesures manquantes, emplacements laissés dans le corps.
4. **Action** — le lien de la PR créée ou mise à jour, ou « non publiée ».

## Règle finale

Français sauf autre langue demandée explicitement, concis, puces : pas de dissertation hors mode article, aucune mention des tests exécutés, aucun détail intermédiaire — seul l'état final du squash par rapport à la branche cible est décrit. Et rien d'inventé : une capture ou un chiffre manquant se signale, il ne se fabrique pas.
