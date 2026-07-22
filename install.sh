#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
AGENTS_SRC="$SCRIPT_DIR/agents"

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

usage() {
  cat <<EOF
Usage: install.sh (--global | --local [chemin]) [--uninstall]

Installe (ou désinstalle) les skills de ce dépôt par symlinks.

  --global              Installe dans le hub ~/.agents/skills, puis expose ce
                        hub à ~/.claude/skills et ~/.copilot/skills (un symlink
                        racine par outil). Tu gères les skills à un seul
                        endroit ; les deux outils les voient.
  --local [chemin]      Installe directement dans <chemin>/.claude/skills et
                        <chemin>/.copilot/skills (défaut chemin = cwd). Utile
                        pour limiter une skill à un projet.
  --uninstall           Retire les symlinks créés par ce dépôt. À combiner
                        avec --global ou --local [chemin].
  --no-plugins          En mode --global, n'installe (ni ne désinstalle) pas les
                        plugins tiers ; seuls skills et sous-agents sont gérés.
  --no-agents           Ne gère pas les sous-agents (dossier agents/) ; seuls
                        les skills (et, en --global, les plugins) sont gérés.
  -h, --help            Affiche cette aide.

Les sous-agents du dossier agents/ (fichiers .md, Claude Code uniquement) sont
symlinkés vers ~/.claude/agents (--global) ou <chemin>/.claude/agents (--local),
sauf avec --no-agents.

En mode --global, installe aussi les plugins tiers listés dans ce script
(superpowers, figma, …) depuis le marketplace $PLUGIN_MARKETPLACE, via le CLI
'claude' (scope user). Nécessite 'claude' dans le PATH ; sinon les plugins sont
ignorés avec un avertissement (les symlinks restent installés).

Idempotent : relancer l'installation est sans effet si tout est déjà en place.
Sûr : ne supprime jamais un fichier ou un symlink pointant ailleurs.
EOF
}

MODE=""
ACTION="install"
LOCAL_PATH=""
INCLUDE_PLUGINS="yes"
INCLUDE_AGENTS="yes"

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
    --no-plugins)
      INCLUDE_PLUGINS="no"
      shift
      ;;
    --no-agents)
      INCLUDE_AGENTS="no"
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
  echo "Erreur : --global ou --local requis." >&2
  usage >&2
  exit 2
fi

if [ ! -d "$SKILLS_SRC" ]; then
  echo "Erreur : dossier source $SKILLS_SRC introuvable." >&2
  exit 1
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

case "$MODE:$ACTION" in
  global:install)
    HUB="$HOME/.agents/skills"
    install_skills_into "$HUB"
    expose_hub_to_tool claude
    expose_hub_to_tool copilot
    if [ "$INCLUDE_AGENTS" = "yes" ]; then install_agents_into "$HOME/.claude/agents"; fi
    if [ "$INCLUDE_PLUGINS" = "yes" ]; then install_plugins; fi
    ;;

  global:uninstall)
    HUB="$HOME/.agents/skills"
    unexpose_hub_from_tool claude
    unexpose_hub_from_tool copilot
    uninstall_skills_from "$HUB"
    if [ "$INCLUDE_AGENTS" = "yes" ]; then uninstall_agents_from "$HOME/.claude/agents"; fi
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
