# dataset-company-profile

Queria のデータセット `company_profile`（企業カルテ）のリポジトリです。データセットの説明は [docs/index.md](docs/index.md) にあります。

## ビルド

```bash
uv sync
scripts/build.sh
```

`scripts/build.sh` は Queria の公開済みデータを pull し、dbt を実行して push します。
