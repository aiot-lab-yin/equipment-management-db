# 05 Physical Design（物理設計）

## 1. 目的
本ドキュメントでは、`docs/04_logical_design.md` の論理設計をもとに、**MySQL（InnoDB）** で実装するための
データ型・制約（PK/FK/UNIQUE/NOT NULL）・インデックス・参照整合性の方針を確定する。

---

## 2. 想定DBMSと基本設定
- DBMS：MySQL 8.x
- ストレージエンジン：InnoDB
- 文字コード：utf8mb4
- 照合順序：utf8mb4_0900_ai_ci（環境のデフォルトに合わせても可）
- 日時：履歴は `DATETIME` を基本（`event_timestamp`）

---

## 3. 命名規則
- テーブル名：snake_case（例：`equipment_events`）
- 主キー：`id` または業務ID（例：`equipment_id`）
- 参照コード：`*_code`（例：`status_code`）
- 外部キー制約名：`fk_<child>_<parent>`
- インデックス名：`idx_<table>_<columns>`

---

## 4. 主キー設計（採番）

### 4.1 サロゲートキー（数値ID）
- `equipment.equipment_id`
- `people.id`
- `projects.id`
- `locations.id`
- `vendors.id`
- `purchases.id`
- `equipment_events.id`

は、`BIGINT UNSIGNED AUTO_INCREMENT` を推奨。

理由：
- 参照・結合が高速
- 手入力による重複を防止
- 将来の件数増加にも耐える

### 4.2 参照テーブル（reference）のキー
- `equipment_type_reference.code`
- `equipment_status_reference.code`

は、`VARCHAR(32)` をPK。

### 4.3 1:0..1 の識別子テーブル
- `equipment_identifiers.equipment_id` は **PK兼FK**（`equipment` への参照）

---

## 5. データ型方針

### 5.1 文字列
- `code`：`VARCHAR(32)`（英小文字＋アンダースコアを想定）
- `name` / `short_name` / `contact_name`：`VARCHAR(255)`
- `user_name`：`VARCHAR(64)`（運用でID相当）
- `email`：`VARCHAR(255)`
- `phone` / `mobile`：`VARCHAR(32)`（国番号・ハイフンを許容）
- `address`：`VARCHAR(255)`（より長い場合はTEXTへ）
- `description` / `note`：`TEXT`

### 5.2 日付・日時
- `start_date` / `end_date` / `order_date` / `delivery_date` / `purchase_date`：`DATE`
- `equipment_events.event_timestamp`：`DATETIME NOT NULL`

### 5.3 数値
- `quantity`：`INT UNSIGNED NOT NULL DEFAULT 1`
- `price`：`DECIMAL(12,2)`（通貨の丸め誤差を避ける）

### 5.4 真偽
- `equipment_status_reference.is_usable` / `is_terminal`：`TINYINT(1) NOT NULL`

---

## 6. NULL可否（要点）

### 6.1 equipment
- `name`：NOT NULL
- `quantity`：NOT NULL
- `unit`：NOT NULL
- `purchase_id`：購入不明を許容するなら NULL 可
- `project_id`：NOT NULL
- `location_id`：NOT NULL
- `manager_id`：NOT NULL
- `user_id`：NULL 可（未割当を許容）
- `equipment_type_code` / `status_code`：NOT NULL（reference を参照）

### 6.2 equipment_events
- `equipment_id`：NOT NULL
- `actor_id`：NOT NULL
- `event_type`：NOT NULL
- `event_timestamp`：NOT NULL
- `from_status_code` / `to_status_code`：NOT NULL
- `from_manager_id` / `to_manager_id`：NOT NULL
- `from_user_id` / `to_user_id`：NULL 可（equipment 側が NULL の場合を許容）
- `loan_to_id` / `return_to_id`：イベント種別に応じて NULL 可

> 本設計では、`equipment` の UPDATE を起点に `equipment_events` を自動生成する（11.2参照）。

---

## 7. 参照テーブル（reference tables）

### 7.1 equipment_type_reference
- `code`（PK）：`consumable` / `equipment` / `asset`
- `name`：表示名（例：消耗品、備品、資産）
- `description`：説明

