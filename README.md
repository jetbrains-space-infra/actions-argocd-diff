# 🚀 Argo CD Diff GitHub Action

This GitHub Action runs `argocd app diff` for all applications in a specified Argo CD project and outputs a **Markdown-formatted summary**, useful for visibility in CI pipelines or PR checks.

You can use this action to detect configuration drift, review changes between git revisions, or simply preview what Argo CD would apply.

---

## 📦 Features

- 🔍 Runs `argocd app diff` on all apps in a project
- 🧾 Outputs Markdown report as an action output (`result`)
- 📁 Stores the report in a file (`argocd-diff-summary.XXXXXX.md`) and returns its name (`filename`)
- 🧰 Based on official `quay.io/argoproj/argocd` CLI image
- ⚙️ Supports version pinning for Argo CD CLI

---

## 📥 Inputs

| Name              | Description                                | Required | Default     |
|-------------------|--------------------------------------------|----------|-------------|
| `argocd-version`  | Argo CD CLI version                        | ❌       | `v3.0.12`   |
| `server`          | Argo CD server URL                         | ✅       | –           |
| `project`         | Argo CD project name                       | ✅       | –           |
| `token`           | Argo CD authentication token               | ✅       | –           |
| `revision`        | Git revision to diff against               | ✅       | –           |

---

## 📤 Outputs

| Name       | Description                               |
|------------|-------------------------------------------|
| `result`   | Markdown-formatted diff result            |
| `filename` | Name the generated `argocd-diff-summary.XXXXXX.md` file |

---

## 🚀 Usage

```yaml
jobs:
  argo-diff:
    runs-on: ubuntu-latest
    steps:
      - uses: jetbrains-space-infra/actions-argocd-diff@v1
        id: diff
        with:
          server: https://your-argocd.example.com
          project: my-argo-project
          token: ${{ secrets.ARGOCD_AUTH_TOKEN }}
          revision: ${{ github.head_ref }}

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

- The `token` must be a valid **Argo CD API token** (usually generated via `argocd account generate-token`).
- It must have access to:
    - `argocd app list`
    - `argocd app diff`
    - all applications in the specified `project`.
- If Argo CD has SSO enabled, ensure the token is from a bot or local user with appropriate permissions.

---

### 🛠️ Local Development & Debugging

To test locally with a specific version of Argo CD:

```bash
docker build --build-arg ARGOCD_VERSION=v3.0.12 -t argocd-diff-action .
docker run --rm \
  -e INPUT_SERVER=https://argocd.example.com \
  -e INPUT_PROJECT=my-project \
  -e INPUT_TOKEN=your-token \
  -e INPUT_REVISION=main \
  argocd-diff-action
```

You’ll get the rendered Markdown in argocd-diff-summary.XXXXXX.md inside the container.
