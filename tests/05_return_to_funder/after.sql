-- tests/05_return_to_funder/after.sql
-- 目的: 実行後状態の確認（スクショ用）
-- NOTE: action.sql を実行した同一セッションなら @eid 等が残っている。
--       もし別セッションで after を実行する場合は、@run_id を手で入れて検索してください。
-- 例: SET @run_id := '20260107000306';

SET NAMES utf8mb4;

SELECT '========== TEST 05: RETURN TO FUNDER (AFTER) ==========' AS msg;

SELECT DATABASE() AS current_db;

-- A) 同一セッション：@eid で直接追跡
SELECT '--- equipment by @eid (if available) ---' AS msg;
SELECT @eid AS equipment_id_maybe;

SELECT * FROM equipment WHERE equipment_id=@eid;

SELECT '--- events for @eid (time order) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- B) 別セッション救済：FunderItem- を探す
SELECT '--- search latest Funder items (manual recovery) ---' AS msg;
SELECT equipment_id, name, status_code, project_id, location_id, manager_id, user_id
FROM equipment
WHERE name LIKE 'FunderItem-%'
ORDER BY equipment_id DESC
LIMIT 10;

-- C) 集計（証跡）
SELECT '--- counts (after) ---' AS msg;
SELECT 'equipment' AS tbl, COUNT(*) AS cnt FROM equipment
UNION ALL
SELECT 'equipment_events', COUNT(*) FROM equipment_events;

SELECT '--- latest events (top 10) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
ORDER BY event_timestamp DESC
LIMIT 10;

-- D) 今回作った project を確認（project_no が P-FUNDER- で始まる）
SELECT '--- projects created by this test (latest) ---' AS msg;
SELECT id, project_no, name, representative_id, status
FROM projects
WHERE project_no LIKE 'P-FUNDER-%'
ORDER BY id DESC
LIMIT 10;