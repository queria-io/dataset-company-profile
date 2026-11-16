# ビルドと更新

データセットの概要は [README.md](README.md) にあります。ここにはこのリポジトリでデータセットをビルド・更新する手順を書きます。

## ビルド

```bash
uv sync
scripts/build.sh
```

`scripts/build.sh` は Queria の公開済みデータを pull し、dbt を実行して push します。