### 7.2 equipment_status_reference
- `code`（PK）：
  - `in_stock`, `in_service`, `assigned`, `loaned`, `broken`, `repairing`, `returned_to_funder`, `discarded`
- `name`：表示名
- `description`：説明
- `is_usable`：利用可能か
- `is_terminal`：終端状態か（`discarded` / `returned_to_funder` は 1）

> `equipment.status_code` と `equipment_events.from_status_code/to_status_code` は、必ずこの参照テーブルの `code` を参照する。

---

## 8. 外部キー（FK）と参照整合性

- `equipment.status_code` → `equipment_status_reference.code`
- `equipment.equipment_type_code` → `equipment_type_reference.code`
- `equipment.project_id` → `projects.id`
- `equipment.location_id` → `locations.id`
- `equipment.manager_id` / `equipment.user_id` → `people.id`
- `purchases.vendor_id` → `vendors.id`
- `equipment.purchase_id` → `purchases.id`
- `equipment_identifiers.equipment_id` → `equipment.equipment_id`
- `equipment_events.equipment_id` → `equipment.equipment_id`
- `equipment_events.from_status_code` / `to_status_code` → `equipment_status_reference.code`
- `equipment_events.actor_id` / `from_user_id` / `to_user_id` / `loan_to_id` / `return_to_id` → `people.id`
- `equipment_events.from_manager_id` / `to_manager_id` → `people.id`

### 8.2 ON DELETE / ON UPDATE 方針
- reference tables（status/type）：
  - ON UPDATE CASCADE（コード変更は原則しないが安全策）
  - ON DELETE RESTRICT（参照中は削除不可）
- people / projects / locations / vendors：
  - 履歴保持のため ON DELETE RESTRICT を基本
  - 削除ではなく、運用上の無効化（status/terminated等）を推奨
- purchases：
  - 参照がある場合は削除禁止（RESTRICT）

---

## 9. ユニーク制約（UNIQUE）

- `people.user_name`：運用で一意にするなら UNIQUE
- `people.email`：運用で重複を避けるなら UNIQUE
- `projects.project_no`：運用で一意にするなら UNIQUE
- `equipment_identifiers.university_id` / `funding_id`：番号が一意である前提なら UNIQUE

---

## 10. インデックス設計（検索要件ベース）

### 10.1 equipment
- `idx_equipment_status`：(`status_code`)
- `idx_equipment_type`：(`equipment_type_code`)
- `idx_equipment_project`：(`project_id`)
- `idx_equipment_location`：(`location_id`)
- `idx_equipment_manager`：(`manager_id`)
- `idx_equipment_user`：(`user_id`)

### 10.2 equipment_events
- `idx_events_equipment_time`：(`equipment_id`, `event_timestamp`)
- `idx_events_actor_time`：(`actor_id`, `event_timestamp`)
- `idx_events_to_status_time`：(`to_status_code`, `event_timestamp`)

### 10.3 purchases
- `idx_purchases_vendor`：(`vendor_id`)
- `idx_purchases_purchase_date`：(`purchase_date`)

---

## 11. CHECK制約と運用ルール
MySQL 8.0.16 以降は CHECK 制約が有効だが、環境差分を考慮し、
重要ルールは **FK/NOT NULL/UNIQUE** で担保し、CHECKは補助として扱う。

例：
- `quantity >= 1`
- `price >= 0`

状態遷移の妥当性（例：`discarded` は戻れない等）は、
- トリガ
- ストアド
- アプリ層
のいずれかで実装できる。本課題では **SQLテスト（tests/）** で検証する。

### 11.2 equipment_events 整合性ルールの担保（トリガ方式）

`equipment_events` は監査・履歴のためのテーブルであり、手動INSERTよりも、
**`equipment` の状態更新（UPDATE）を起点に自動生成**する方が、利用者の操作として分かりやすい。

この方式では、操作者（actor）やイベント種別（event_type）が UPDATE 文だけでは渡せないため、
MySQL の **セッション変数**を必須化して、トリガで強制する。

#### 方針（方式A：セッション変数必須）
- `equipment` を更新する前に、必ず次を設定する：
  - `SET @actor_id = <people.id>;`
  - `SET @event_type = '<event_type>';`
