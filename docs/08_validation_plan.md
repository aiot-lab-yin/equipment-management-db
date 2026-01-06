

# 08 Validation Plan（検証計画）

本章は、部品/機材管理データベース（MySQL）について、要件（FR）・ユースケース（UC）・トランザクション設計（T）・SQL（tests/・sql/）に基づき、再現可能な検証手順と証跡（スクリーンショット）取得方法を定義する。

---

## 目次

- [1. 検証の目的と範囲](#1-検証の目的と範囲)
- [2. 前提条件](#2-前提条件)
- [3. 証跡（Evidence）方針](#3-証跡evidence方針)
- [4. 実行手順（共通）](#4-実行手順共通)
- [5. 検証観点一覧（FR/UC/T/SQL対応表）](#5-検証観点一覧fructsql対応表)
- [6. 必須検証（課題セット 1〜6）](#6-必須検証課題セット-16)
- [7. 追加検証（制約・負系・監査ログ）](#7-追加検証制約負系監査ログ)
- [8. 受入基準（Acceptance Criteria）](#8-受入基準acceptance-criteria)
- [9. 既知の制約・補足](#9-既知の制約補足)

---

## 1. 検証の目的と範囲

### 目的
- 要件定義（docs/01_requirements.md）に記載した主要機能（登録・配備・使用者/責任者変更・貸出/返却・故障/修理・廃棄/資金元返却・検索）が、DDL/制約/トリガおよびSQL実行で正しく実現できることを確認する。
- 監査ログ（equipment_events）が、INSERT/UPDATE操作に対して自動生成され、操作者（actor）とイベント種別（event_type）、状態遷移（from/to）が追跡可能であることを確認する。
- DB制約（終端状態の固定、最低限の状態遷移制約、貸出/返却先の必須）が機能し、誤操作をDB側で検知・拒否できることを確認する。

### 範囲
- DBスキーマ（sql/01_schema.sql）
- 初期データ（sql/02_seed.sql）
- 代表トランザクション（sql/04_transaction_cases.sql：T-00〜T-08）
- テストSQL（tests/ 配下：制約・CRUD・貸出/返却・廃棄・検索・ロールバック）
- 証跡（evidence/screenshots/）

---

## 2. 前提条件

- MySQL 8.x（Docker Compose）で実行する。
- DB名は実行環境で指定する（SQLファイル内に `USE sampledb;` は書かない方針）。
- `equipment` の INSERT/UPDATE に対し、トリガで `equipment_events` が自動生成される。
- トリガ要件：
  - INSERT/UPDATE の前に `@actor_id` と `@event_type` を設定する。
  - `@event_type='loan'` の場合は `@loan_to_id` が必須。
  - `@event_type='return'` の場合は `@return_to_id` が必須。
  - `discarded` / `returned_to_funder` は終端状態として以後の更新を禁止する（DB制約で強制）。

---

## 3. 証跡（Evidence）方針

- すべての必須検証について、実行前後の結果を確認できる証跡（スクリーンショット）を保存する。
- 保存先：`evidence/screenshots/`
- ファイル名規約（例）：
  - `V01_schema_tables.png`
  - `V02_seed_counts.png`
  - `V11_register_before_after.png`
  - `V21_loan_before_after.png`
  - `V31_change_user_before_after.png`
  - `V41_project_list.png`
  - `V51_discard_before_after.png`
  - `V61_free_search.png`
  - `V71_negative_missing_actor.png`
  - `V72_negative_double_loan.png`
  - `V73_negative_terminal_update.png`

---

## 4. 実行手順（共通）

### 4.1 MySQLへ接続

（例：studentユーザ）

```bash
docker compose exec db mysql -ustudent -pstudent
```

（外部からSQLを流し込む場合：TTYエラー回避のため `-T` を使う）

```bash
docker compose exec -T db mysql -ustudent -pstudent sampledb < sql/01_schema.sql
```

### 4.2 DBの初期化（推奨：毎回リセットして再現性を上げる）

1) スキーマ適用

```bash
docker compose exec -T db mysql -uroot -proot sampledb < sql/01_schema.sql
```

2) 初期データ投入

```bash
docker compose exec -T db mysql -uroot -proot sampledb < sql/02_seed.sql
```

3) 代表トランザクション（再現性重視版）

```bash
docker compose exec -T db mysql -uroot -proot sampledb < sql/04_transaction_cases.sql
```

### 4.3 最低限の動作確認（スキーマ/トリガ）

MySQLに入って以下を実行し、証跡を保存する。

```sql
SHOW TABLES;
SHOW TRIGGERS;
```

---

## 5. 検証観点一覧（FR/UC/T/SQL対応表）

| 観点 | 対応FR/UC | 参照トランザクション/SQL | 期待結果（概要） |
|---|---|---|---|
| 登録（購入→台帳登録） | FR-01 / UC-01 | T-00 / sql/04_transaction_cases.sql | purchases + equipment が作成され、eventsが自動生成される |
| 配備（project/location/manager設定） | FR-02 / UC-02 | T-01 | equipment更新 + events自動生成 |
| 使用者変更（A→B） | FR-03 / UC-03 | T-02 | user_id更新 + events自動生成 |
| 貸出（loan） | FR-04 / UC-04 | T-03 | status=loaned + loan_to_id必須 + eventsにloan_to_id保存 |
| 返却（return） | FR-04 / UC-04 | T-04 | status復帰 + return_to_id必須 + eventsにreturn_to_id保存 |
| 故障・修理 | FR-05 / UC-05 | T-05/T-06 | status遷移 + events自動生成 |
| 廃棄 | FR-06 / UC-06 | T-07 | status=discarded（終端）+ 以後更新不可 |
| 資金元返却 | FR-06 / UC-06 | T-08 | status=returned_to_funder（終端）+ 以後更新不可 |
| 複合検索 | FR-07 / UC-07 | sql/05_free_queries.sql / tests/05_search.sql | 条件検索が正しく動作 |
| 監査ログ | NFR（監査/追跡） | equipment_events | actor/event_type/from-toが追跡可能 |

---

## 6. 必須検証（課題セット 1〜6）

ここは「提出用チェックリスト」の必須検証に対応する。各課題は **Before/After** を示す。

### 課題1：部品/機材登録（Before/After）

- 対象：T-00（register_purchase）
- 手順：
  1. T-00 実行前に、対象の `equipment` が存在しない（または件数が増える前）ことを確認
  2. `sql/04_transaction_cases.sql` を実行し、T-00 で新規作成された `@eid_router/@eid_sa/@eid_battery` を確認
  3. `equipment_events` に登録イベントが自動で残ることを確認
- 確認SQL（例）：

```sql
SELECT COUNT(*) FROM equipment;
SELECT * FROM equipment ORDER BY equipment_id DESC LIMIT 10;
SELECT * FROM equipment_events ORDER BY event_timestamp DESC LIMIT 20;
```

- 証跡：`V11_register_before_after.png`

### 課題2：貸出前後（Before/After）

- 対象：T-03（loan）
- 手順：
  1. 対象機材の現在状態を確認（例：in_stock / in_service）
  2. loan 実行後、`status_code='loaned'` になっていること
  3. `equipment_events.loan_to_id` が NULL ではないこと（必須）

```sql
SELECT equipment_id, status_code FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;
```

- 証跡：`V21_loan_before_after.png`

### 課題3：使用者／責任者変更前後（Before/After）

- 対象：T-02（change_user）
- 手順：
  1. `equipment.user_id` の変更前を確認
  2. change_user 実行後に user_id が変化
  3. events に from/to user が残る

```sql
SELECT equipment_id, user_id, manager_id FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;
```

- 証跡：`V31_change_user_before_after.png`

### 課題4：特定プロジェクトの部品/機材一覧

- 対象：プロジェクト別一覧（FR-07）
- 手順：
  1. `project_id` を指定して equipment を抽出
  2. 必要に応じて type/status/location も併用

```sql
SELECT e.equipment_id, e.name, e.status_code, e.location_id, e.manager_id, e.user_id
FROM equipment e
WHERE e.project_id = @pid_main
ORDER BY e.equipment_id DESC;
```

- 証跡：`V41_project_list.png`

### 課題5：廃棄処理（Before/After）

- 対象：T-07（discard）
- 手順：
  1. 廃棄前の status を確認
  2. `discarded` に更新されること
  3. 廃棄後の追加UPDATEが拒否されること（終端固定）

```sql
SELECT equipment_id, status_code FROM equipment WHERE equipment_id = @eid_router;
SELECT * FROM equipment_events WHERE equipment_id = @eid_router ORDER BY event_timestamp DESC LIMIT 5;
```

- 証跡：
  - `V51_discard_before_after.png`
  - `V73_negative_terminal_update.png`（終端後更新拒否）

### 課題6：複合条件検索（自由）

- 対象：FR-07
- 例：プロジェクト + 状態 + 設置場所 + 期間（events）

```sql
-- 例：特定プロジェクトで loaned になった履歴がある機材を抽出（期間条件つき）
SELECT DISTINCT e.equipment_id, e.name
FROM equipment e
JOIN equipment_events ev ON ev.equipment_id = e.equipment_id
WHERE e.project_id = @pid_main
  AND ev.to_status_code = 'loaned'
  AND ev.event_timestamp >= (NOW() - INTERVAL 30 DAY)
ORDER BY e.equipment_id DESC;
```

- 証跡：`V61_free_search.png`

---

## 7. 追加検証（制約・負系・監査ログ）

### 7.1 負系：@actor_id 未設定

- 目的：操作者必須（監査）をDBが強制すること

```sql
SET @actor_id := NULL;
SET @event_type := 'deploy';
UPDATE equipment SET location_id = @loc_lab WHERE equipment_id = @eid_sa;
```

- 期待：エラー（Missing session variable: @actor_id）
- 証跡：`V71_negative_missing_actor.png`

### 7.2 負系：二重貸出の禁止

```sql
-- 既に loaned の状態で、再度 loan を試みる
SET @actor_id := @uid_member;
SET @event_type := 'loan';
SET @loan_to_id := @uid_viewer;
UPDATE equipment SET status_code = 'loaned' WHERE equipment_id = @eid_sa;
```

- 期待：エラー（Double-loan is not allowed）
- 証跡：`V72_negative_double_loan.png`

### 7.3 負系：貸出中の廃棄/資金元返却禁止

```sql
-- loaned のまま discard を試みる
SET @actor_id := @uid_admin;
SET @event_type := 'discard';
UPDATE equipment SET status_code = 'discarded' WHERE equipment_id = @eid_sa;
```

- 期待：エラー（Cannot discard/return_to_funder while loaned）

### 7.4 監査ログの整合

- 目的：events が from/to と actor/event_type を持ち、追跡可能であること

```sql
SELECT ev.*
FROM equipment_events ev
WHERE ev.equipment_id IN (@eid_router, @eid_sa, @eid_battery)
ORDER BY ev.equipment_id, ev.event_timestamp;
```

---

## 8. 受入基準（Acceptance Criteria）

- 必須検証（課題セット 1〜6）を実行し、すべて期待結果を満たす。
- `SHOW TABLES;` と `SHOW TRIGGERS;` でスキーマとトリガが確認できる。
- equipment の INSERT/UPDATE で `equipment_events` が自動生成され、`@actor_id/@event_type` が必須として機能する。
- loan/return において `loan_to_id/return_to_id` が events に保存される。
- 終端状態（discarded/returned_to_funder）になった機材は以後更新できない。
- 主要な負系（actor未設定、二重貸出、貸出中の廃棄/返却）がDBで拒否される。
- すべての証跡が `evidence/screenshots/` に揃っている。

---

## 9. 既知の制約・補足

- 本プロジェクトは「授業課題の解答例」として、DB内で監査ログ・最低限の制約を強めに実装している。
- 将来Web化する場合は、アプリ側で認証・認可（role）を担い、DB側は監査ログ・整合性・禁止遷移を担保する設計が有力。
- テストを何度でも再実行できるよう、`sql/04_transaction_cases.sql` は T-00 で毎回新しい機材を作成し、そのIDを後続トランザクションで使用する。