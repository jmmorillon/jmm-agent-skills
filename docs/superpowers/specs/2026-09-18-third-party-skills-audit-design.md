# Skills tierces et audit de sécurité — `install.sh`

_Design validé le 2026-09-18._

## Problème

`install.sh --global` sert de bootstrap « nouvelle machine » : il relie les
skills de ce dépôt et installe une liste versionnée de plugins tiers. Deux trous :

1. **Les skills tierces hors plugins ne sont pas versionnées.** 37 skills
   installées via skills.sh (`npx skills`) vivent dans `~/.agents/skills/` —
   35 de `mattpocock/skills`, `find-skills` de `vercel-labs/skills`, `ccc` de
   `cocoindex-io/cocoindex-code`. Seul `~/.agents/.skill-lock.json` en garde la
   trace ; une nouvelle machine ne les retrouve pas.
2. **Rien n'est audité.** Un plugin ou une skill tierce est du code et du prompt
   exécutés avec les droits de l'agent. Une mise à jour peut introduire un hook,
   un serveur MCP, un `curl | sh` ou une injection de prompt en prose, et elle
   est acceptée sans que personne ne l'ait lue.

## Objectifs

1. Déclarer dans `install.sh` les skills tierces à installer, par source.
2. Soumettre chaque installation et chaque mise à jour — plugins **et** skills
   tierces — à une analyse de sécurité **avant** qu'elle ne devienne active.
3. Ne demander l'avis de l'utilisateur que sur ce qui a changé et paraît
   suspect, et ne pas lui reposer une question à laquelle il a déjà répondu.

## Non-objectifs

- Plugins Copilot (`copilot plugin …`).
- Skills tierces en mode `--local`.
- Audit périodique en tâche de fond.
- Garantie de sécurité : l'analyse réduit le risque, elle ne le supprime pas.

## Limites connues

- **`node_modules` de certains plugins échappe au pipeline courant.** Claude
  Code installe lui-même les dépendances npm de quelques plugins
  (`chrome-devtools-mcp`, `atlassian`) dans leur cache, après l'installation.
  Les comparaisons de plugins (contrôle « à jour » et concordance
  post-installation, cf. Pipeline étapes 2 et 6) passent donc
  `trees_equal … --no-node-modules` — qui exclut `node_modules` à toute
  profondeur — quand la source préparée n'en contient elle-même aucun ; les
  skills restent comparées strictement. Ces dépendances ne sont jamais vues
  par le pipeline d'installation ou de mise à jour : seul `--audit-installed`
  les analyse, et lentement (environ 30 000 fichiers pour
  `chrome-devtools-mcp`).

## Décisions et leurs raisons

**Matt Pocock via skills.sh, pas via plugin.** `mattpocock-skills` existe dans
`claude-plugins-official`, mais un plugin Claude Code n'est vu que par Claude
Code (Copilot a son propre système de plugins, et Codex, Cursor, Gemini… ne
voient rien). skills.sh pose une copie unique dans `~/.agents/skills/`, lue par
tous les agents. Installer les deux canaux est à proscrire : les skills
coexistent sous deux noms (`tdd` et `mattpocock-skills:tdd`), leurs deux
descriptions chargent le contexte, le déclenchement devient aléatoire et les
versions divergent (plugin mis à jour seul, copie figée).

**Source entière moins exclusions.** Une skill publiée par l'auteur arrive à la
mise à jour sans édition de la liste ; elle passe par l'audit comme une première
installation.

**Analyse hybride.** Un filtre statique déterministe, puis une revue LLM sur le
seul diff. Le statique est gratuit et reproductible mais aveugle à la prose ; le
LLM voit l'injection en langage naturel mais coûte et varie. Limiter le LLM au
diff garde le coût bas hors première installation.

**Pré-scan en zone de préparation (approche A).** Le cache des plugins ne garde
que la version courante : après `claude plugin update`, il n'existe plus
d'ancienne version à comparer. Une skill skills.sh est active dès son
installation. Préparer la nouvelle version à part, la comparer à l'installée,
l'analyser, puis seulement l'installer, est la seule approche qui (a) analyse un
vrai diff dans les deux cas et (b) n'active jamais un contenu non accepté.

**Demander en cas de signalement.** Rapport, puis `[o/N]` ; refus par défaut.

## Configuration

En tête d'`install.sh`, à côté de `THIRD_PARTY_PLUGINS` :

```bash
# « source [-exclusion …] » : toute la source, sauf les skills préfixées de -
THIRD_PARTY_SKILLS=(
  "mattpocock/skills -implement-spec -pr -retro"
  "vercel-labs/skills"
  "cocoindex-io/cocoindex-code"
)
THIRD_PARTY_SKILL_AGENTS="claude-code github-copilot"
```

