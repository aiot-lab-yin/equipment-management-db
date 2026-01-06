-- tests/07_transaction_rollback/after.sql
-- 目的: 実行後状態の確認（スクショ用）
-- NOTE:
--   - action.sql と同一セッションなら @eid / @run_id が残っています。
--   - 別セッションの場合は、下の例のように @run_id を手で入れて検索してください。
--     例: SET @run_id := '20260107010101';

SET NAMES utf8mb4;

SELECT '========== TEST 07: TRANSACTION ROLLBACK (AFTER) ==========' AS msg;

SELECT DATABASE() AS current_db;

-- A) 同一セッション：@eid で直接追跡
SELECT '--- equipment by @eid (if available) ---' AS msg;
SELECT @eid AS equipment_id_maybe;

SELECT equipment_id, name, status_code, project_id, location_id, manager_id, user_id
FROM equipment
WHERE equipment_id=@eid;

SELECT '--- events for @eid (time order) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, loan_to_id, return_to_id, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- B) 別セッション救済：RollbackItem- を探す（@run_id が分かるなら絞れる）
SELECT '--- search latest Rollback items (manual recovery) ---' AS msg;

SELECT equipment_id, name, status_code, project_id, location_id, manager_id, user_id
FROM equipment
WHERE name LIKE 'RollbackItem-%'
ORDER BY equipment_id DESC
LIMIT 10;

-- C) 集計（証跡）
SELECT '--- counts (after) ---' AS msg;
SELECT 'equipment' AS tbl, COUNT(*) AS cnt FROM equipment
UNION ALL
SELECT 'equipment_events', COUNT(*) FROM equipment_events;

-- D) 今回作った project を確認（project_no が P-RB- で始まる）
SELECT '--- projects created by this test (latest) ---' AS msg;

SELECT id, project_no, name, representative_id, status
FROM projects
WHERE project_no LIKE 'P-RB-%'
ORDER BY id DESC
LIMIT 10;

-- ★このテストで期待するポイント（初心者向けチェック）
--   - equipment.status_code は loaned になっていない（in_stock のまま等）
--   - equipment_events に loan / discard が増えていない（register のみ等）