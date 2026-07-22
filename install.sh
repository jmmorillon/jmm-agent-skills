#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"

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
  -h, --help            Affiche cette aide.

Idempotent : relancer l'installation est sans effet si tout est déjà en place.
Sûr : ne supprime jamais un fichier ou un symlink pointant ailleurs.
EOF
}

MODE=""
ACTION="install"
LOCAL_PATH=""

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

case "$MODE:$ACTION" in
  global:install)
    HUB="$HOME/.agents/skills"
    install_skills_into "$HUB"
    expose_hub_to_tool claude
    expose_hub_to_tool copilot
    ;;

  global:uninstall)
    HUB="$HOME/.agents/skills"
    unexpose_hub_from_tool claude
    unexpose_hub_from_tool copilot
    uninstall_skills_from "$HUB"
    ;;

  local:install)
    install_skills_into "$LOCAL_PATH/.claude/skills"
    install_skills_into "$LOCAL_PATH/.copilot/skills"
    ;;

  local:uninstall)
    uninstall_skills_from "$LOCAL_PATH/.claude/skills"
    uninstall_skills_from "$LOCAL_PATH/.copilot/skills"
    ;;
esac
