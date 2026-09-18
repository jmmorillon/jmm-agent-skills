# Fonctions partagées par install.sh et scripts/audit.sh. À sourcer.

# Refus mémorisés : « <type>:<nom> <empreinte> <AAAA-MM-JJ> », un par ligne.
REFUSED_FILE="${AUDIT_REFUSED_FILE:-$HOME/.agents/.audit-refused}"

# Liste les fichiers et symlinks de $1 (chemins relatifs, triés). Ignore les
# artefacts d'exécution : clone git, marqueurs du cache de plugins, bytecode.
# Seul endroit où cette liste d'exclusions est définie. $2 = --no-node-modules
# ajoute node_modules (à toute profondeur) à l'exclusion : pour les plugins
# uniquement, où Claude Code installe lui-même ce dossier dans le cache.
list_files() {
  local dir="$1" flag="${2:-}"
  local prune=(-name .git -o -name .in_use -o -name .orphaned_at \
      -o -name __pycache__ -o -name .DS_Store)
  if [ "$flag" = "--no-node-modules" ]; then
    prune+=(-o -name node_modules)
  fi
  (cd "$dir" && find . \( "${prune[@]}" \) -prune \
      -o \( -type f -o -type l \) -print) | sed 's#^\./##' | LC_ALL=C sort
}

# 0 si $1 et $2 contiennent les mêmes fichiers au même contenu. $3, transmis à
# list_files, voir ci-dessus.
trees_equal() {
  local a="$1" b="$2" flag="${3:-}"
  if [ ! -d "$a" ] || [ ! -d "$b" ]; then return 1; fi
  if [ "$(list_files "$a" "$flag")" != "$(list_files "$b" "$flag")" ]; then return 1; fi
  local f
  while IFS= read -r f; do
    if ! cmp -s "$a/$f" "$b/$f"; then return 1; fi
  done < <(list_files "$a" "$flag")
  return 0
}

# Empreinte du contenu de $1 : sha256 des chemins et contenus, 16 caractères.
content_hash() {
  if [ ! -d "$1" ]; then return 1; fi
  local f
  list_files "$1" | while IFS= read -r f; do
    printf '%s\n' "$f"
    shasum -a 256 < "$1/$f" 2>/dev/null || echo "illisible"
  done | shasum -a 256 | cut -c1-16
}

# Affiche la date du refus de <type>:<nom> pour cette empreinte ; 1 si aucun.
refused_since() {
  if [ ! -f "$REFUSED_FILE" ]; then return 1; fi
  awk -v k="$1:$2" -v h="$3" '$1 == k && $2 == h { print $3; found = 1 }
    END { exit !found }' "$REFUSED_FILE"
}

# Réécrit le fichier de refus sans les lignes visées : $1 = clé exacte
# (type:nom), ou, avec $2 = name, un nom quel que soit le type.
drop_refusals() {
  if [ ! -f "$REFUSED_FILE" ]; then return 0; fi
  local tmp
  tmp="$(mktemp)"
  awk -v v="$1" -v by="${2:-key}" '
    { n = $1; sub(/^[^:]*:/, "", n) }
    (by == "key" && $1 == v) || (by == "name" && n == v) { next }
    { print }' "$REFUSED_FILE" > "$tmp"
  mv "$tmp" "$REFUSED_FILE"
}

# Mémorise le refus de <type> <nom> <empreinte>, en remplaçant le précédent.
record_refusal() {
  mkdir -p "$(dirname "$REFUSED_FILE")"
  drop_refusals "$1:$2"
  printf '%s:%s %s %s\n' "$1" "$2" "$3" "$(date +%Y-%m-%d)" >> "$REFUSED_FILE"
}

# Oublie les refus de <nom>, skill comme plugin (ex. code-review existe sous
# les deux formes).
forget_refusal() {
  drop_refusals "$1" name
}
