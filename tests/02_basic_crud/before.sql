-- tests/02_basic_crud/before.sql
-- 目的: 実行前状態の確認（スクショ用）
SET NAMES utf8mb4;

SELECT '========== TEST 02: BASIC CRUD (BEFORE) ==========' AS msg;

-- 0) 接続先DBの確認（MySQL端末で USE <DB名>; 済みの前提）
SELECT DATABASE() AS current_db;

-- 1) 参照データの存在確認（seedが入っていること）
SELECT '--- counts (seed baseline) ---' AS msg;
SELECT 'people' AS tbl, COUNT(*) AS cnt FROM people
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'vendors', COUNT(*) FROM vendors
UNION ALL SELECT 'purchases', COUNT(*) FROM purchases
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'equipment_events', COUNT(*) FROM equipment_events;

-- 2) テストで使うユーザーIDの取得（存在することが前提）
SELECT '--- actors ---' AS msg;
SELECT id AS admin_id, user_name, full_name FROM people WHERE role='admin' ORDER BY id LIMIT 3;
SELECT id AS member_id, user_name, full_name FROM people WHERE role='member' ORDER BY id LIMIT 3;

-- 3) トリガ存在確認（INSERT/UPDATEでeventsが残る設計）
SELECT '--- triggers (equipment) ---' AS msg;
SHOW TRIGGERS LIKE 'equipment';

-- 4) 直近のイベント（参考）
SELECT '--- latest events (top 10) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
ORDER BY event_timestamp DESC
LIMIT 10;