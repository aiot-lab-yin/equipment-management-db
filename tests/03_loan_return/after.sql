-- tests/03_loan_return/after.sql
-- 目的: 実行後状態の確認（スクショ用）
-- 実行方法:
--   1) action.sql を実行した同一セッションなら、そのまま実行（@eid/@run_id が残っている）
--   2) 別セッションなら、必要なら SET @run_id := '...'; を手で入れて検索してください

SET NAMES utf8mb4;

SELECT '========== TEST 03: LOAN / RETURN (AFTER) ==========' AS msg;

SELECT DATABASE() AS current_db;

-- A) 同一セッション：@eid で直接追跡
SELECT '--- equipment by @eid (if available) ---' AS msg;
SELECT @eid AS equipment_id_maybe;

SELECT * FROM equipment WHERE equipment_id=@eid;

SELECT '--- events for @eid (time order) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code,
       loan_to_id, return_to_id, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- B) 別セッション救済：LoanItem- を探す
SELECT '--- search latest Loan items (manual recovery) ---' AS msg;

SELECT equipment_id, name, status_code, project_id, location_id, manager_id, user_id
FROM equipment
WHERE name LIKE 'LoanItem-%'
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

-- D) 今回作った project を確認（project_no が P-LOAN- で始まる）
SELECT '--- projects created by this test (latest) ---' AS msg;

SELECT id, project_no, name, representative_id, status
FROM projects
WHERE project_no LIKE 'P-LOAN-%'
ORDER BY id DESC
LIMIT 10;