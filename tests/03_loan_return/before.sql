-- tests/03_loan_return/before.sql
-- 目的: 実行前状態の確認（スクショ用）
-- 実行方法: MySQL端末で USE <DB名>; のあと、この内容を貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== TEST 03: LOAN / RETURN (BEFORE) ==========' AS msg;

-- 0) 接続先DBの確認
SELECT DATABASE() AS current_db;

-- 1) seedが入っていること（最低限の件数確認）
SELECT '--- counts (baseline) ---' AS msg;

SELECT 'people' AS tbl, COUNT(*) AS cnt FROM people
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'equipment_events', COUNT(*) FROM equipment_events;

-- 2) テストで使うユーザーIDの存在確認（admin/member/viewer）
SELECT '--- actors ---' AS msg;

SELECT id AS admin_id, user_name, full_name
FROM people
WHERE role='admin'
ORDER BY id
LIMIT 3;

SELECT id AS member_id, user_name, full_name
FROM people
WHERE role='member'
ORDER BY id
LIMIT 3;

SELECT id AS viewer_id, user_name, full_name
FROM people
WHERE role='viewer'
ORDER BY id
LIMIT 3;

-- 3) equipmentのトリガ存在確認（loan/returnで@loan_to_id/@return_to_idが必要）
SELECT '--- triggers (equipment) ---' AS msg;
SHOW TRIGGERS LIKE 'equipment';

-- 4) 直近イベント（参考）
SELECT '--- latest events (top 10) ---' AS msg;

SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
ORDER BY event_timestamp DESC
LIMIT 10;