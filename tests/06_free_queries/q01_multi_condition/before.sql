-- 目的: 検索用の代表IDを「ある範囲で」自動決定（無ければ最新にフォールバック）
-- 実行方法: MySQL端末で USE <DB名>; のあと貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== FREE Q01: MULTI-CONDITION (BEFORE) ==========' AS msg;
SELECT DATABASE() AS current_db;

-- project: short_name='MAIN' があればそれ、なければ最新
SET @pid_main := (
  SELECT id FROM projects
  WHERE short_name='MAIN'
  ORDER BY id DESC LIMIT 1
);
SET @pid_main := COALESCE(@pid_main, (SELECT id FROM projects ORDER BY id DESC LIMIT 1));

-- location: 倉庫っぽいの / 研究室っぽいの（無ければ最新）
SET @loc_store := (
  SELECT id FROM locations
  WHERE name IN ('倉庫','ストレージ','保管庫')
  ORDER BY id DESC LIMIT 1
);
SET @loc_lab := (
  SELECT id FROM locations
  WHERE name IN ('研究室','ラボ')
  ORDER BY id DESC LIMIT 1
);
SET @loc_store := COALESCE(@loc_store, (SELECT id FROM locations ORDER BY id DESC LIMIT 1));
SET @loc_lab   := COALESCE(@loc_lab,   (SELECT id FROM locations ORDER BY id DESC LIMIT 1));

-- ここが「今回の検索条件」：必要なら手で変えてOK
SET @q_project_id := @pid_main;      -- NULLにすると project 条件なし
SET @q_status     := 'in_stock';     -- NULLにすると status 条件なし
SET @q_location   := @loc_store;     -- NULLにすると location 条件なし

SELECT '--- resolved params ---' AS msg;
SELECT
  @q_project_id AS q_project_id,
  @q_status     AS q_status,
  @q_location   AS q_location;

SELECT '--- equipment total ---' AS msg;
SELECT COUNT(*) AS equipment_total FROM equipment;