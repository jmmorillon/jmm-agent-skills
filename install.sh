#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
AGENTS_SRC="$SCRIPT_DIR/agents"
AUDIT="$SCRIPT_DIR/scripts/audit.sh"
HUB="$HOME/.agents/skills"
# shellcheck source=scripts/lib.sh
. "$SCRIPT_DIR/scripts/lib.sh"

# Plugins tiers à (dé)installer en mode --global. Tous proviennent du
# marketplace officiel Anthropic. C'est le bootstrap « nouvelle machine » :
# la liste est versionnée ici, le cache ~/.claude/plugins est reconstruit.
PLUGIN_MARKETPLACE="anthropics/claude-plugins-official"
PLUGIN_MARKETPLACE_NAME="claude-plugins-official"
THIRD_PARTY_PLUGINS=(
  superpowers
  figma
  frontend-design
  code-review
  context7
  skill-creator
  playwright
  security-guidance
  atlassian
  chrome-devtools-mcp
)

# Skills tierces installées via skills.sh (npx skills) en --global, mises à
# jour par --update. « source [-exclusion …] » : toute la source GitHub, sauf
# les skills préfixées de -. Copie unique dans ~/.agents/skills (le hub), lue
# par tous les agents. -a claude-code pose en plus un symlink relatif
# ~/.claude/skills/<nom> → le hub ; -a github-copilot n'écrit rien de plus
# (skills.sh ≥ 1.7 le traite comme un agent « universel », qui lit
# ~/.agents/skills directement, comme Codex, Cursor ou Gemini CLI). Ne pas
# lister ici une source aussi installée en plugin : chaque skill existerait
# en double.
THIRD_PARTY_SKILLS=(
  "mattpocock/skills -implement-spec -pr -retro"
  "vercel-labs/skills"
  "cocoindex-io/cocoindex-code"
)
THIRD_PARTY_SKILL_AGENTS="claude-code github-copilot"

usage() {
  cat <<EOF
Usage: install.sh (--global | --local [chemin]) [--uninstall] [options]
       install.sh --update [options]
       install.sh --audit-installed [--no-llm]
       install.sh --reconsider <nom> [mode]

Relie les skills de ce dépôt par symlinks, et installe ou met à jour les skills
et plugins tiers listés dans ce script, derrière un audit de sécurité.

  --global              Relie les skills du dépôt dans le hub ~/.agents/skills,
                        exposé à ~/.claude/skills et ~/.copilot/skills, et les
                        sous-agents dans ~/.claude/agents. Installe aussi les
                        skills tierces et les plugins tiers listés.
  --local [chemin]      Relie les skills du dépôt dans <chemin>/.claude/skills et
                        <chemin>/.copilot/skills (défaut = cwd). Rien de tiers.
  --uninstall           Retire ce que ce dépôt a installé. Avec --global/--local.
  --update              Met à jour skills tierces et plugins tiers listés. Ne
                        touche à aucun symlink. Une skill apparue dans une source
                        déclarée est installée ; un plugin absent ne l'est pas.
  --update-plugins      Alias de --update.
  --audit-installed     Audite en entier chaque skill tierce et plugin tiers
                        installé. N'installe rien. Un appel LLM par élément.
  --reconsider <nom>    Oublie le refus mémorisé de <nom> (skill ou plugin) pour
                        qu'il soit reproposé. Seul, ne fait que ça.
  --no-plugins          Ignore les plugins tiers.
  --no-third-party-skills
                        Ignore les skills tierces.
  --no-agents           Ignore les sous-agents (dossier agents/).
  --no-llm              Audit par filtre statique seul, sans revue LLM.
  -h, --help            Affiche cette aide.

Audit de sécurité : chaque nouvelle version est préparée à part, comparée à la
version installée, analysée par scripts/audit.sh, puis installée. En cas de
signalement grave, la question [o/N] est posée. Un non est mémorisé dans
~/.agents/.audit-refused et vaut tant que le contenu ne change pas. Sans
terminal, la réponse est non, sans être mémorisée.

Plugins : marketplace $PLUGIN_MARKETPLACE, scope user.
Prérequis : git et node/npx (skills tierces), CLI 'claude' (plugins, revue LLM).
Redémarrer Claude Code pour appliquer les plugins installés ou mis à jour.
Idempotent. Ne supprime jamais un fichier ou un symlink pointant ailleurs.
EOF
}