- Une entrée = une source GitHub `owner/repo`, suivie d'exclusions `-<nom>`.
- Les exclusions initiales reproduisent l'état actuel de la machine (les trois
  skills « in-progress » apparues en amont après l'installation).
- skills.sh ≥ 1.7 traite `github-copilot` comme un agent « universel » : il
  n'écrit rien dans `~/.copilot/skills`. Copilot CLI lit désormais
  `~/.agents/skills` directement, comme Codex, Cursor et Gemini (changelog de
  skills.sh : « Support `.agents/skills` directory for auto-loading skills »).
  Seul `-a claude-code` ajoute encore un pointeur, un symlink relatif
  `~/.claude/skills/<nom>` → le hub.
- `mattpocock-skills` n'est **pas** ajouté à `THIRD_PARTY_PLUGINS`.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `install.sh` | Orchestration : liste des skills tierces, pipeline, décisions, options. |
| `scripts/audit.sh` | Analyse seule, sans interaction. Utilisable en dehors d'`install.sh`. |
| `scripts/audit-prompt.md` | Prompt de la revue LLM, versionné. |
| `scripts/audit-patterns.txt` | Motifs du filtre statique, un par ligne avec sa gravité. |
| `scripts/lib.sh` | Primitives partagées : liste de fichiers, comparaison d'arbres, empreinte, refus. |
| `tests/run.sh` | Tests de `lib.sh` et d'`audit.sh` ; génère ses fixtures dans un dossier temporaire. |

**Dépendances** : `git`, `node`/`npx` (déjà requis par skills.sh ; `node -e`
lit le JSON imbriqué des `marketplace.json` et `installed_plugins.json`, là où
le `json_field` sed ne suffit pas — toujours pas de `jq`). Le CLI `claude` pour
la revue LLM ; absent, seul le filtre statique tourne, avec un avertissement.

## Options d'`install.sh`

| Option | Effet |
| --- | --- |
| `--global` | Comme aujourd'hui, plus les skills tierces ; tout passe par le pipeline. |
| `--global --uninstall` | Retire aussi les skills tierces listées (`npx skills remove -g`). |
| `--update` | Met à jour plugins et skills tierces listés, via le pipeline. Ne touche à aucun symlink. Une skill apparue dans une source déclarée est installée (c'est le sens de « source entière moins exclusions ») ; un plugin listé mais absent ne l'est pas (rôle de `--global`). Requiert le dépôt (`scripts/audit.sh`). |
| `--no-llm` | Passe `--no-llm` à `audit.sh` : filtre statique seul. |
| `--update-plugins` | Alias conservé de `--update`. |
| `--reconsider <nom>` | Efface le refus mémorisé de `<nom>`, puis le repropose au fil du mode choisi. |
| `--audit-installed` | Lance `audit.sh` en analyse complète sur chaque plugin et skill tierce installés (audit de départ). Aucune installation. |
| `--no-plugins` / `--no-agents` | Inchangés. |
| `--no-third-party-skills` | En `--global`/`--update`, ignore les skills tierces. |

## Pipeline

Commun à l'installation et à la mise à jour, élément par élément :

```text
préparer ─▶ comparer ─▶ analyser ─▶ décider ─▶ appliquer ─▶ vérifier
```

1. **Préparer**, dans un `mktemp -d` nettoyé par `trap` à la sortie :
   - _skill_ : `git clone --depth 1` de la source (un seul clone par source) ;
     découverte des dossiers contenant un `SKILL.md`, moins les exclusions.
   - _plugin_ : `claude plugin marketplace update`, puis résolution de la
     `source` de l'entrée dans `marketplace.json`. Chemin relatif → pris dans le
     marketplace cloné ; `{url, sha}` → `git clone` puis `checkout <sha>`. Toute
     autre forme → erreur pour cet élément. Une entrée qui déclare elle-même
     des composants (`hooks`, `mcpServers`, `lspServers`, `commands`, `agents`,
     `skills`) → erreur aussi : ce contenu vit dans `marketplace.json`, jamais
     préparé ni haché, donc jamais audité.
   - _skill_ : une skill homonyme d'une skill de ce dépôt (le hub pointe vers
     `skills/`) → `warn`, ignorée : jamais comparée à la nôtre ni écrasée. Le
     nom est lu dans le seul frontmatter du `SKILL.md`.
   - Calcul de l'**empreinte** (voir « Mémoire des refus »). Si elle figure
     parmi les refus, l'élément s'arrête ici : `refusé  <nom> (depuis le <date>)`.
2. **Comparer** avec l'installé — `~/.agents/skills/<nom>`, ou l'`installPath`
   lu dans `~/.claude/plugins/installed_plugins.json` :
   - identique → `ok`, fin, pas d'analyse ;
   - absent → première installation, analyse **complète** ;
   - différent → analyse du **diff**.
   - pour un plugin, la comparaison ignore `node_modules` quand le préparé
     n'en contient lui-même aucun (voir « Limites connues ») ; pour une skill,
     toujours stricte.
