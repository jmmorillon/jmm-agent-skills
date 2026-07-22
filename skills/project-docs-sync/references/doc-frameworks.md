# Frameworks de documentation de site

À lire quand l'inventaire a détecté un site de doc. Objectif : savoir **où vivent les pages**, **comment est déclarée la navigation**, et **quelles conventions respecter** avant de modifier ou d'ajouter une page. Dans tous les cas : édition ciblée, on respecte le format existant, et si on ajoute une page on l'inscrit dans la navigation pour qu'elle ne reste pas orpheline.

## Table des matières

- [VitePress](#vitepress)
- [VuePress](#vuepress)
- [MkDocs](#mkdocs)
- [Docusaurus](#docusaurus)
- [Starlight (Astro)](#starlight-astro)
- [Doc « brute » (Markdown sans framework)](#doc-brute)
- [Réflexe commun](#réflexe-commun)

## VitePress

- **Détection** : `docs/.vitepress/config.{js,ts,mjs,mts}` (ou `.vitepress/` à un autre niveau).
- **Pages** : fichiers `.md` sous la racine de doc (souvent `docs/`). L'URL suit l'arborescence des fichiers.
- **Navigation** : définie dans `config.*` via les clés `themeConfig.nav` (barre du haut) et `themeConfig.sidebar` (barre latérale). Une nouvelle page n'apparaît dans la sidebar que si elle y est ajoutée — pense à l'y inscrire.
- **Frontmatter** : YAML optionnel en tête de page (`title`, `outline`, `editLink`…). La page d'accueil peut utiliser `layout: home` avec des `features` structurées — respecte ce format si présent.
- **Conventions** : liens internes en `.md` relatifs ; blocs de conteneurs personnalisés (`::: tip`, `::: warning`).

## VuePress

- **Détection** : `docs/.vuepress/config.{js,ts}` ou `.vuepress/`.
- **Pages** : `.md` sous `docs/`, routage par arborescence (proche de VitePress, dont il est l'ancêtre).
- **Navigation** : `themeConfig.navbar` et `themeConfig.sidebar` dans `.vuepress/config.*`. Sidebar souvent déclarée explicitement → ajoute-y toute nouvelle page.
- **Frontmatter** : YAML (`title`, `lang`, `sidebar`…).
- **Attention à la version** : VuePress 1 et 2 diffèrent sur la config et le thème. Repère la version dans `package.json` avant de toucher la config.

## MkDocs

- **Détection** : `mkdocs.yml` (ou `mkdocs.yaml`) à la racine.
- **Pages** : `.md` sous `docs/` par défaut (voir la clé `docs_dir`).
- **Navigation** : clé `nav:` dans `mkdocs.yml` — un arbre explicite de titres → fichiers. Si `nav` est défini, une nouvelle page **doit** y être ajoutée pour être visible.
- **Thème** : souvent *Material for MkDocs* (`theme: name: material`), qui ajoute des extensions Markdown (admonitions `!!! note`, onglets de contenu). Respecte-les si présentes.
- **Conventions** : liens internes vers des fichiers `.md` ; `mkdocs.yml` est du YAML strict — attention à l'indentation.

## Docusaurus

- **Détection** : `docusaurus.config.{js,ts}`.
- **Pages** : docs sous `docs/`, blog sous `blog/`, pages libres sous `src/pages/`. Distingue bien doc et blog.
- **Navigation** : la sidebar est dans `sidebars.{js,ts}` (explicite ou auto-générée). La navbar est dans `docusaurus.config.*` (`themeConfig.navbar`). Si la sidebar est explicite, inscris-y la nouvelle page.
- **Frontmatter** : `id`, `title`, `sidebar_position`, `slug`. L'ordre dans une sidebar auto-générée dépend de `sidebar_position` → renseigne-le pour une nouvelle page.
- **Conventions** : supporte MDX (composants React dans le Markdown) — ne casse pas un import ou un composant existant.

## Starlight (Astro)

- **Détection** : `astro.config.{mjs,ts}` avec la dépendance `@astrojs/starlight`.
- **Pages** : contenu sous `src/content/docs/` en `.md`/`.mdx`. Le routage suit l'arborescence.
- **Navigation** : `sidebar` déclarée dans l'intégration `starlight({...})` de `astro.config.*` (groupes explicites ou `autogenerate` par dossier). Ajoute la page au bon groupe si la sidebar est explicite.
- **Frontmatter** : `title` (requis), `description`, `sidebar` (ordre/badge). Respecte le schéma de collection Astro — un frontmatter invalide casse le build.

## Doc « brute »

- **Détection** : un dossier `docs/` (ou similaire) rempli de `.md` sans fichier de config connu.
- **Approche** : pas de navigation à maintenir séparément. Mets à jour directement les fichiers `.md` concernés. S'il existe un `docs/README.md` ou un `index.md` faisant office de sommaire, tiens-le à jour quand tu ajoutes une page.

## Réflexe commun

1. **Localise** la page qui correspond au sujet modifié (par titre, par nom de fichier, par section).
2. **Édite** de façon ciblée, en gardant le frontmatter et le style de la page.
3. Si une **nouvelle page** est justifiée, crée-la avec le frontmatter attendu par le framework **et** inscris-la dans la navigation (sidebar/nav) pour qu'elle soit atteignable.
4. Ne touche pas à la config du framework au-delà de l'ajout de navigation nécessaire ; ne « modernise » pas une config qui fonctionne.