MODE=""
ACTION="install"
LOCAL_PATH=""
INCLUDE_PLUGINS="yes"
INCLUDE_AGENTS="yes"
INCLUDE_TP_SKILLS="yes"
USE_LLM="yes"
RECONSIDER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --global)
      MODE="global"
      shift
      ;;
    --local)
      MODE="local"
      if [ $# -ge 2 ] && [[ "$2" != --* ]]; then
        LOCAL_PATH="$2"
        shift 2
      else
        LOCAL_PATH="$(pwd)"
        shift
      fi
      ;;
    --uninstall)
      ACTION="uninstall"
      shift
      ;;
    --update|--update-plugins)
      MODE="update"
      shift
      ;;
    --audit-installed)
      MODE="audit-installed"
      shift
      ;;
    --reconsider)
      if [ $# -lt 2 ] || [[ "$2" == -* ]]; then
        echo "Erreur : --reconsider attend un nom." >&2
        usage >&2
        exit 2
      fi
      RECONSIDER="$2"
      shift 2
      ;;
    --no-plugins)
      INCLUDE_PLUGINS="no"
      shift
      ;;
    --no-third-party-skills)
      INCLUDE_TP_SKILLS="no"
      shift
      ;;
    --no-agents)
      INCLUDE_AGENTS="no"
      shift
      ;;
    --no-llm)
      USE_LLM="no"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Option inconnue : $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$MODE" ]; then
  if [ -n "$RECONSIDER" ]; then
    forget_refusal "$RECONSIDER"
    echo "oubli refus de $RECONSIDER : il sera reproposé"
    exit 0
  fi
  echo "Erreur : --global, --local, --update ou --audit-installed requis." >&2
  usage >&2
  exit 2
fi

if { [ "$MODE" = "update" ] || [ "$MODE" = "audit-installed" ]; } && [ "$ACTION" = "uninstall" ]; then
  echo "Erreur : --$MODE ne se combine pas avec --uninstall." >&2
  exit 2
fi

if { [ "$MODE" = "global" ] || [ "$MODE" = "local" ]; } && [ ! -d "$SKILLS_SRC" ]; then
  echo "Erreur : dossier source $SKILLS_SRC introuvable." >&2
  exit 1
fi

if [ "$MODE" != "local" ] && [ ! -x "$AUDIT" ]; then
  echo "Erreur : $AUDIT introuvable ; l'audit de sécurité est obligatoire." >&2
  exit 1
fi

# Appliqué seulement une fois toutes les validations passées : une commande
# invalide (ex. --update --uninstall) ne doit pas oublier le refus au passage.
if [ -n "$RECONSIDER" ]; then
  forget_refusal "$RECONSIDER"
  echo "oubli refus de $RECONSIDER : il sera reproposé"
fi

# Crée $link → $target. Idempotent. Ne touche pas à un symlink qui pointe
# ailleurs ni à un fichier réel.
link_skill() {
  local link="$1"
  local target="$2"

  if [ -L "$link" ]; then
    local current
    current="$(readlink "$link")"
    if [ "$current" = "$target" ]; then
      echo "ok    $link"
    else
      echo "warn  $link pointe vers $current, ignoré"
    fi
  elif [ -e "$link" ]; then
    echo "warn  $link existe (pas un symlink), ignoré"
  else
    ln -s "$target" "$link"
    echo "lien  $link → $target"
  fi
}

# Retire $link s'il est un symlink pointant exactement vers $target.
# Refuse de toucher autre chose.
unlink_skill() {
  local link="$1"
  local target="$2"

  if [ -L "$link" ]; then
    local current
    current="$(readlink "$link")"
    if [ "$current" = "$target" ]; then
      rm "$link"
      echo "rm    $link"
    else
      echo "skip  $link pointe vers $current"
    fi
  elif [ -e "$link" ]; then
    echo "skip  $link existe (pas un symlink)"
  fi
}

install_skills_into() {
  local dir="$1"
  mkdir -p "$dir"
  local src name
  for src in "$SKILLS_SRC"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    name="$(basename "$src")"
    link_skill "$dir/$name" "$src"
  done
}

uninstall_skills_from() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local src name
  for src in "$SKILLS_SRC"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    name="$(basename "$src")"
    unlink_skill "$dir/$name" "$src"
  done
}

