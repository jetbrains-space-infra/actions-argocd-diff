#!/bin/bash
set -euo pipefail

SERVER="${INPUT_SERVER}"
PROJECT="${INPUT_PROJECT}"
TOKEN="${INPUT_TOKEN}"
REVISION="${INPUT_REVISION}"

OUTPUT_FILE=$(mktemp /github/workspace/argocd-diff-summary.XXXXXX.md)
chmod 0644 "$OUTPUT_FILE"

echo "## 🔍 Argo CD Diff Report (project: \`$PROJECT\`)" >> "$OUTPUT_FILE"
echo '' >> "$OUTPUT_FILE"

echo "Fetching apps in project '${PROJECT}'..."
APPS=$(argocd app list \
  --project "$PROJECT" \
  --server "$SERVER" \
  --auth-token "$TOKEN" \
  --grpc-web \
  --output name)

for APP in $APPS; do
  DIFF_OUTPUT_FILE="$(mktemp)"
  if argocd app diff "$APP" \
      --server "$SERVER" \
      --revision "$REVISION" \
      --auth-token "$TOKEN" \
      --grpc-web \
      --refresh > "$DIFF_OUTPUT_FILE" 2>&1; then
    echo "✔️ No changes in $APP"
  else
    echo "🛠️ Changes found in $APP"
    echo "### 🔧 Diff for \`$APP\`" >> "$OUTPUT_FILE"
    echo '```diff' >> "$OUTPUT_FILE"
    cat "$DIFF_OUTPUT_FILE" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo '' >> "$OUTPUT_FILE"
  fi
done

# Prepare result output
RESULT=$(cat "$OUTPUT_FILE")
RESULT="${RESULT//'%'/'%25'}"
RESULT="${RESULT//$'\n'/'%0A'}"
RESULT="${RESULT//$'\r'/'%0D'}"

echo "filename=$(basename $OUTPUT_FILE)" >> "$GITHUB_OUTPUT"
echo "result=$RESULT" >> "$GITHUB_OUTPUT"
