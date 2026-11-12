# 企業カルテ

法人番号を軸に、法人の基本情報・企業属性・上場情報・最新の売上高・人的資本の指標をまとめたデータセットです。補助金と国の落札は 1 件 1 行でも引けます。

## 出典と利用条件

Queria の公開データセットを読んで作ります。

| 原典 | 使うテーブル |
| --- | --- |
| 国税庁法人番号公表サイト | `houjin_bangou.main.mart_houjin_bangou`、`houjin_bangou.main.mart_houjin_bangou_history` |
| gBizINFO | `gbizinfo.main.mart_gbizinfo_company`、`gbizinfo.main.mart_gbizinfo_workplace`、`gbizinfo.main.mart_gbizinfo_subsidy` |
| EDINET | `edinet.main.mart_companies`、`edinet.main.mart_business_results`、`edinet.main.mart_human_capital` |
| 調達ポータル | `p_portal.main.procurement_award` |
| 女性の活躍推進企業データベース | `mhlw.josei_katsuyaku.company` |

元データの利用規約に従います。

## テーブル

| テーブル | 内容 |
| --- | --- |
| `profile.company` | 法人の基本情報・企業属性・上場情報・最新の売上高・人的資本。1 行が現存する 1 法人 |
| `profile.public_funds` | 法人が受け取った補助金と国の落札。1 行が 1 件 |
| `profile.city` | 市区町村ごとの法人数・上場企業・公的なお金・直近 1 年の新設と閉鎖。1 行が 1 市区町村 |

## 使い方

上場企業を平均年間給与の高い順に並べる:

```sql
SELECT corporate_number, name, city_name, market_segment,
       average_annual_salary, average_annual_salary_as_of
FROM company_profile.profile.company
WHERE is_listed
ORDER BY average_annual_salary DESC NULLS LAST;
```

法人が受け取った公的なお金を日付順に見る:

```sql
SELECT event_date, fund_type, title, amount, issuer,
       source_table, source_record_id
FROM company_profile.profile.public_funds
WHERE corporate_number = '法人番号13桁'
ORDER BY event_date DESC NULLS LAST;
```

市区町村ごとの企業数と公的なお金を比べる:

```sql
SELECT city_name, company_count, listed_company_count,
       listed_average_annual_salary_median,
       subsidy_total_amount, procurement_total_amount,
       new_company_count_last_year, closed_company_count_last_year
FROM company_profile.profile.city
WHERE prefecture_code = '13'
ORDER BY company_count DESC;
```

## 作り方と注意

- 母集団は `houjin_bangou.main.mart_houjin_bangou` にある現存法人です
- 市区町村コードは 5 桁、全国地方公共団体コードは検査数字付きの 6 桁です
- 平均年間給与は EDINET の提出会社単体の値です
- 女性管理職比率は出典の単位をそろえた百分率です
- 元テーブルに時点がない値は、対応する `*_as_of` が NULL です
- 補助金は gBizINFO、国の落札は調達ポータルから読みます。両方にある調達を重ねて数えないため、gBizINFO の調達テーブルは使いません
- Jグランツは補助金制度の公募情報で、受給法人・交付額・交付日を持たないため `public_funds` には使いません
- gBizINFO の補助金テーブルは原本 ID を持たないため、その行の `source_record_id` は NULL です
- 委託と研究費は、今回の入力元に受取法人・金額・日付を区分できるテーブルがないため収録していません
- 直近 1 年の新設は法人番号指定年月日、閉鎖は登記記録の閉鎖年月日で数えます。集計期間は `period_start` 以上 `period_end` 以下です

## ファイルの分け方

DuckLake のカタログを読まずに Parquet を直接読んで法人番号から 1 行を引けるよう、表は毎回まるごと作り直し、行グループを 2,048 行にしています。法人の表（`profile.company`）は法人番号の下 3 桁（`shard`）ごとのファイルに分け、ファイルの中は法人番号の順に並べています。

## ビルド

```bash
uv sync
scripts/build.sh
```

`scripts/build.sh` は Queria の公開済みデータを pull し、dbt を実行して push します。