3. **Analyser** : `scripts/audit.sh <préparé> [--against <installé>] --name <nom>`.
4. **Décider** :
   - code `0` → accepté ;
   - code `1` ou `2` → rapport affiché, puis `Installer quand même ? [o/N]` lu
     sur stdin si stdin est un terminal (`[ -t 0 ]`). Sinon la réponse est non. La variable `INSTALL_ANSWER=o|n`, réservée aux tests, répond à la place et compte comme une réponse explicite.
   - Un non **explicite** est mémorisé ; un non faute de terminal ne l'est pas,
     pour qu'une exécution non interactive ne décide jamais à la place de
     l'utilisateur.
5. **Appliquer**, pour les seuls éléments acceptés :
   - skills : un `npx skills add <source> -g -s <acceptées…> -a <agents> -y` par
     source, le CLI épinglé (`SKILLS_CLI="skills@1.7.0"`, monté délibérément) ;
   - plugins : `claude plugin install|update <nom>@claude-plugins-official --scope user`.
6. **Vérifier la concordance** : comparer l'installé au préparé (même
   tolérance `node_modules` qu'à l'étape 2 pour un plugin). Un écart signifie
   que la source a changé entre l'analyse et l'installation → `warn`, retrait
   (`npx skills remove -g <nom>` / `claude plugin uninstall <nom> --scope user`),
   code retour non nul. Un plugin est désinstallé, pas désactivé : désactivé, il
   resterait en cache et passerait pour « à jour » au lancement suivant sans
   avoir été audité.

**Présomption de sûreté pour l'existant.** Un élément installé identique à sa
source n'est jamais analysé : au premier lancement, les 37 skills et 10 plugins
actuels passent en `ok`. `--audit-installed` est le moyen explicite d'auditer
cette base.

**Refus d'une mise à jour** : l'élément garde sa version actuelle — rien n'a été
touché. **Refus d'une première installation** : l'élément n'est pas installé.

**Résumé final** : `N à jour · M installés/mis à jour · K refusés · E erreurs`.
Code retour non nul s'il y a au moins un refus ou une erreur.

## Mémoire des refus

- Fichier local `~/.agents/.audit-refused`, non versionné. Une ligne par refus :
  `<type>:<nom> <empreinte> <date AAAA-MM-JJ>`, `<type>` ∈ `skill`, `plugin`.
- L'empreinte identifie le **contenu**, pas le numéro de version : sha256 de la
  liste triée des fichiers et de leurs contenus (pour un symlink, le texte de
  sa cible, jamais le fichier pointé), hors artefacts d'exécution
  (`.git`, `.in_use`, `.orphaned_at`, `__pycache__`, `.DS_Store`), tronqué à 16
  caractères. Une seule méthode pour tout : le marketplace de plugins n'est pas
  un dépôt git (il est téléchargé, cf. `.gcs-sha`), un hash d'arbre git n'y est
  pas disponible.
- Une empreinte différente (la source a changé) relance le pipeline normal.
- Un nouveau refus pour le même élément remplace la ligne précédente.
- `--reconsider <nom>` supprime la ligne de `<nom>`.

## `scripts/audit.sh`

```text
scripts/audit.sh <dossier> [--against <dossier_ancien>] [--name <label>] [--no-llm]
```

**Codes retour** : `0` propre · `1` signalements graves · `2` erreur de
l'analyse. Un `2` déclenche aussi la question : une analyse qui échoue ne vaut
jamais approbation. Rapport sur stdout ; aucune interaction.

**Périmètre** : fichiers ajoutés ou modifiés par rapport à `--against` (tout le
dossier sans `--against`), comparés comme dans `trees_equal`.

- **Symlinks** : jamais suivis, ni pour comparer, ni pour hacher, ni pour lire ;
  seul le texte de leur cible compte. Un lien à cible absolue, qui remonte
  au-dessus de la racine, ou dont le chemin réel se résout hors de l'arbre (ou
  ne se résout pas) est **grave** ; un lien qui reste dans l'arbre est une note.
- **Binaires** (octet NUL) : non lus. Tolérés en note s'ils portent une
  extension média connue (`png jpg jpeg gif webp ico bmp svg pdf woff woff2 ttf
  otf eot mp3 mp4 wav`) et ne sont pas exécutables ; sinon **graves** — un octet
  NUL ne doit pas soustraire un script à l'analyse.
- Les fichiers texte sont passés aux outils par lots (`xargs -0`) : un arbre
  immense ne peut pas faire échouer le filtre en silence (« Argument list too
  long »). Un lot en erreur rend l'analyse incomplète (code `2`).

