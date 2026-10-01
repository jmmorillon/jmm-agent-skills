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

<Facultatif — exemples, seulement si la source en donne :>
**Exemples tirés de <la vidéo / l'article / le livre> :**
- <exemple concret donné par la source>

<Facultatif — règle pratique ou indice qui découle de l'idée, en une phrase.>

<Facultatif — **Réserve :** limite relevée par l'analyse (et non par la source), en une phrase.>

## Liens

- [[<fiche existante>]] : <pourquoi elle est liée, en une proposition>.
```

## Règles

- **Une fiche = une idée.** Si tu as besoin de « et » dans le titre pour relier deux thèses, ce sont deux fiches.
- **Titre = affirmation** qu'on peut citer seule (« Raccorder prend plus de temps que produire »), pas un sujet (« Le raccordement »).
- **`source`** : lien wiki vers la note de littérature ; en mode « idée dictée », ce que l'utilisateur indique (lien wiki vers une note existante, ou texte brut), toujours entre guillemets ; pas de source → supprime la ligne.
- **Exemples** : uniquement ceux de la source (y compris pour une fiche « leçon tirée de l'analyse », qui cite le passage fautif), présentés comme tels. Aucun exemple inventé ; pas de source ou pas d'exemple → supprime le bloc.
- **`## Liens`** : seulement vers des fichiers existants de `Prise de notes/` (ou vers des fiches créées dans le même lot). Aucune fiche liée pertinente → supprime la section.
- **Tags** : 2 à 4, en minuscules, sans accents, mots séparés par `-`, préfixés `#`, entre guillemets. Réutilise d'abord les tags déjà présents dans `Prise de notes/`.
