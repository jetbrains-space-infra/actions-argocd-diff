# 🚀 Argo CD Diff GitHub Action

This GitHub Action scans your repository for Argo CD Application manifests and runs `argocd app diff` for each application it finds. It produces a concise, Markdown-formatted summary suitable for CI logs and PR checks, and also exposes the report as an artifact-friendly file.

Use it to detect configuration drift, preview what Argo CD would apply for the target revision declared in your manifests, and surface differences early in your pipeline.

---

## 📦 Features

- 🔍 Runs `argocd app diff` for every Argo CD Application manifest in your repo
- 🧾 Outputs a Markdown report as an action output (`result`)
- 📁 Saves the report to `argocd-diff-summary.XXXXXX.md` and returns its name via `filename`
- ⚙️ Supports extra flags for `argocd app diff` via `argocd_diff_flags` (e.g., `--grpc-web --refresh`)
- 🧭 Optionally diff only changed Application manifests against a base ref
- 🧰 Based on the official `quay.io/argoproj/argocd` CLI image
- 📌 Supports pinning the Argo CD CLI version

---

## 📥 Inputs

| Name               | Description                                                | Required | Default          |
|--------------------|------------------------------------------------------------|----------|------------------|
| `argocd-version`   | Argo CD CLI version to use (image tag)                     | ❌       | `v3.0.12`        |
| `server`           | Argo CD server address (e.g., `https://argocd.example.com`)| ✅       | –                |
| `token`            | Argo CD authentication token                               | ✅       | –                |
| `argocd_diff_flags`| Extra flags passed to `argocd app diff`                    | ❌       | `""`            |
| `app_glob`         | Glob to discover Application manifests                      | ❌       | `**/*.application.yaml` |
| `only_changed`     | If `true`, diff only manifests changed vs `base_ref`        | ❌       | `false`          |
| `base_ref`         | Git base ref used when `only_changed=true`                  | ❌       | `origin/main`    |

Notes:
- The action parses each Application manifest to determine:
  - `metadata.name` and optional `metadata.namespace` (forming `<namespace>/<name>`), and
  - `spec.source.targetRevision` (which is used as `--revision`).

---

## 📤 Outputs

| Name       | Description                                             |
|------------|---------------------------------------------------------|
| `result`   | Markdown-formatted diff summary                         |
| `filename` | The generated `argocd-diff-summary.XXXXXX.md` file name |

---

## 🚀 Usage

Typical usage in a workflow scanning the checked-out repository:

```yaml
jobs:
  argo-diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: jetbrains-space-infra/actions-argocd-diff@v1
        id: diff
        with:
          server: https://your-argocd.example.com
          token: ${{ secrets.ARGOCD_AUTH_TOKEN }}
          # Optional:
          # argocd_diff_flags: --grpc-web --refresh
          # only_changed: 'true'
          # base_ref: origin/main
          # app_glob: '**/*.application.yaml'

      - name: Show raw diff
        run: echo "${{ steps.diff.outputs.result }}"

      - name: Upload report as artifact
        uses: actions/upload-artifact@v4
        with:
          name: argocd-diff
          path: "${{ github.workspace }}/${{ steps.diff.outputs.filename }}"
```

---

### 🔐 Notes

- The `token` must be a valid **Argo CD API token** (e.g., generated via `argocd account generate-token`).
- It must have access to:
  - `argocd app list`
  - `argocd app diff`
  - the applications you reference in your manifests.
- If Argo CD uses SSO, ensure the token belongs to a user or bot with adequate permissions.

---

### 🛠️ Local Development & Debugging

To test locally with a specific Argo CD CLI version and your current repo:

```bash
# Build the action image
docker build --build-arg ARGOCD_VERSION=v3.0.12 -t argocd-diff-action .

# Run it against your local repo (mounted at /github/workspace)
docker run --rm \
  -v "$PWD":/github/workspace \
  -w /github/workspace \
  -e INPUT_SERVER=https://argocd.example.com \
  -e INPUT_TOKEN=your-token \
  -e INPUT_ARGOCD_DIFF_FLAGS="--grpc-web --refresh" \
  -e INPUT_ONLY_CHANGED=false \
  -e INPUT_BASE_REF=origin/main \
  -e INPUT_APP_GLOB='**/*.application.yaml' \
  argocd-diff-action
```

You’ll find the rendered Markdown printed in logs, and the file path inside the container as `argocd-diff-summary.XXXXXX.md` under `/github/workspace`.