- `@actor_id` / `@event_type` が未設定（NULL）の UPDATE は、トリガで拒否する。

#### トリガ構成
- **BEFORE UPDATE（検証）**：
  - `@actor_id` / `@event_type` の存在をチェックし、NULLなら `SIGNAL SQLSTATE '45000'` で UPDATE を拒否
- **AFTER UPDATE（履歴生成）**：
  - `OLD` と `NEW` の差分（status/user/manager等）を使って `equipment_events` を INSERT
  - `actor_id = @actor_id`, `event_type = @event_type`, `event_timestamp = NOW()`

#### 例（運用手順のイメージ）
```sql
SET @actor_id = 1;
SET @event_type = 'loan';
UPDATE equipment
SET status_code = 'loaned', user_id = 100
WHERE equipment_id = 10;
```

#### 注意点
- セッション変数は接続（セッション）単位で保持されるため、運用では
  - 1操作ごとに必ず `@actor_id/@event_type` を設定する
  - 必要に応じて操作後に `SET @actor_id = NULL; SET @event_type = NULL;` でクリアする
- `equipment_events` への直接INSERTは混乱のもとになるため、
  - 権限で禁止する
  - または運用ルールとして「eventsへ直接INSERTしない」と明記する

#### 実装ファイル
- トリガDDLは `sql/01_schema.sql`（スキーマの一部）に含める。
- 検証は `tests/` で、
  - `@actor_id/@event_type` 未設定の UPDATE が失敗すること
  - 正常UPDATEで `equipment_events` が自動生成されること
  を確認し、`evidence/` に証跡を残す。

---

## 12. 実装ファイルとの対応
- DDL：`sql/01_schema.sql`
- 初期データ：`sql/02_seed.sql`（reference tables の初期投入を含む）
- 検証：`tests/` と `evidence/`

---

## 13. 決定事項まとめ
- MySQL（InnoDB）で実装
- `equipment_id` は AUTO_INCREMENT の数値ID
- `equipment_type_reference` / `equipment_status_reference` を参照テーブルとして導入
- 履歴テーブル `equipment_events` も状態コード参照で統一
- 主要検索条件にインデックスを付与

## 14. テーブル仕様（データディクショナリ）

本節は、DDL（`sql/01_schema.sql`）実装時のブレ防止と、レビュー/採点向けの根拠資料として、各テーブルの物理仕様を整理する。

---

### 14.1 equipment（機器）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| equipment_id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| name | VARCHAR(255) | NO |  |  | 名称 |
| model | VARCHAR(255) | NO |  |  | 型番（本課題では必須） |
| quantity | INT UNSIGNED | NO |  |  | DEFAULT 1 |
| unit | VARCHAR(32) | NO |  |  | 台/個/箱/本/セット等 |
| equipment_type_code | VARCHAR(32) | NO |  | equipment_type_reference.code | 区分コード |
| status_code | VARCHAR(32) | NO |  | equipment_status_reference.code | 状態コード |
| purchase_id | BIGINT UNSIGNED | YES |  | purchases.id | 購入不明を許容 |
| project_id | BIGINT UNSIGNED | NO |  | projects.id | 必須 |
| location_id | BIGINT UNSIGNED | NO |  | locations.id | 必須 |
| manager_id | BIGINT UNSIGNED | NO |  | people.id | 必須 |
| user_id | BIGINT UNSIGNED | YES |  | people.id | 未割当を許容 |

> NOTE：本課題では `project_id/location_id/manager_id` は必須、`user_id` は NULL 可で統一する。

---

### 14.2 people（人）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| user_name | VARCHAR(64) | NO |  |  | UNIQUE（運用で一意） |
| full_name | VARCHAR(255) | NO |  |  | 氏名 |
| email | VARCHAR(255) | NO |  |  | UNIQUE推奨 |
| mobile | VARCHAR(32) | NO |  |  |  |
| affiliation | VARCHAR(255) | NO |  |  | 所属 |
| position | VARCHAR(255) | NO |  |  | 職位 |
| role | VARCHAR(32) | NO |  |  | admin/member/viewer/guest |

---

