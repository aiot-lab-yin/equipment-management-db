-- tests/02_basic_crud/action.sql
-- 目的: CRUDの代表例（INSERT -> UPDATE(配備) -> UPDATE(割当)）を実行し、eventsも確認する
-- 実行方法: MySQL端末に貼り付けて順に実行（途中エラーが出たらスクショ）

SET NAMES utf8mb4;

SELECT '========== TEST 02: BASIC CRUD (ACTION) ==========' AS msg;

-- 実行識別子（重複回避のため、project_no等に付ける）
SET @run_id := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');
SELECT CONCAT('RUN_ID=', @run_id) AS run_id;

-- 1) actor（admin/member）を取得
SELECT id INTO @uid_admin FROM people WHERE role='admin' ORDER BY id LIMIT 1;
SELECT id INTO @uid_member FROM people WHERE role='member' ORDER BY id LIMIT 1;

SELECT CONCAT('admin_id=', @uid_admin, ', member_id=', @uid_member) AS actors;

-- 2) location を作成
INSERT INTO locations(name, address)
VALUES (CONCAT('CRUDLab-', @run_id), 'Campus');
SET @loc := LAST_INSERT_ID();
SELECT CONCAT('OK: location_id=', @loc) AS msg;

-- 3) vendor を作成
INSERT INTO vendors(name, contact_name, phone, email, address)
VALUES (CONCAT('CRUDVendor-', @run_id), 'Hanako', '111', CONCAT('crud-', @run_id, '@test'), 'Tokyo');
SET @vid := LAST_INSERT_ID();
SELECT CONCAT('OK: vendor_id=', @vid) AS msg;

-- 4) purchase を作成
INSERT INTO purchases(vendor_id, order_date, delivery_date, purchase_date, price, note)
VALUES (@vid, CURDATE(), CURDATE(), CURDATE(), 5000, CONCAT('T02 CRUD purchase run=', @run_id));
SET @pid_purchase := LAST_INSERT_ID();
SELECT CONCAT('OK: purchase_id=', @pid_purchase) AS msg;

-- 5) project を作成（project_noは UNIQUE なので run_id を付けて重複回避）
INSERT INTO projects(project_no, name, short_name, programe_name, funder, start_date, end_date, representative_id, status)
VALUES (CONCAT('P-CRUD-', @run_id), CONCAT('CRUD Project ', @run_id), 'CR', 'Prog', 'Funder',
        CURDATE(), CURDATE(), @uid_admin, 'ongoing');
SET @pid := LAST_INSERT_ID();
SELECT CONCAT('OK: project_id=', @pid) AS msg;

-- 6) equipment INSERT（トリガにより @actor_id / @event_type が必要）
SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(
  name, model, quantity, unit, equipment_type_code, status_code,
  purchase_id, project_id, location_id, manager_id, user_id
)
VALUES (
  CONCAT('CRUDItem-', @run_id), 'X1', 1, 'pcs', 'asset', 'in_stock',
  @pid_purchase, @pid, @loc, @uid_admin, NULL
);
SET @eid := LAST_INSERT_ID();
SELECT CONCAT('OK: equipment_id=', @eid) AS msg;

-- 7) deploy（状態を in_service へ）
SET @actor_id := @uid_admin;
SET @event_type := 'deploy';
UPDATE equipment SET status_code='in_service' WHERE equipment_id=@eid;
SELECT 'OK: deploy update' AS msg;

-- 8) assign（状態を assigned + user_id を member に）
SET @actor_id := @uid_admin;
SET @event_type := 'assign';
UPDATE equipment SET status_code='assigned', user_id=@uid_member WHERE equipment_id=@eid;
SELECT 'OK: assign update' AS msg;

-- 9) 結果確認（equipment と events）
SELECT '--- equipment (final) ---' AS msg;
SELECT * FROM equipment WHERE equipment_id=@eid;

SELECT '--- equipment_events (time order) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, from_user_id, to_user_id, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- 10) 参照用に、今回作ったIDを表示（afterで使う）
SELECT '--- IDs for AFTER ---' AS msg;
SELECT @run_id AS run_id, @loc AS location_id, @vid AS vendor_id, @pid_purchase AS purchase_id, @pid AS project_id, @eid AS equipment_id;