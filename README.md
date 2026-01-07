# Equipment Management DB（機材・部品管理データベース）

購入・使用・貸出/返却・廃棄までの**機材ライフサイクル**を管理するための、データベース設計/実装/検証（テスト）用リポジトリです。

## 目次

- [目的と位置づけ](#目的と位置づけ)
- [将来計画（実運用）](#将来計画実運用)
- [ディレクトリ構成](#ディレクトリ構成)
- [前提（推奨環境）](#前提推奨環境)
- [セットアップ手順（最短）](#セットアップ手順最短)
  - [1) データベース作成](#1-データベース作成)
  - [2) スキーマ作成（CREATE TABLE）](#2-スキーマ作成create-table)
  - [3) 初期データ投入（INSERT）](#3-初期データ投入insert)
  - [（参考）Docker Compose を使用する場合](#参考docker-compose-を使用する場合)
- [機能SQLの実行](#機能sqlの実行)
- [テスト（検証）の実行](#テスト検証の実行)
- [証跡（スクリーンショット）](#証跡スクリーンショット)
- [ドキュメント作成の流れ（推奨）](#ドキュメント作成の流れ推奨)
- [Author](#author)
- [ライセンス](#ライセンス)

## 目的と位置づけ

本リポジトリは、**研究室の部品/機材管理システムのデータベース**として開発しています。
同時に、授業の「データベース総合課題」の**解答例（サンプル）**も兼ねています。

- 課題の要件・提出物の流れは `docs/00_overview.md` にまとめています。
- 本リポジトリは、著者の運用上の経験や判断（例：履歴の残し方、権限制御の考え方）も反映した“実運用寄り”の版です。
- **学生は、本リポジトリより簡潔な回答**（最小限のER/DDL/検証）でも課題として成立します。

## 将来計画（実運用）

将来的には、Web フロントエンドを用意し、研究室の部品管理として**実運用**できる形を目指します。
（例：検索画面、貸出/返却の操作画面、履歴閲覧、権限に応じた操作制限）

- 設計ドキュメント：`docs/`
- SQL 実装：`sql/`
- テスト：`tests/`
- スクリーンショット等の証跡：`evidence/`

---

## ディレクトリ構成

```text
.
├── README.md                  # 本リポジトリの概要・セットアップ・実行手順の説明
├── LICENSE                    # LICENSE
├── docs/                      # データベース設計に関する各種ドキュメント
│   ├── 00_overview.md         # 課題全体の概要・目的・要件一覧
│   ├── 01_requirements.md     # 要件定義（管理対象・必要機能の整理）
│   ├── 02_use_cases.md        # ユースケース定義（操作シナリオ）
│   ├── 03_er_diagram.md       # ER図（概念設計）の説明
│   ├── 04_logical_design.md   # 論理設計（正規化・テーブル構成）
│   ├── 05_physical_design.md  # 物理設計（型・制約・インデックス）
│   ├── 06_transaction_design.md # トランザクション設計
│   ├── 07_query_design.md     # クエリ設計・検索例
│   ├── 08_validation_plan.md  # 検証計画（テスト方針）
│   └── 09_conclusion.md       # まとめ・考察
├── sql/                       # 実行用SQLファイル
│   ├── 01_schema.sql          # テーブル定義（DDL）
│   ├── 02_seed.sql            # 初期データ投入
│   ├── 03_basic_operations.sql # 基本CRUD操作
│   ├── 04_transaction_cases.sql # トランザクション処理例
│   └── 05_free_queries.sql    # 自由課題・応用検索クエリ
├── tests/                     # 動作検証・テスト用SQL
│   ├── 01_constraints/        # 制約（NOT NULL・外部キー）検証
│   ├── 02_basic_crud/         # CRUD操作の検証
│   ├── 03_loan_return/        # 貸出・返却処理の検証
│   ├── 04_discard/            # 廃棄処理の検証
│   ├── 05_return_to_funder/   # 提供元返却処理の検証
│   ├── 06_free_queries/       # 自由課題・応用検索クエリの検証（テスト用）
│   ├── 07_transaction_rollback/ # ROLLBACK動作の検証
│   └── 08_concurrency_locking.md # 同時実行・ロック確認手順
└── evidence/
    └── screenshots/           # 実行結果（Before/After）の証跡スクリーンショット
```

### 各ディレクトリの説明

- **docs/**  
  要件定義・ER 図・論理設計・物理設計・トランザクション設計など、
  データベース設計に関するすべてのドキュメントを格納します。

- **sql/**  
  CREATE TABLE（DDL）、初期データ投入、基本操作、トランザクション例、
  自由課題用クエリなど、実行用 SQL を格納します。

- **tests/**  
  制約検証、CRUD、貸出/返却、廃棄、検索（自由課題/応用検索を含む）、ROLLBACK、
  並行実行・ロック確認などのテスト用 SQL／手順書を格納します。

- **evidence/**  
  実行結果の証跡（Before/After の SELECT 結果、エラー画面など）を保存します。

- **evidence/screenshots/**  
  提出・確認用のスクリーンショットを保存するためのディレクトリです。

---

## 前提（推奨環境）

- MySQL 8.x（または MariaDB 10.x）
- クライアント：`mysql` コマンド、または MySQL Workbench / DBeaver 等

> 授業で MySQL を使っている想定です。SQLite 等に置き換える場合は、DDL（AUTO_INCREMENT 等）を調整してください。

---

## セットアップ手順（最短）

### 1) データベース作成

```sql
CREATE DATABASE equipment_management_db DEFAULT CHARACTER SET utf8mb4;
```

### 2) スキーマ作成（CREATE TABLE）

- `sql/01_schema.sql` を実行

例（CLI）：

```bash
mysql -u <user> -p equipment_management_db < sql/01_schema.sql
```

### 3) 初期データ投入（INSERT）

- `sql/02_seed.sql` を実行

```bash
mysql -u <user> -p equipment_management_db < sql/02_seed.sql
```

### （参考）Docker Compose を使用する場合

Docker Compose で MySQL コンテナを起動している場合は、以下の手順でセットアップできます。

#### 1) 起動中のコンテナ名を確認

```bash
docker compose ps
```

例：

```text
NAME                         SERVICE   STATUS    PORTS
equipment-db-mysql-1         mysql     running   3306/tcp
```

以下では、コンテナ名を `equipment-db-mysql-1` と仮定します。

#### 2) コンテナ内の MySQL に接続

```bash
docker exec -it equipment-db-mysql-1 mysql -u root -p
```

#### 3) データベース作成

MySQL コンソール上で以下を実行します。

```sql
CREATE DATABASE equipment_management_db
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

#### 4) コンテナ外から SQL ファイルを実行

別のターミナルで、リポジトリのルートディレクトリから以下を実行します。

```bash
# スキーマ作成
docker exec -i equipment-db-mysql-1 \
  mysql -u root -p equipment_management_db < sql/01_schema.sql

# 初期データ投入
docker exec -i equipment-db-mysql-1 \
  mysql -u root -p equipment_management_db < sql/02_seed.sql
```

---

## 機能SQLの実行

- 基本操作：`sql/03_basic_operations.sql`
- トランザクション例：`sql/04_transaction_cases.sql`
- 自由検索：`sql/05_free_queries.sql`

例（CLI）：

```bash
mysql -u <user> -p equipment_management_db < sql/03_basic_operations.sql
```

> 実行前後の状態確認（Before/After）は `SELECT` の結果をスクリーンショットで `evidence/screenshots/` に保存します。

---

## テスト（検証）の実行

### 自動で流せるテスト（SQL）

以下は SQL だけで実行できるテストです。

- 制約テスト：`tests/01_constraints/before.sql` / `action.sql` / `after.sql`
- CRUD テスト：`tests/02_basic_crud/before.sql` / `action.sql` / `after.sql`
- 貸出/返却：`tests/03_loan_return/before.sql` / `action.sql` / `after.sql`
- 廃棄：`tests/04_discard/before.sql` / `action.sql` / `after.sql`
- 提供元へ返却：`tests/05_return_to_funder/before.sql` / `action.sql` / `after.sql`
- ROLLBACK：`tests/07_transaction_rollback/before.sql` / `action.sql` / `after.sql`

例（CLI）：

```bash
# 例: TEST 02 (before -> action -> after)
mysql -u <user> -p equipment_management_db < tests/02_basic_crud/before.sql
mysql -u <user> -p equipment_management_db < tests/02_basic_crud/action.sql
mysql -u <user> -p equipment_management_db < tests/02_basic_crud/after.sql

# 例: TEST 07 (before -> action -> after)
mysql -u <user> -p equipment_management_db < tests/07_transaction_rollback/before.sql
mysql -u <user> -p equipment_management_db < tests/07_transaction_rollback/action.sql
mysql -u <user> -p equipment_management_db < tests/07_transaction_rollback/after.sql
```

- 手順書：`tests/08_concurrency_locking.md`
- 2つのセッション（A/B）で同時実行し、
  - ロック待ち
  - 分離レベルの挙動
  - デッドロック発生と対処
  などを確認します。

---

## 証跡（スクリーンショット）

- すべて `evidence/screenshots/` に保存
- 推奨命名例：
  - `01_insert_before.png`
  - `01_insert_after.png`
  - `02_loan_before.png`
  - `02_loan_after.png`
  - `07_rollback_before.png`
  - `07_rollback_after.png`

---

## ドキュメント作成の流れ（推奨）

1. `docs/00_overview.md` を確認（課題の要件・機能要件・検証課題セット）
2. `docs/01_requirements.md`（需要分析）を作成（まず overview を元に整理）
3. `docs/02_use_cases.md`（ユースケース詳細）を作成  
   - overview に記載した **機能要件** と **検証課題セット** に合わせて作成する
4. `docs/04_logical_design.md`（論理設計：1NF→2NF→参照テーブル化3NF）
5. `docs/05_physical_design.md`（物理設計：MySQL 前提の制約・インデックス・トリガ方針）
6. `docs/03_er_diagram.md`（ER 図）を更新（論理設計の結果を反映）
7. `docs/06_transaction_design.md`（トランザクション設計）を作成 
   - 省略してもよい
8. `docs/07_query_design.md`（クエリ設計）を作成
   - 省略してもよい
9. `sql/01_schema.sql`（DDL）を実装
10. `sql/02_seed.sql`（初期データ）を投入
11. 機能 SQL / テスト SQL を実行して証跡保存（`evidence/screenshots/`）
12. `docs/08_validation_plan.md`（検証計画）と `docs/09_conclusion.md`（まとめ）を仕上げ

---

## Author

- Name: Yin　Chen
- Affiliation: Reitaku University
- Role: Student / Maintainer

## ライセンス

本リポジトリは **MIT License** の下で公開します。

- 商用利用可
- 改変・再配布可
- 保証なし（AS IS）

> 授業課題として作成していますが、将来の商用利用も可能なライセンスを採用しています。
