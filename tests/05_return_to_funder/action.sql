-- tests/05_return_to_funder/action.sql
-- 目的: 返却（研究費提供元へ返す）= returned_to_funder の代表例を実行し、eventsが残ることを確認する
-- 実行方法: MySQL端末に貼り付けて上から順に実行（途中エラーが出たらスクショ）
-- 注意:
--   - equipment INSERT/UPDATE はトリガにより @actor_id / @event_type が必須
--   - status_code='returned_to_funder' にする場合、@event_type は 'return_to_funder' でなければならない

SET NAMES utf8mb4;

SELECT '========== TEST 05: RETURN TO FUNDER (ACTION) ==========' AS msg;

-- 実行識別子（重複回避）
SET @run_id := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');
SELECT CONCAT('RUN_ID=', @run_id) AS run_id;

-- 1) admin を取得
SELECT id INTO @uid_admin
FROM people
WHERE role='admin'
ORDER BY id
LIMIT 1;

SELECT CONCAT('admin_id=', @uid_admin) AS actor;

-- 2) location を作成（このテスト専用）
INSERT INTO locations(name, address)
VALUES (CONCAT('FunderLab-', @run_id), 'Campus');

SET @loc := LAST_INSERT_ID();
SELECT CONCAT('OK: location_id=', @loc) AS msg;

-- 3) project を作成（project_no は UNIQUE）
INSERT INTO projects(
  project_no, name, short_name, programe_name, funder,
  start_date, end_date, representative_id, status
) VALUES (
  CONCAT('P-FUNDER-', @run_id),
  CONCAT('ReturnToFunder Project ', @run_id),
  'RF', 'Prog', 'Funder',
  CURDATE(), CURDATE(), @uid_admin, 'ongoing'
);

SET @pid := LAST_INSERT_ID();
SELECT CONCAT('OK: project_id=', @pid) AS msg;

-- 4) equipment を登録（in_service からスタートして「提供元へ返却」にする）
--    ※ purchase_id は NULL でもOK
SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(
  name, model, quantity, unit, equipment_type_code, status_code,
  purchase_id, project_id, location_id, manager_id, user_id
) VALUES (
  CONCAT('FunderItem-', @run_id), 'F1', 1, 'pcs', 'asset', 'in_service',
  NULL, @pid, @loc, @uid_admin, NULL
);

SET @eid := LAST_INSERT_ID();
SELECT CONCAT('OK: equipment_id=', @eid) AS msg;

-- 5) return_to_funder（提供元へ返す）: status_code=returned_to_funder
--    ※ トリガ要件: @event_type は 'return_to_funder' 必須
SET @actor_id := @uid_admin;
SET @event_type := 'return_to_funder';

UPDATE equipment
SET status_code='returned_to_funder'
WHERE equipment_id=@eid;

SELECT 'OK: return_to_funder update' AS msg;

-- 6) 結果確認（equipment と events）
SELECT '--- equipment (final) ---' AS msg;
SELECT * FROM equipment WHERE equipment_id=@eid;

SELECT '--- equipment_events (time order) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- 7) after 用にIDを表示（同一セッションなら after でそのまま使える）
SELECT '--- IDs for AFTER ---' AS msg;
SELECT @run_id AS run_id, @pid AS project_id, @loc AS location_id, @eid AS equipment_id;