### Filtre statique

`scripts/audit-patterns.txt`, format `<gravité>\t<regex ERE>\t<libellé>`,
lignes `#` ignorées. Gravités :

- **grave** (déclenche la question) :
  - téléchargement exécuté : `curl … | sh`, `wget … | bash` ;
  - exécution dynamique : `eval`, `base64 -d | sh` ;
  - accès à des secrets : `~/.ssh`, `~/.aws`, `.env`, `security find-…-password` ;
  - exfiltration : `curl -d` / `--data` vers un hôte externe ;
  - caractères Unicode invisibles ou bidirectionnels (U+200B–U+200F,
    U+202A–U+202E, U+2066–U+2069, U+E0000–U+E007F).
- **à noter** (affiché, sans question) : nouveau fichier exécutable,
  `allowed-tools` dans un `SKILL.md`, URL vers un domaine, `rm -rf`, `sudo`.

En plus des motifs, des contrôles structurels, **graves**, pour tout ce qui
s'exécute sans invocation explicite : hook (`hooks/hooks.json`, clé `"hooks"`
dans `plugin.json`, clé `hooks:` dans le frontmatter d'un Markdown — skill,
agent, commande), serveur MCP (`.mcp.json`, clé `mcpServers`), serveur LSP
(`.lsp.json`, clé `lspServers`), script npm d'installation (`preinstall`,
`install`, `postinstall`, `prepare` dans un `package.json`).

### Revue LLM

Lancée si le périmètre n'est pas vide, sauf `--no-llm` ou `claude` absent.

- `claude -p --tools "" --strict-mcp-config --mcp-config '{"mcpServers":{}}'
  --disallowedTools 'mcp__*' --setting-sources "" --disable-slash-commands
  --no-session-persistence`, lancé depuis un dossier temporaire vide : **aucun
  outil**, aucun serveur MCP, aucun réglage utilisateur/projet/local (donc ni
  hooks ni plugins activés), aucune skill. Le prompt (`audit-prompt.md`)
  présente l'élément audité comme des **données**, jamais comme des consignes :
  son nom, les signalements statiques (dont les chemins viennent de l'élément)
  et le diff sont tous entre `<<<DIFF_DEBUT` et `DIFF_FIN>>>` — une skill
  malveillante ne doit pas pouvoir piloter son auditeur.
- Cible ce que le grep ne voit pas : injection de prompt en prose (« ignore les
  instructions précédentes », « ne le dis pas à l'utilisateur »), consignes qui
  poussent l'agent à lire des secrets, à désactiver des garde-fous ou à joindre
  un service externe, écart entre la `description` d'une skill et ce que son
  corps fait.
- Reçoit aussi les signalements statiques, pour les confirmer ou les écarter en
  prose (sans pouvoir les annuler : un grave statique reste grave).
- Sortie imposée : une ligne `VERDICT: ok` ou `VERDICT: suspect` (la première
  trouvée fait foi), puis des constats `fichier:ligne — raison`. Le script ne lit que la ligne `VERDICT`.
  `suspect` = grave. Ligne absente ou illisible = code `2`.
- Au-delà de ~200 Ko, le diff est tronqué : la revue est partielle, donc code
  `2` (analyse incomplète, question posée) même si le verdict est `ok`.

## Livrables

- `install.sh` modifié (configuration, pipeline, options, `usage()`).
- `scripts/audit.sh`, `scripts/audit-prompt.md`, `scripts/audit-patterns.txt`, `scripts/lib.sh`.
- `tests/run.sh`.
- `CLAUDE.md` : section « Skills tierces et audit de sécurité » — format de
  `THIRD_PARTY_SKILLS`, pipeline, choix skills.sh plutôt que plugin pour Matt
  Pocock (et le risque de doublon), présomption de sûreté, fichier de refus.

## Vérification

**`tests/run.sh`** (bash pur) vérifie les codes retour d'`audit.sh` sur des
fixtures minimales générées à l'exécution : skill propre (`0`), `curl | sh` (`1`), caractère invisible
(`1`), hook ajouté (`1`), couple avant/après où seul l'ajout est signalé
(`--against`). Par défaut en `--no-llm`, déterministe et gratuit ; `--with-llm`
ajoute une fixture d'injection en prose attendue en `1`.

**Pipeline d'installation**, à la main dans un `HOME` jetable
(`HOME=$(mktemp -d) ./install.sh --global --no-plugins`) :

1. première installation → tout analysé, puis installé ;
2. relance → tout en `ok`, aucune analyse ;
3. fixture suspecte refusée → ligne dans `.audit-refused`, relance → `refusé` ;
4. `--reconsider <nom>` → question reposée ;
5. exécution sans terminal (`</dev/null`) → refus non mémorisé.
