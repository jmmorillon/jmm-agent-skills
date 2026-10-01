# Gabarit — note de littérature

Remplace chaque `<…>`. Une section sans contenu est supprimée, jamais laissée vide.

```markdown
---
id: <AAAAMMJJHHmm>
title: <titre de la source, sans « : »> (<vidéo|article|livre|podcast|page>)
aliases:
  - <alias court, facultatif>
type: literature-note
tags:
  - "#<tag>"
source: <description de la source, ex. Vidéo YouTube « … » de <auteur>>
date_created: <AAAA-MM-JJ>
---
[<titre original exact>](<url>)

# <titre, identique au title>

> [!abstract] Thèse de <la vidéo / l'article / le livre…>
> <thèse en 2-3 phrases>
>
> **Mon avis :** <avis validé par l'utilisateur>

## Idées extraites → fiches permanentes

- [<MM:SS>](<url horodatée>) <idée en une phrase> → [[<titre de la fiche>]]
- <idée sans repère> → [[<titre de la fiche>]]
- <idée déjà couverte> → [[<fiche existante>]] (fiche existante)

## Faits solides (vérifiés dans l'ensemble)

- <fait> <(source : …) si vérifié par recherche web>

## Points faibles

- <affirmation> : <raison>.

## Non vérifiable

- <affirmation>

## Liens

- [[<note existante>]] : <pourquoi>.
```

## Règles

- **Ligne d'URL** en tête du corps : seulement si la source a une URL. Sinon, supprime la ligne.
- **Repères horodatés** : seulement s'ils figurent dans la transcription fournie. URL horodatée YouTube : `<url>&t=<secondes>s`. Page de livre : `p. <n>` sans lien. Jamais de repère reconstitué.
- **Leçon tirée de l'analyse** (et non de la source, par ex. tirée des points faibles) : ligne sans repère, préfixée « Leçon tirée des faiblesses de la source → ».
- **« Mon avis »** : le texte validé par l'utilisateur, mot pour mot.
