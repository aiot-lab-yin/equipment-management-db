-- tests/05_return_to_funder/before.sql
-- 目的: 実行前状態の確認（スクショ用）
-- 実行方法: MySQL端末で USE <DB名>; のあと、この内容を貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== TEST 05: RETURN TO FUNDER (BEFORE) ==========' AS msg;

-- 0) 接続先DBの確認
SELECT DATABASE() AS current_db;

-- 1) baseline件数（seedが入っている前提）
SELECT '--- counts (baseline) ---' AS msg;
SELECT 'people' AS tbl, COUNT(*) AS cnt FROM people
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'equipment_events', COUNT(*) FROM equipment_events;

-- 2) admin の存在確認（return_to_funder は基本 admin が実行する想定）
SELECT '--- admin (for return_to_funder) ---' AS msg;
SELECT id AS admin_id, user_name, full_name
FROM people
WHERE role='admin'
ORDER BY id
LIMIT 3;

-- 3) equipmentのトリガ存在確認（UPDATEには @actor_id / @event_type が必須）
SELECT '--- triggers (equipment) ---' AS msg;
SHOW TRIGGERS LIKE 'equipment';

-- 4) 直近イベント（参考）
SELECT '--- latest events (top 10) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
ORDER BY event_timestamp DESC
LIMIT 10;