# 02 Use Cases（ユースケース詳細）

本章では `docs/01_requirements.md` の **FR-01〜FR-07 / UC-01〜UC-07** に対応する、詳細ユースケース（入力・前提・手順・期待結果・例外）を定義する。

> 権限（A案）：更新系（UC-01〜UC-06）は原則 `admin` / `member` が実行者（actor）。`viewer` / `guest` は参照（UC-07）のみ。

---

## UC-01 新規登録（FR-01）

### 目的
購入した部品/機材を台帳に登録し、以後の配備・使用・貸出・修理・廃棄などの管理を可能にする。

### actor
- `admin` / `member`

### 入力（例）
- 基本情報：名称、型番、種類（カテゴリ）、機材区分（equipment_type：consumable/equipment/asset）
- 購入情報：発注日、納品日、販売元、価格
- （備品・資産のみ）学内/資金元番号：固定資産番号、備品番号、科研費管理番号など（複数可）

### 前提条件
- 部品番号（内部管理番号）はシステムが自動採番する（NOT NULL / UNIQUE、重複しない）
- 名称・機材区分（equipment_type）など必須項目が入力されている
- （参照マスタがある設計の場合）カテゴリ/プロジェクト/場所などの参照先が存在する

### 基本フロー
1. actor が基本情報・購入情報を入力する（部品番号は入力せず、システムが自動採番する）
2. システムは入力の必須項目・整合性（重複、日付、価格）を検証する
3. `equipment` に新規レコードを作成する（初期 `status` は原則 `in_stock`）
4. 購入情報を `purchase`（または `equipment` の購入関連列）に保存する
5. （備品・資産のみ）学内/資金元番号があれば `equipment_identifiers` 等に保存する
6. `equipment_events`（または履歴テーブル）に「登録」イベントを記録する（actor、日時、登録内容）

### 期待結果（成功）
- 台帳に1件追加され、初期 `status = in_stock`
- 登録イベントが履歴として残る

### 例外/エラー
- E1：一意制約（部品番号/識別子等）の衝突 → 登録拒否（再採番/入力見直し）
- E2：必須項目不足（名称、区分など）→ 登録拒否
- E3：`equipment_type=consumable` なのに識別番号を必須にしている等、設計ルール違反 → 登録拒否（または警告）

---

## UC-02 配備（設置・稼働開始）（FR-02）

### 目的
機材をプロジェクト・設置場所・責任者に紐付け、運用開始状態（`in_service`）にする。

### actor
- `admin` / `member`

### 入力（例）
- 対象機材（equipment_id / 部品番号）
- プロジェクト
- 設置場所
- 責任者（people）
- （任意）配備メモ

### 前提条件
- 対象機材が存在し、`status` が運用可能（例：`in_stock` / `assigned` / `in_service`）
- `discarded` / `returned_to_funder` は配備不可

### 基本フロー
1. actor が対象機材を検索して選択する
2. actor がプロジェクト・設置場所・責任者を設定する
3. 必要に応じて `status` を `in_service` に更新する
4. `equipment_events` に「配備/設置」イベントを記録する（actor、日時、project/location/manager、from_status/to_status）

### 期待結果（成功）
- 機材の現在情報（project/location/manager）が更新される
- 必要に応じて `status=in_service` になる
- 配備イベントが履歴として残る

### 例外/エラー
- E1：対象機材が `discarded` / `returned_to_funder` → 更新拒否
- E2：プロジェクトが存在しない（project 不存在）→ 更新拒否
- E3：参照先（場所/責任者）が存在しない → 更新拒否

---

## UC-03 使用者/責任者変更（FR-03）

### 目的
機材の責任者・使用者の変更を記録し、監査可能にする（例：A→B）。

### actor
- `admin` / `member`

### 入力（例）
- 対象機材
- 変更対象：責任者/使用者（または両方）
- 新しい責任者/使用者
- （任意）理由メモ

### 前提条件
- 対象機材が存在する
- `discarded` / `returned_to_funder` は変更不可

### 基本フロー（使用者変更の例：A→B）
1. actor が対象機材を選択する
2. 現在の使用者（A）を確認する
3. 使用者を B に更新する（必要に応じて `status` を `assigned` に更新）
4. `equipment_events` に「使用者変更」イベントを記録する（actor、from_user/to_user、from_status/to_status）

### 期待結果（成功）
- 現在の使用者/責任者が最新化される
- 変更の履歴（前後・実行者・日時）が残る

### 例外/エラー
- E1：`discarded` / `returned_to_funder` → 更新拒否
- E2：新しい使用者/責任者が存在しない（people未登録）→ 更新拒否
- E3：権限不足（viewer/guest）→ 実行拒否

---

## UC-04 貸出/返却（FR-04）

### 目的
機材の貸出と返却を管理し、二重貸出や追跡不能を防ぐ。

### actor
- `admin` / `member`

### 入力（貸出：例）
- 対象機材
- 貸出日
- 貸出先：学内メンバ（people）または外部先（guest）
- 担当者（actor）
- （任意）返却予定日、メモ

### 入力（返却：例）
- 対象機材
- 返却日
- 返却先：`in_stock` / `assigned` / `in_service` / `returned_to_funder` を決めるための情報
- （任意）返却メモ