# Sous-agents : fichiers .md plats (pas de dossier), Claude Code uniquement.
# Symlink direct vers la source absolue, comme le hub des skills.
install_agents_into() {
  local dir="$1"
  [ -d "$AGENTS_SRC" ] || return 0
  mkdir -p "$dir"
  local src name
  for src in "$AGENTS_SRC"/*.md; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    link_skill "$dir/$name" "$src"
  done
}

uninstall_agents_from() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  [ -d "$AGENTS_SRC" ] || return 0
  local src name
  for src in "$AGENTS_SRC"/*.md; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    unlink_skill "$dir/$name" "$src"
  done
}

# Expose chaque skill du hub à un outil : ~/.<tool>/skills/<name> → ../../.agents/skills/<name>.
# Cible relative pour matcher la convention déjà en place dans ce setup.
expose_hub_to_tool() {
  local tool="$1"
  local tool_skills="$HOME/.$tool/skills"
  mkdir -p "$tool_skills"

  local src name rel_target
  for src in "$SKILLS_SRC"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    name="$(basename "$src")"
    rel_target="../../.agents/skills/$name"
    link_skill "$tool_skills/$name" "$rel_target"
  done
}

unexpose_hub_from_tool() {
  local tool="$1"
  local tool_skills="$HOME/.$tool/skills"
  [ -d "$tool_skills" ] || return 0

  local src name rel_target
  for src in "$SKILLS_SRC"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    name="$(basename "$src")"
    rel_target="../../.agents/skills/$name"
    unlink_skill "$tool_skills/$name" "$rel_target"
  done
}

# --- Pipeline d'audit : préparer → comparer → analyser → décider → appliquer → vérifier

N_OK=0
N_APPLIED=0
N_REFUSED=0
N_ERR=0
STAGE=""

# Crée le dossier de préparation, supprimé à la sortie du script.
stage_dir() {
  if [ -z "$STAGE" ]; then
    STAGE="$(mktemp -d)"
    trap 'rm -rf "$STAGE"' EXIT
  fi
}

# Pose la question o/N. 0 = oui · 1 = non explicite · 2 = pas de terminal.
# INSTALL_ANSWER (o|n) répond à la place de l'utilisateur : réservé aux tests.
ask_install() {
  local answer="${INSTALL_ANSWER:-}"
  if [ -z "$answer" ]; then
    if [ ! -t 0 ]; then return 2; fi
    printf '      Installer quand même ? [o/N] '
    read -r answer || answer=""
  fi
  case "$answer" in
    o|O|oui|y|Y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

# gate <type> <nom> <préparé> <installé|""> <empreinte>
# 0 = à appliquer · 1 = déjà à jour · 2 = refusé (maintenant ou auparavant)
gate() {
  local kind="$1" name="$2" staged="$3" installed="$4" hash="$5"
  local since arc=0 qrc=0
  if since="$(refused_since "$kind" "$name" "$hash")"; then
    echo "refusé $name (depuis le $since ; --reconsider $name pour revoir)"
    N_REFUSED=$((N_REFUSED + 1))
    return 2
  fi
  if [ -n "$installed" ] && trees_equal "$staged" "$installed"; then
    echo "ok    $name"
    N_OK=$((N_OK + 1))
    return 1
  fi
  local args=("$staged" --name "$kind:$name")
  if [ -n "$installed" ] && [ -d "$installed" ]; then args+=(--against "$installed"); fi
  if [ "$USE_LLM" = "no" ]; then args+=(--no-llm); fi
  "$AUDIT" "${args[@]}" | sed 's/^/      /' || arc=$?
  if [ "$arc" -eq 0 ]; then return 0; fi
  ask_install || qrc=$?
  case "$qrc" in
    0)
      echo "      accepté malgré les signalements"
      return 0 ;;
    1)
      record_refusal "$kind" "$name" "$hash"
      echo "refusé $name (mémorisé)"
      N_REFUSED=$((N_REFUSED + 1))
      return 2 ;;
    *)
      echo "refusé $name (pas de terminal ; refus non mémorisé)"
      N_REFUSED=$((N_REFUSED + 1))
      return 2 ;;
  esac
}

# Bilan ; 1 s'il y a au moins un refus ou une erreur.
summary() {
  echo "→ bilan : $N_OK à jour · $N_APPLIED installé(s) ou mis à jour · $N_REFUSED refusé(s) · $N_ERR erreur(s)"
  if [ "$N_REFUSED" -gt 0 ] || [ "$N_ERR" -gt 0 ]; then return 1; fi
}

# Nom d'une skill : champ name: de son SKILL.md, à défaut le nom du dossier.
skill_name() {
  local n
  n="$(awk '/^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }' "$1/SKILL.md" | tr -d "\"'")"
  printf '%s\n' "${n:-$(basename "$1")}"
}

# Noms des skills installées depuis la source $1, lus dans le verrou skills.sh.
skills_from_source() {
  local lock="$HOME/.agents/.skill-lock.json"
  if [ ! -f "$lock" ]; then return 0; fi
  node -e '
    const [lock, src] = process.argv.slice(1);
    const skills = require(lock).skills || {};
    for (const [name, s] of Object.entries(skills)) if (s.source === src) console.log(name);
  ' "$lock" "$1"
}

# Clone une source déclarée, passe chaque skill au pipeline, installe les
# acceptées en un seul appel à skills.sh, puis vérifie la concordance.
sync_skill_source() {
  local src excl clone dir name installed hash rc
  read -r src excl <<< "$1"
  echo "→ skills $src"
  clone="$STAGE/skills/${src//\//__}"
  if ! git clone -q --depth 1 "https://github.com/$src.git" "$clone" 2>/dev/null; then
    echo "warn  $src : clone impossible"
    N_ERR=$((N_ERR + 1))
    return 0
  fi
  local found=() names=() dirs=()
  while IFS= read -r dir; do found+=("$dir"); done \
    < <(find "$clone" -name SKILL.md -not -path '*/.git/*' -exec dirname {} \; | LC_ALL=C sort)
  if [ ${#found[@]} -eq 0 ]; then
    echo "warn  $src : aucune skill trouvée"
    N_ERR=$((N_ERR + 1))
    return 0
  fi
  for dir in "${found[@]}"; do
    name="$(skill_name "$dir")"
    if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
      echo "warn  $src : nom de skill invalide « $name », ignoré"
      N_ERR=$((N_ERR + 1))
      continue
    fi
    case " $excl " in *" -$name "*) echo "exclu $name"; continue ;; esac
    installed=""
    if [ -d "$HUB/$name" ]; then installed="$HUB/$name"; fi
    hash="$(content_hash "$dir")"
    rc=0
    gate skill "$name" "$dir" "$installed" "$hash" || rc=$?
    if [ "$rc" -eq 0 ]; then
      names+=("$name")
      dirs+=("$dir")
    fi
  done
  if [ ${#names[@]} -eq 0 ]; then return 0; fi
  # shellcheck disable=SC2086 # liste d'agents volontairement découpée
  if ! npx --yes skills add "$src" -g -s "${names[@]}" -a $THIRD_PARTY_SKILL_AGENTS -y </dev/null >/dev/null 2>&1; then
    echo "warn  $src : échec de npx skills add"
    N_ERR=$((N_ERR + 1))
    return 0
  fi
  local i
  for i in "${!names[@]}"; do
    if trees_equal "${dirs[$i]}" "$HUB/${names[$i]}"; then
      echo "maj   ${names[$i]}"
      N_APPLIED=$((N_APPLIED + 1))
    else
      echo "warn  ${names[$i]} : l'installé diffère de l'analysé (la source a bougé), retiré"
      npx --yes skills remove -g -y "${names[$i]}" </dev/null >/dev/null 2>&1 || true
      N_ERR=$((N_ERR + 1))
    fi
  done
}

# 0 si les outils des skills tierces sont présents ; sinon avertit.
skills_tools_ok() {
  local c
  for c in git node npx; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "warn  '$c' introuvable, skills tierces ignorées"
      return 1
    fi
  done
}

sync_skills() {
  local entry
  if ! skills_tools_ok; then return 0; fi
  for entry in "${THIRD_PARTY_SKILLS[@]}"; do sync_skill_source "$entry"; done
}

# Retire les skills installées depuis chaque source déclarée.
uninstall_third_party_skills() {
  local entry src n
  if ! skills_tools_ok; then return 0; fi
  for entry in "${THIRD_PARTY_SKILLS[@]}"; do
    read -r src _ <<< "$entry"
    local names=()
    while IFS= read -r n; do names+=("$n"); done < <(skills_from_source "$src")
    if [ ${#names[@]} -eq 0 ]; then
      echo "skip  $src (aucune skill installée)"
      continue
    fi
    if npx --yes skills remove -g -y "${names[@]}" </dev/null >/dev/null 2>&1; then
      echo "rm    $src : ${names[*]}"
    else
      echo "warn  $src : échec de npx skills remove"
    fi
  done
}

# Installe les plugins tiers via le CLI 'claude' (scope user, non interactif).
# Idempotent : le marketplace déjà connu et un plugin déjà installé renvoient
# une erreur bénigne, absorbée sans faire échouer le script.
install_plugins() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "warn  CLI 'claude' introuvable, plugins tiers ignorés"
    return 0
  fi

  echo "→ marketplace $PLUGIN_MARKETPLACE"
  claude plugin marketplace add "$PLUGIN_MARKETPLACE" --scope user >/dev/null 2>&1 || true

  local plugin
  for plugin in "${THIRD_PARTY_PLUGINS[@]}"; do
    if claude plugin install "${plugin}@${PLUGIN_MARKETPLACE_NAME}" --scope user >/dev/null 2>&1; then
      echo "plug  ${plugin}"
    else
      echo "ok    ${plugin} (déjà présent ou sans changement)"
    fi
  done
}

# Désinstalle uniquement les plugins listés dans ce script (scope user).
uninstall_plugins() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "warn  CLI 'claude' introuvable, plugins tiers ignorés"
    return 0
  fi

  local plugin
  for plugin in "${THIRD_PARTY_PLUGINS[@]}"; do
    if claude plugin uninstall "${plugin}@${PLUGIN_MARKETPLACE_NAME}" --scope user --yes >/dev/null 2>&1; then
      echo "rm    ${plugin}"
    else
      echo "skip  ${plugin} (absent)"
    fi
  done
}

# Extrait la valeur texte du champ $2 dans la ligne JSON $1. Suffisant pour les
# champs plats de 'claude plugin update --json' ; pas un parseur JSON.
json_field() {
  printf '%s' "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"
}

# Rafraîchit le marketplace puis met à jour chaque plugin listé (scope user).
# N'installe rien : un plugin absent est signalé, pas ajouté — c'est le rôle de
# --global. Le redémarrage de Claude Code applique les mises à jour.
update_plugins() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "Erreur : CLI 'claude' introuvable, plugins non mis à jour." >&2
    exit 1
  fi

  echo "→ marketplace $PLUGIN_MARKETPLACE_NAME"
  if ! claude plugin marketplace update "$PLUGIN_MARKETPLACE_NAME" >/dev/null 2>&1; then
    echo "warn  marketplace non rafraîchi, mise à jour depuis le cache local"
  fi

  local plugin out updated=0
  for plugin in "${THIRD_PARTY_PLUGINS[@]}"; do
    if out="$(claude plugin update "${plugin}@${PLUGIN_MARKETPLACE_NAME}" --scope user --json 2>/dev/null)"; then
      if [ "$(json_field "$out" updateOutcome)" = "up_to_date" ]; then
        echo "ok    ${plugin} ($(json_field "$out" newVersion))"
      else
        echo "maj   ${plugin} $(json_field "$out" oldVersion) → $(json_field "$out" newVersion)"
        updated=$((updated + 1))
      fi
    else
      echo "warn  ${plugin} non mis à jour ($(json_field "$out" failureCode))"
    fi
  done

  if [ "$updated" -gt 0 ]; then
    echo "→ $updated plugin(s) mis à jour : redémarre Claude Code pour appliquer."
  else
    echo "→ tous les plugins sont déjà à jour."
  fi
}

case "$MODE:$ACTION" in
  update:install)
    stage_dir
    if [ "$INCLUDE_TP_SKILLS" = "yes" ]; then sync_skills; fi
    if [ "$INCLUDE_PLUGINS" = "yes" ]; then update_plugins; fi
    summary || exit 1
    ;;

  global:install)
    install_skills_into "$HUB"
    expose_hub_to_tool claude
    expose_hub_to_tool copilot
    if [ "$INCLUDE_AGENTS" = "yes" ]; then install_agents_into "$HOME/.claude/agents"; fi
    stage_dir
    if [ "$INCLUDE_TP_SKILLS" = "yes" ]; then sync_skills; fi
    if [ "$INCLUDE_PLUGINS" = "yes" ]; then install_plugins; fi
    summary || exit 1
    ;;

  global:uninstall)
    unexpose_hub_from_tool claude
    unexpose_hub_from_tool copilot
    uninstall_skills_from "$HUB"
    if [ "$INCLUDE_AGENTS" = "yes" ]; then uninstall_agents_from "$HOME/.claude/agents"; fi
    if [ "$INCLUDE_TP_SKILLS" = "yes" ]; then uninstall_third_party_skills; fi
    if [ "$INCLUDE_PLUGINS" = "yes" ]; then uninstall_plugins; fi
    ;;

  local:install)
    install_skills_into "$LOCAL_PATH/.claude/skills"
    install_skills_into "$LOCAL_PATH/.copilot/skills"
    if [ "$INCLUDE_AGENTS" = "yes" ]; then install_agents_into "$LOCAL_PATH/.claude/agents"; fi
    ;;

  local:uninstall)
    uninstall_skills_from "$LOCAL_PATH/.claude/skills"
    uninstall_skills_from "$LOCAL_PATH/.copilot/skills"
    if [ "$INCLUDE_AGENTS" = "yes" ]; then uninstall_agents_from "$LOCAL_PATH/.claude/agents"; fi
    ;;
esac
