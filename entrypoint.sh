#!/usr/bin/env bash
set -euo pipefail

# ==== Inputs (from GitHub Action) ====
SERVER="${INPUT_SERVER}"
TOKEN="${INPUT_TOKEN}"
ARGOCD_DIFF_FLAGS="${INPUT_ARGOCD_DIFF_FLAGS}"

# ==== Repo scanning options ====
APP_GLOB="${INPUT_APP_GLOB}"
ONLY_CHANGED="${INPUT_ONLY_CHANGED}"
BASE_REF="${INPUT_BASE_REF}"

# ==== Output report ====
OUTPUT_FILE="$(mktemp /github/workspace/argocd-diff-summary.XXXXXX.md)"
chmod 0644 "$OUTPUT_FILE"

echo "## 🔍 Argo CD Diff Report" >> "$OUTPUT_FILE"
echo '' >> "$OUTPUT_FILE"

log()  { printf "\n\033[1;36m%s\033[0m\n" "-- $*"; }
warn() { printf "\n\033[1;33m%s\033[0m\n" "!! $*" >&2; }
hr()   { printf "\n\033[2m%s\033[0m\n" "----------------------------------------"; }

collect_files() {
  if [[ "${ONLY_CHANGED}" == "true" ]]; then
    git fetch --quiet || true
    git diff --name-only "${BASE_REF}" -- ${APP_GLOB} 2>/dev/null | grep -E '\.application\.ya?ml$' || true
  else
    find . -type f \( -name "*.application.yaml" -o -name "*.application.yml" \)
  fi
}

diff_one() {
  local file="$1"
  local tmp; tmp="$(mktemp)"

  local name namespace rev
  name="$(yq -r '.metadata.name // ""' "$file")"
  namespace="$(yq -r '.metadata.namespace // ""' "$file")"
  rev="$(yq -r '.spec.source.targetRevision // ""' "$file")"

  if [[ -z "$name" || -z "$rev" ]]; then
    warn "Skipping $file: missing name or targetRevision"
    return 0
  fi

  local app_ref="$name"
  [[ -n "$namespace" ]] && app_ref="${namespace}/${name}"

  log "Diff: $app_ref (revision: $rev)"
  set +e
  # shellcheck disable=SC2086
  argocd app diff "$app_ref" \
    --server "$SERVER" \
    --auth-token "$TOKEN" \
    --revision "$rev" \
    $ARGOCD_DIFF_FLAGS \
    >"$tmp" 2>&1
  rc=$?
  set -e

  case "$rc" in
    0)
      echo "✔️ No changes in $app_ref"
      ;;
    1)
      echo "🛠️ Changes found in $app_ref"
      {
        echo "### 🔧 Diff for \`$app_ref\`"
        echo ''
        echo '```diff'
        cat "$tmp"
        echo '```'
        echo ''
      } >> "$OUTPUT_FILE"
      ;;
    *)
      echo "⚠️ Error diffing $app_ref (exit $rc)"
      {
        echo "### ⚠️ Error for \`$app_ref\` (exit $rc)"
        echo ''
        echo '```text'
        cat "$tmp"
        echo '```'
        echo ''
      } >> "$OUTPUT_FILE"
      ;;
  esac

  rm -f "$tmp"
  return 0
}

main() {
  local files=()
  while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < <(collect_files)

  if ((${#files[@]} == 0)); then
    warn "No Application manifests found (APP_GLOB=${APP_GLOB})."
    echo "_No Application manifests found (APP_GLOB=\`${APP_GLOB}\`)._" >> "$OUTPUT_FILE"
  else
    log "Found ${#files[@]} Application manifest(s)"
    for f in "${files[@]}"; do
      diff_one "$f"
    done
  fi

  # Prepare GitHub output
  RESULT="$(cat "$OUTPUT_FILE")"
  RESULT="${RESULT//'%'/'%25'}"
  RESULT="${RESULT//$'\n'/'%0A'}"
  RESULT="${RESULT//$'\r'/'%0D'}"

  echo "filename=$(basename "$OUTPUT_FILE")" >> "$GITHUB_OUTPUT"
  echo "result=$RESULT" >> "$GITHUB_OUTPUT"
}

main "$@"
