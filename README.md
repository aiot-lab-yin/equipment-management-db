# Equipment Management DB（機材・部品管理データベース）

購入・使用・貸出/返却・廃棄までの**機材ライフサイクル**を管理するための、データベース設計/実装/検証（テスト）用リポジトリです。

- 設計ドキュメント：`docs/`
- SQL 実装：`sql/`
- テスト：`tests/`
- スクリーンショット等の証跡：`evidence/`

---

## ディレクトリ構成

```text
.
├── README.md
├── docs/
│   ├── 00_overview.md
│   ├── 01_requirements.md
│   ├── 02_use_cases.md
│   ├── 03_er_diagram.md
│   ├── 04_logical_design.md
│   ├── 05_physical_design.md
│   ├── 06_transaction_design.md
│   ├── 07_query_design.md
│   ├── 08_validation_plan.md
│   └── 09_conclusion.md
├── sql/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_basic_operations.sql
│   ├── 04_transaction_cases.sql
│   └── 05_free_queries.sql
├── tests/
│   ├── 01_constraints.sql
│   ├── 02_basic_crud.sql
│   ├── 03_loan_return.sql
│   ├── 04_discard.sql
│   ├── 05_search.sql
│   ├── 06_transaction_rollback.sql
│   └── 07_concurrency_locking.md
└── evidence/
    └── screenshots/
```

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

- 制約テスト：`tests/01_constraints.sql`
- CRUD テスト：`tests/02_basic_crud.sql`
- 貸出/返却：`tests/03_loan_return.sql`
- 廃棄：`tests/04_discard.sql`
- 検索：`tests/05_search.sql`
- ROLLBACK：`tests/06_transaction_rollback.sql`

例（CLI）：

```bash
mysql -u <user> -p equipment_management_db < tests/01_constraints.sql
mysql -u <user> -p equipment_management_db < tests/02_basic_crud.sql
```

### 手動テスト（並行実行・ロック・デッドロック）

- 手順書：`tests/07_concurrency_locking.md`
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
  - `06_rollback_before.png`
  - `06_rollback_after.png`

---

## ドキュメント作成の流れ（推奨）

1. `docs/01_requirements.md`（需要分析）
2. `docs/03_er_diagram.md`（ER 図）
3. `sql/01_schema.sql`（DDL）
4. `sql/02_seed.sql`（初期データ）
5. 機能 SQL / テスト SQL を実行して証跡保存
6. `docs/08_validation_plan.md` と `docs/09_conclusion.md` を仕上げ

---

## ライセンス

授業課題用（必要に応じて追記）。
