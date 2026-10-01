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
| Lien vers une page web, sans contenu | Tu récupères le texte intégral de la page, mot pour mot (pas un résumé). Si l'outil ne rend qu'un résumé ou un texte coupé, dis-le en tête (« Lu jusqu'à… ») ou demande à l'utilisateur de coller le texte. |
| Lien vidéo ou audio, sans transcription | Tu t'arrêtes et demandes la transcription (ou le texte). |
| Page inaccessible, paywall, texte vide | Tu t'arrêtes, tu dis pourquoi, tu demandes le texte. |
| Titre ou thème seul | Tu demandes le contenu. **Tu n'analyses jamais de mémoire.** |

Si tu n'as pu lire qu'une partie du contenu, dis-le en tête de la sortie et précise jusqu'où tu as lu.

## Contraintes

- **Trois registres, jamais mélangés** : *ce que dit la source* (Thèse, Idées candidates), *ce que tu en sais* (Faits solides, Points faibles), *ce que tu ne peux pas trancher* (Non vérifiable).
- **Faits solides, Points faibles et Non vérifiable ne contiennent que des affirmations faites par la source.** Tes connaissances servent à les juger (la raison d'un point faible, la confirmation d'un fait), jamais à ajouter un fait que la source ne donne pas.
- **Fidélité** : chaque idée attribuée à la source doit s'y trouver. Pas d'idée ajoutée, pas de nuance retirée, pas de conclusion plus forte que celle de l'auteur.
- **Aucune invention** : ne complète jamais un chiffre, une date, un nom, une citation ; n'invente aucune source.
- **Web seulement en cas de doute** : pour un chiffre, un fait daté ou un fait récent dont tu n'es pas sûr, cherche une source primaire et cite-la. Sans source fiable trouvée : « Non vérifiable ». Ne tranche jamais au hasard.
- **Repères** : garde l'horodatage, la page ou la section quand la source les donne. N'en reconstitue jamais.
- **10 idées candidates maximum.**
- **Tu n'écris rien dans le vault.**

## Méthode

1. **Identifie la source** : titre exact, type, auteur s'il est indiqué, lien. Types : `vidéo`, `podcast`, `livre`, `article` (texte signé ou daté : presse, blog, newsletter), `page` (page de référence ou de documentation, sans auteur ni date).
2. **Lis tout le contenu** avant d'écrire quoi que ce soit.
3. **Formule la thèse** en 2-3 phrases, avec les mots de l'auteur quand c'est possible : c'est ce que *dit* l'auteur, même si une partie se révèle faible ensuite.
4. **Relève les affirmations vérifiables** de la source (chiffres, faits, dates, causalités) et range chacune dans **une seule** section, dans cet ordre de priorité :
   1. **Points faibles** — tu peux nommer un défaut : affirmation fausse, chiffre-clé sans source sur lequel l'auteur appuie sa thèse, comparaison bancale, conclusion plus forte que la prémisse, cause concurrente ignorée, contradiction, conflit d'intérêts. Écris la raison.
   2. **Faits solides** — l'affirmation est exacte, à ta connaissance sûre ou par une source que tu cites.
   3. **Non vérifiable** — ni confirmée ni infirmée, et aucun défaut nommable. Un chiffre secondaire sans source, sans rôle dans la thèse, va ici.

   Une affirmation en partie juste se scinde : la partie exacte en Faits solides, la partie défaillante en Points faibles (« se tester fait mieux retenir » / « trois fois plus, sans source »).

   Faits solides ne répète pas les Idées candidates : il sert aux faits précis (chiffres, dates, événements) qu'une fiche pourra citer.
5. **Choisis les idées candidates.** Une idée mérite d'être retenue si elle est **tangible** (fait établi, mécanisme, méthode, critère de décision) et **réutilisable hors de ce contenu**. Écarte les opinions non argumentées et les anecdotes sans portée. Si une idée s'appuie sur un chiffre faible ou non vérifiable, garde l'idée sans le chiffre. Formule chacune comme une affirmation simple. Une leçon tirée des points faibles peut être une idée : marque-la « (leçon tirée de l'analyse) », elle n'est pas attribuée à la source.
6. **Propose un avis** : 1-2 phrases sur la valeur du contenu (ce qui est utile, ce qui ne l'est pas). C'est la seule section où tu donnes un jugement personnel ; il se fonde sur les sections précédentes et se présente comme une proposition à corriger.

## Sortie obligatoire

Exactement ces sections, dans cet ordre. Une section sans contenu porte « Aucun. »

```
## Source
<Titre exact> — <type> — <auteur ou « auteur non indiqué »> — <lien ou « pas de lien »>
<Si lecture partielle : « Lu jusqu'à <repère> sur <total>. »>
<Si la source n'a aucun repère (horodatage, page, section) : « Aucun repère dans la source. »>

## Thèse
<2-3 phrases>

## Idées candidates
1. <affirmation> — <repère : MM:SS, p. n, section… ; omis si la source n'a aucun repère>
2. …

## Faits solides
- <affirmation de la source, confirmée> <(source : …) si vérifiée par recherche>

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