### 14.3 projects（プロジェクト）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| project_no | VARCHAR(64) | NO |  |  | UNIQUE推奨 |
| name | VARCHAR(255) | NO |  |  | 名称 |
| short_name | VARCHAR(64) | NO |  |  | 略称 |
| programe_name | VARCHAR(255) | NO |  |  | 事業名 |
| funder | VARCHAR(255) | NO |  |  | 資金元 |
| start_date | DATE | NO |  |  |  |
| end_date | DATE | NO |  |  |  |
| representative_id | BIGINT UNSIGNED | NO |  | people.id | 代表 |
| status | VARCHAR(32) | NO |  |  | ongoing/terminated |

---

### 14.4 locations（設置場所）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| name | VARCHAR(255) | NO |  |  | 場所名 |
| address | VARCHAR(255) | NO |  |  | 住所/補足（本課題では必須） |

---

### 14.5 vendors（ベンダー）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| name | VARCHAR(255) | NO |  |  | 名称 |
| contact_name | VARCHAR(255) | NO |  |  | 担当者名 |
| phone | VARCHAR(32) | NO |  |  | 電話 |
| email | VARCHAR(255) | NO |  |  | メール |
| address | VARCHAR(255) | NO |  |  | 住所 |

---

### 14.6 purchases（購入）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| vendor_id | BIGINT UNSIGNED | NO |  | vendors.id |  |
| order_date | DATE | NO |  |  | 本課題では必須 |
| delivery_date | DATE | NO |  |  | 本課題では必須 |
| purchase_date | DATE | NO |  |  | 本課題では必須 |
| price | DECIMAL(12,2) | NO |  |  | 価格 |
| note | TEXT | NO |  |  | 備考（本課題では必須） |

---

### 14.7 equipment_identifiers（機器識別子）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| equipment_id | BIGINT UNSIGNED | NO | PK | equipment.equipment_id | PK兼FK（1:0..1） |
| university_id | VARCHAR(64) | NO |  |  | 学内管理番号 |
| funding_id | VARCHAR(64) | NO |  |  | 資金元管理番号 |

---

### 14.8 equipment_events（機器イベント履歴）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| id | BIGINT UNSIGNED | NO | PK |  | AUTO_INCREMENT |
| equipment_id | BIGINT UNSIGNED | NO |  | equipment.equipment_id | 対象機器 |
| event_type | VARCHAR(64) | NO |  |  | イベント種別 |
| from_status_code | VARCHAR(32) | NO |  | equipment_status_reference.code | 遷移前状態 |
| to_status_code | VARCHAR(32) | NO |  | equipment_status_reference.code | 遷移後状態 |
| from_user_id | BIGINT UNSIGNED | YES |  | people.id | equipment.user_id と一致が必要 |
| to_user_id | BIGINT UNSIGNED | YES |  | people.id |  |
| from_manager_id | BIGINT UNSIGNED | NO |  | people.id | equipment.manager_id と一致が必要 |
| to_manager_id | BIGINT UNSIGNED | NO |  | people.id |  |
| loan_to_id | BIGINT UNSIGNED | YES |  | people.id | 貸出時のみ |
| return_to_id | BIGINT UNSIGNED | YES |  | people.id | 返却時のみ |
| actor_id | BIGINT UNSIGNED | NO |  | people.id | 実行者 |
| event_timestamp | DATETIME | NO |  |  | 実行日時 |

> 重要：本設計では `equipment` 更新時にトリガで履歴を自動生成するため、`from_*` は `OLD` から一貫して生成され、表記ゆれや不一致を防げる。

---

### 14.9 equipment_type_reference（機器区分参照）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| code | VARCHAR(32) | NO | PK |  | consumable/equipment/asset |
| name | VARCHAR(255) | NO |  |  | NOT NULL（要求） |
| description | TEXT | YES |  |  |  |

---

### 14.10 equipment_status_reference（機器状態参照）

| カラム名 | データ型（例） | NULL | PK | FK | 備考 |
|---|---|---:|:--:|---|---|
| code | VARCHAR(32) | NO | PK |  | in_stock 等 |
| name | VARCHAR(255) | NO |  |  | NOT NULL（要求） |
| description | TEXT | YES |  |  |  |
| is_usable | TINYINT(1) | NO |  |  | 0/1 |
| is_terminal | TINYINT(1) | NO |  |  | 0/1 |




