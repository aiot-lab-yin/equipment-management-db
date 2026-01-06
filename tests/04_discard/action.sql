-- tests/04_discard/action.sql
-- 目的: 廃棄(discard) の代表例を実行し、eventsが残ることを確認する
-- 実行方法: MySQL端末に貼り付けて上から順に実行（途中エラーが出たらスクショ）
-- 注意:
--   - equipment INSERT/UPDATE はトリガにより @actor_id / @event_type が必須
--   - discarded は terminal 状態なので、discard 後の更新は禁止（※このテストでは触らない）

SET NAMES utf8mb4;

SELECT '========== TEST 04: DISCARD (ACTION) ==========' AS msg;

-- 実行識別子（重複回避）
SET @run_id := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');
SELECT CONCAT('RUN_ID=', @run_id) AS run_id;

-- 1) admin を取得
SELECT id INTO @uid_admin FROM people WHERE role='admin' ORDER BY id LIMIT 1;
SELECT CONCAT('admin_id=', @uid_admin) AS actor;

-- 2) location を作成（このテスト専用）
INSERT INTO locations(name, address)
VALUES (CONCAT('DiscardLab-', @run_id), 'Campus');
SET @loc := LAST_INSERT_ID();
SELECT CONCAT('OK: location_id=', @loc) AS msg;

-- 3) project を作成（project_noは UNIQUE）
INSERT INTO projects(project_no, name, short_name, programe_name, funder, start_date, end_date, representative_id, status)
VALUES (
  CONCAT('P-DISC-', @run_id),
  CONCAT('Discard Project ', @run_id),
  'DS', 'Prog', 'Funder',
  CURDATE(), CURDATE(), @uid_admin, 'ongoing'
);
SET @pid := LAST_INSERT_ID();
SELECT CONCAT('OK: project_id=', @pid) AS msg;

-- 4) equipment を登録（in_stock）
--    トリガのため @actor_id / @event_type が必要
SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(
  name, model, quantity, unit, equipment_type_code, status_code,
  purchase_id, project_id, location_id, manager_id, user_id
)
VALUES (
  CONCAT('DiscardItem-', @run_id), 'D1', 1, 'pcs', 'asset', 'in_stock',
  NULL, @pid, @loc, @uid_admin, NULL
);

SET @eid := LAST_INSERT_ID();
SELECT CONCAT('OK: equipment_id=', @eid) AS msg;

-- 5) discard（廃棄）: status_code=discarded（@event_type は discard 必須）
SET @actor_id := @uid_admin;
SET @event_type := 'discard';

UPDATE equipment
SET status_code='discarded'
WHERE equipment_id=@eid;

SELECT 'OK: discard update' AS msg;

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