### 前提条件
- 貸出：対象機材が運用可能（`in_stock` / `assigned` / `in_service` 等）である
- 貸出：既に `status=loaned` の機材は貸出不可（二重貸出防止）
- 返却：対象機材が `status=loaned` である

### 基本フロー（貸出）
1. actor が対象機材を選択する
2. 貸出情報（貸出日、貸出先、メモ等）を入力する
3. `status` を `loaned` に更新する
4. 貸出イベントを `equipment_events` に記録する（loan_to、actor、from_status/to_status）

### 基本フロー（返却）
1. actor が `loaned` の対象機材を選択する
2. 返却情報（返却日、返却先）を入力する
3. 返却先に応じて `status` を更新する（例：在庫へ戻す→`in_stock`、学内個人へ割当→`assigned`、設置へ戻す→`in_service`、資金元へ返却→`returned_to_funder`）
4. 返却イベントを `equipment_events` に記録する（return_to、actor、from_status/to_status）

### 期待結果（成功）
- 貸出時：`status=loaned` となり、貸出履歴・状態遷移履歴が残る
- 返却時：返却先に応じた `status` となり、返却履歴・状態遷移履歴が残る

### 例外/エラー
- E1：貸出対象が既に `loaned` → 貸出拒否
- E2：返却対象が `loaned` ではない → 返却拒否
- E3：`discarded` / `returned_to_funder` への不正操作 → 拒否

---

## UC-05 故障/修理（FR-05）

### 目的
故障〜修理の状態遷移を管理し、稼働可否と履歴を明確にする。

### actor
- `admin` / `member`

### 入力（例）
- 対象機材
- 故障日 / 修理開始日 / 修理完了日
- 内容（任意）
- 担当者（actor）
- 修理完了後の復旧先（`in_service` または `in_stock`）

### 前提条件
- `discarded` / `returned_to_funder` は故障/修理操作不可

### 基本フロー
1. 故障登録：`status` を `broken` に更新し、故障イベントを履歴に記録
2. 修理開始：`status` を `repairing` に更新し、修理開始イベントを履歴に記録
3. 修理完了：復旧先に応じて `status` を `in_service` または `in_stock` に更新し、修理完了イベントを履歴に記録

### 期待結果（成功）
- 故障/修理の各段階が `status` と履歴で追跡できる

### 例外/エラー
- E1：状態遷移が不正（例：`in_stock` からいきなり修理完了）→ 拒否（または警告）
- E2：権限不足（viewer/guest）→ 実行拒否

---

## UC-06 廃棄/資金元返却（FR-06）

### 目的
運用終了（廃棄）または資金元返却を管理し、以後の運用操作対象外とする。

### actor
- `admin` / `member`

### 入力（廃棄）
- 対象機材
- 廃棄日
- 理由
- 担当者（actor）

### 入力（資金元返却）
- 対象機材
- 返却日
- 返却先（資金元/提供元の識別）
- 担当者（actor）

### 前提条件
- 対象機材が存在する
- 既に `discarded` / `returned_to_funder` の機材は再操作不可

### 基本フロー（廃棄）
1. actor が対象機材を選択する
2. 廃棄情報を入力する
3. `status` を `discarded` に更新する
4. 廃棄イベントを履歴に記録する

### 基本フロー（資金元返却）
1. actor が対象機材を選択する
2. 返却情報を入力する
3. `status` を `returned_to_funder` に更新する
4. 資金元返却イベントを履歴に記録する

### 期待結果（成功）
- `status` が `discarded` または `returned_to_funder` となり、以後の運用操作（貸出/返却/変更/修理等）が原則不可
- 廃棄/返却の履歴・状態遷移履歴が残る

### 例外/エラー
- E1：`loaned` のまま廃棄/返却しようとする → 運用ルールにより拒否（または「返却処理を先に行う」）
- E2：権限不足（viewer/guest）→ 実行拒否

---

## UC-07 複合条件検索（FR-07）

### 目的
運用上の問い合わせに対し、条件を組み合わせて機材を検索・一覧化する。

### actor
- `admin` / `member` / `viewer` / `guest`

### 入力（条件例）
- 使用者、責任者
- 期間（購入日、貸出日、状態変化日など）
- プロジェクト、種類（カテゴリ）、設置場所
- 区分（消耗品/備品/資産）
- ステータス（`loaned` / `broken` / `repairing` / `returned_to_funder` など）

### 前提条件
- 参照権限がある（guest の参照範囲は運用で限定してよい）

### 基本フロー
1. actor が検索条件を指定する
2. システムは条件に一致する機材を一覧で返す
3. 必要に応じて、履歴（イベント）を参照して「期間内に状態変化があった」等の条件を評価する

### 期待結果（成功）
- 条件に一致する機材一覧が取得できる

### 例外/エラー
- E1：条件が不正（存在しないステータスなど）→ エラー

---

## 実装・検証への紐付け（ガイド）

- スキーマ：`sql/01_schema.sql`
- 初期データ：`sql/02_seed.sql`
- 基本操作：`sql/03_basic_operations.sql`
- トランザクション：`sql/04_transaction_cases.sql`
- 自由検索：`sql/05_free_queries.sql`

- テスト：`tests/01_constraints.sql` 〜 `tests/06_transaction_rollback.sql`
- 並行実行：`tests/07_concurrency_locking.md`

> 各UCの実行結果は `evidence/screenshots/` に保存し、最終レポート（docs）に貼り付ける。