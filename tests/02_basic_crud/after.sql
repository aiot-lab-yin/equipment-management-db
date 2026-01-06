-- tests/02_basic_crud/after.sql
-- 目的: 実行後状態の確認（スクショ用）
-- NOTE: action.sql を実行した同一セッションなら @eid 等が残っている。
--       もし別セッションで after を実行する場合は、@run_id を手で入れて検索してください。

SET NAMES utf8mb4;

SELECT '========== TEST 02: BASIC CRUD (AFTER) ==========' AS msg;

SELECT DATABASE() AS current_db;

-- A) action直後（同一セッション）なら、そのまま @eid で確認
SELECT '--- equipment by @eid (if available) ---' AS msg;
SELECT @eid AS equipment_id_maybe;

SELECT * FROM equipment WHERE equipment_id=@eid;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, from_user_id, to_user_id, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- B) 別セッションで実行している場合（手動検索用）
--    直近に作られた CRUDItem を探して追跡する（必要なら LIMIT を増やす）
SELECT '--- search latest CRUD items (manual recovery) ---' AS msg;
SELECT equipment_id, name, status_code, project_id, location_id, manager_id, user_id
FROM equipment
WHERE name LIKE 'CRUDItem-%'
ORDER BY equipment_id DESC
LIMIT 10;

-- C) 集計（証跡）
SELECT '--- counts (after) ---' AS msg;
SELECT 'equipment' AS tbl, COUNT(*) AS cnt FROM equipment
UNION ALL SELECT 'equipment_events', COUNT(*) FROM equipment_events;

SELECT '--- latest events (top 10) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
ORDER BY event_timestamp DESC
LIMIT 10;

-- D) （任意）今回作った project を探す（project_no が P-CRUD- で始まる）
SELECT '--- projects created by this test (latest) ---' AS msg;
SELECT id, project_no, name, representative_id, status
FROM projects
WHERE project_no LIKE 'P-CRUD-%'
ORDER BY id DESC
LIMIT 10;