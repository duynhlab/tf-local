# Policy checks

Custom [Checkov](https://www.checkov.io/) rules live in `checkov/`. CI loads them via [`.checkov.yml`](../.checkov.yml) (`external-checks-dir`).

Add a Python module per rule (subclass `BaseResourceCheck`, id prefix `CKV_TF_LOCAL_`). CI enforces Checkov + Trivy + TFLint (see [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)).
