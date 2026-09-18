#!/usr/bin/env bash
# Tests de scripts/lib.sh et scripts/audit.sh. Bash pur, sans dépendance.
# Les fixtures sont générées dans un dossier temporaire, jamais versionnées.
# Usage : tests/run.sh [--with-llm]
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUDIT="$ROOT/scripts/audit.sh"
WITH_LLM="no"
if [ "${1:-}" = "--with-llm" ]; then WITH_LLM="yes"; fi

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export AUDIT_REFUSED_FILE="$T/refused"
# shellcheck source=../scripts/lib.sh
. "$ROOT/scripts/lib.sh"

PASS=0
FAIL=0

# expect <code attendu> <motif attendu dans la sortie, ou ""> <description> -- <commande…>
expect() {
  local want="$1" pattern="$2" desc="$3"
  shift 4
  local out rc=0
  out="$("$@" 2>&1)" || rc=$?
  if [ "$rc" -eq "$want" ] && { [ -z "$pattern" ] || printf '%s' "$out" | grep -qF -- "$pattern"; }; then
    PASS=$((PASS + 1))
    echo "ok    $desc"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL  $desc (code $rc, attendu $want${pattern:+, motif « $pattern »})"
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
}

# mk <chemin relatif à $T> <contenu, échappements printf %b (octal \0nnn)>
mk() {
  mkdir -p "$(dirname "$T/$1")"
  printf '%b' "$2" > "$T/$1"
}

echo "== lib.sh"

mk clean/SKILL.md '---\nname: clean\ndescription: Une skill sans risque.\n---\n\nRésume le fichier ouvert.\n'
mk clean/logo.bin '\0000\0001\0002'
cp -R "$T/clean" "$T/clean-copy"
touch "$T/clean-copy/.in_use"
mkdir -p "$T/clean-copy/__pycache__" && touch "$T/clean-copy/__pycache__/x.pyc"
cp -R "$T/clean" "$T/clean-changed"
mk clean-changed/SKILL.md '---\nname: clean\n---\n\nAutre contenu.\n'

expect 0 "" "trees_equal ignore .in_use et __pycache__" -- trees_equal "$T/clean" "$T/clean-copy"
expect 1 "" "trees_equal voit un contenu modifié" -- trees_equal "$T/clean" "$T/clean-changed"
expect 1 "" "trees_equal échoue si un dossier manque" -- trees_equal "$T/clean" "$T/absent"
expect 0 "" "content_hash ignore les artefacts" -- test "$(content_hash "$T/clean")" = "$(content_hash "$T/clean-copy")"
expect 1 "" "content_hash change avec le contenu" -- test "$(content_hash "$T/clean")" = "$(content_hash "$T/clean-changed")"
expect 0 "" "content_hash fait 16 caractères" -- test "$(content_hash "$T/clean" | tr -d '\n' | wc -c | tr -d ' ')" = 16

record_refusal skill tdd aaaa
expect 0 "$(date +%Y-%m-%d)" "refused_since trouve un refus" -- refused_since skill tdd aaaa
expect 1 "" "refused_since : autre empreinte" -- refused_since skill tdd bbbb
expect 1 "" "refused_since : autre type" -- refused_since plugin tdd aaaa
record_refusal skill tdd cccc
expect 0 "" "record_refusal remplace la ligne de même clé" -- test "$(grep -c '^skill:tdd ' "$REFUSED_FILE")" = 1
record_refusal plugin tdd dddd
forget_refusal tdd
expect 1 "" "forget_refusal oublie le type skill" -- refused_since skill tdd cccc
expect 1 "" "forget_refusal oublie le type plugin" -- refused_since plugin tdd dddd

echo
echo "→ $PASS réussi(s), $FAIL échec(s)"
[ "$FAIL" -eq 0 ]
