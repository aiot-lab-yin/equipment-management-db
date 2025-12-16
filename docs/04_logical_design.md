

# 04 Logical Design（論理設計）

## 1. 目的
本ドキュメントでは、`docs/03_er_diagram.md` で確定した概念設計（ER図）をもとに、
リレーショナルデータベースとして実装可能な形へ落とし込むための**論理設計**を行う。

本章では、正規化の第一段階である **第一正規形（1NF）** を確認・整理する。

---

## 2. 正規化の方針

### 2.1 対象テーブル
概念設計で定義した以下のテーブルを対象とする。

- equipment
- people
- projects
- locations
- vendors
- purchases
- equipment_identifiers
- equipment_events

### 2.2 第一正規形（1NF）の定義
第一正規形（1NF）とは、以下を満たす状態を指す。

- 各列は **原子値**（1セルに1値）のみを保持する
- 繰り返し項目（配列・リスト・可変長属性）を持たない
- 各行は主キーによって一意に識別できる

---

## 3. 第一正規形（1NF）の確認

### 3.1 1NFチェック観点
- 複数の値を1列に格納しない（例：メールアドレスを `a@x, b@y` のように保存しない）
- `xxx1`, `xxx2` のような列の繰り返しを作らない
- 意味の異なる情報を1列に混在させない

---

### 3.2 テーブル別 1NF 確認

#### equipment（機器）
- **主キー**：`equipment_id`
- 確認内容：
  - `name`（名称）、`model`（型番）、`quantity`（数量）、`unit`（量詞）は原子値 → OK
  - `equipment_type`、`status` は単一値（列挙型） → OK
  - `project_id`、`location_id`、`manager_id`、`user_id` は単一参照 → OK
- 備考：
  - 消耗品は「箱」「ロット」単位で管理し、数量×量詞で表現する

#### people（人）
- **主キー**：`id`
- 確認内容：
  - `user_name`、`full_name`、`email`、`mobile`、`affiliation`、`position`、`role` はすべて原子値 → OK
- 備考：
  - 将来、複数メール・複数電話番号を管理する場合は別テーブル化を検討する

#### projects（プロジェクト）
- **主キー**：`id`
- 確認内容：
  - `project_no`、`name`、`short_name`、`programe_name`、`funder` は原子値 → OK
  - `start_date`、`end_date` は単一日付 → OK
  - `representative_id` は単一参照 → OK
  - `status` は単一状態値（`ongoing` / `terminated`） → OK

#### locations（設置場所）
- **主キー**：`id`
- 確認内容：
  - `name`、`address` は原子値 → OK
- 備考：
  - 建物・階・部屋単位での検索が必要になった場合は分割を検討する

#### vendors（ベンダー）
- **主キー**：`id`
- 確認内容：
  - `name`、`contact_name`、`phone`、`email`、`address` は原子値 → OK

#### purchases（購入）
- **主キー**：`id`
- 確認内容：
  - `vendor_id` は単一参照 → OK
  - `order_date`、`delivery_date`、`purchase_date`、`price`、`note` は原子値 → OK
- 備考：
  - 1つの purchase に複数の equipment が紐づく設計とする

#### equipment_identifiers（機器識別子）
- **主キー**：`equipment_id`
- 確認内容：
  - `university_id`、`funding_id` はそれぞれ単一値 → OK
- 備考：
  - 識別子種別が増える場合は、別テーブルで多対1構造にする

#### equipment_events（機器イベント履歴）
- **主キー**：`id`
- 確認内容：
  - 状態・参照・日時はいずれも単一値 → OK
  - NULL を許容する列があっても 1NF 違反にはならない

---

## 4. 第一正規形の結論
本システムの論理設計は、すべてのテーブルにおいて

- 原子値のみを保持し
- 繰り返し項目を持たず
- 主キーにより行が一意に識別できる

ため、**第一正規形（1NF）を満たしている**と結論づける。

---

## 5. 次のステップ
次章では、

- 第二正規形（2NF）：部分関数従属性の排除
- 第三正規形（3NF）：推移的従属性の排除

を検討し、DDL（CREATE TABLE）設計へと進める。