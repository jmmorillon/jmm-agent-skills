#!/usr/bin/env bash
# Analyse de sécurité d'une skill ou d'un plugin avant installation.
# Ne pose aucune question : c'est l'appelant (install.sh) qui décide.
# Code retour : 0 propre · 1 signalements graves · 2 erreur de l'analyse.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"
PATTERNS="$SCRIPT_DIR/audit-patterns.txt"

usage() {
  cat <<EOF
Usage: audit.sh <dossier> [--against <dossier_ancien>] [--name <label>] [--no-llm]

Analyse les fichiers de <dossier> ajoutés ou modifiés par rapport à
<dossier_ancien> (tout <dossier> sans --against) : filtre statique
(audit-patterns.txt, hooks, serveurs MCP, Unicode invisible), puis revue LLM
via 'claude -p' sans outils, sauf --no-llm.

Code retour : 0 propre · 1 signalements graves · 2 erreur de l'analyse.
EOF
}

TARGET=""
AGAINST=""
NAME=""
USE_LLM="yes"
while [ $# -gt 0 ]; do
  case "$1" in
    --against) AGAINST="${2:?--against attend un dossier}"; shift 2 ;;
    --name) NAME="${2:?--name attend un libellé}"; shift 2 ;;
    --no-llm) USE_LLM="no"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Option inconnue : $1" >&2; usage >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Erreur : dossier à analyser introuvable (${TARGET:-aucun})." >&2
  exit 2
fi
if [ -n "$AGAINST" ] && [ ! -d "$AGAINST" ]; then
  echo "Erreur : --against $AGAINST introuvable." >&2
  exit 2
fi
NAME="${NAME:-$(basename "$TARGET")}"

GRAVE=0
LLM_ERROR=0
FINDINGS=""

# report <grave|note> <emplacement> <libellé>
report() {
  local line
  line="$(printf '  [%s] %s — %s' "$1" "$2" "$3")"
  echo "$line"
  FINDINGS="${FINDINGS}${line}"$'\n'
  if [ "$1" = "grave" ]; then GRAVE=$((GRAVE + 1)); fi
}

# Fichiers ajoutés ou modifiés par rapport à --against (tous sans --against).
changed_files() {
  local f
  list_files "$TARGET" | while IFS= read -r f; do
    if [ -z "$AGAINST" ] || [ ! -e "$AGAINST/$f" ] || ! cmp -s "$TARGET/$f" "$AGAINST/$f"; then
      printf '%s\n' "$f"
    fi
  done
}

# Motifs d'audit-patterns.txt sur les fichiers texte.
static_patterns() {
  local sev re label hit
  if [ ${#TEXT[@]} -eq 0 ]; then return 0; fi
  while IFS=$'\t' read -r sev re label; do
    case "$sev" in ''|'#'*) continue ;; esac
    while IFS= read -r hit; do
      report "$sev" "$hit" "$label"
    done < <(cd "$TARGET" && grep -EnH -e "$re" -- "${TEXT[@]}" 2>/dev/null | cut -d: -f1,2 || true)
  done < "$PATTERNS"
}

# Contrôles qui ne tiennent pas dans une regex : hooks, MCP, exécutables,
# Unicode invisible, domaines cités.
structural_checks() {
  local f hit domains
  for f in "${CHANGED[@]}"; do
    case "$f" in
      hooks/hooks.json|*/hooks/hooks.json)
        report grave "$f" "hook : s'exécute sans invocation explicite" ;;
      .mcp.json|*/.mcp.json)
        report grave "$f" "serveur MCP : s'exécute sans invocation explicite" ;;
      *.json)
        if grep -q '"mcpServers"' "$TARGET/$f" 2>/dev/null; then
          report grave "$f" "déclare des serveurs MCP (mcpServers)"
        fi ;;
    esac
    case "$f" in
      plugin.json|*/plugin.json)
        if grep -q '"hooks"' "$TARGET/$f" 2>/dev/null; then
          report grave "$f" "déclare des hooks"
        fi ;;
    esac
    if [ -f "$TARGET/$f" ] && [ -x "$TARGET/$f" ]; then
      if [ -z "$AGAINST" ] || [ ! -e "$AGAINST/$f" ]; then
        report note "$f" "nouveau fichier exécutable"
      fi
    fi
  done
  if [ ${#TEXT[@]} -eq 0 ]; then return 0; fi
  while IFS= read -r hit; do
    report grave "$hit" "caractère Unicode invisible ou bidirectionnel (instruction cachée ?)"
  done < <(cd "$TARGET" && perl -CSD -ne 'print "$ARGV:$.\n" if /[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{2066}-\x{2069}\x{E0000}-\x{E007F}]/; close ARGV if eof' -- "${TEXT[@]}" 2>/dev/null || true)
  domains="$(cd "$TARGET" && grep -EhoI 'https?://[A-Za-z0-9.-]+' -- "${TEXT[@]}" 2>/dev/null \
    | sed -E 's#^https?://##' | LC_ALL=C sort -u | paste -sd, - | sed 's/,/, /g' || true)"
  if [ -n "$domains" ]; then report note "domaines cités" "$domains"; fi
}

# Revue LLM : implémentée à la tâche 4.
llm_review() {
  return 0
}

CHANGED=()
TEXT=()
while IFS= read -r f; do CHANGED+=("$f"); done < <(changed_files)

if [ ${#CHANGED[@]} -eq 0 ]; then
  echo "audit  $NAME : aucun changement"
  exit 0
fi
echo "audit  $NAME : ${#CHANGED[@]} fichier(s) à analyser"

for f in "${CHANGED[@]}"; do
  if [ -s "$TARGET/$f" ] && ! grep -Iq '' "$TARGET/$f"; then
    report note "$f" "fichier binaire, non lu"
  else
    TEXT+=("$f")
  fi
done

static_patterns
structural_checks
llm_review

if [ "$GRAVE" -gt 0 ]; then
  echo "audit  $NAME : $GRAVE signalement(s) grave(s)"
  exit 1
fi
if [ "$LLM_ERROR" -eq 1 ]; then
  echo "audit  $NAME : analyse incomplète"
  exit 2
fi
echo "audit  $NAME : rien de grave"
