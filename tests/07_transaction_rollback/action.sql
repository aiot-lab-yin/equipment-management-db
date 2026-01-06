-- tests/07_transaction_rollback/action.sql
-- 目的:
--   1) まず equipment を1件作る（これは残る）
--   2) その後、トランザクション内で loan を実行（本来は成功）
--   3) 続けて「loaned のまま discard」を実行してわざとエラーにする（triggerで禁止）
--   4) ROLLBACK して、loan の変更と loan event が残らないことを確認する
--
-- 実行方法: MySQL端末に貼り付けて上から順に実行（途中エラーは想定内・スクショOK）

SET NAMES utf8mb4;

SELECT '========== TEST 07: TRANSACTION ROLLBACK (ACTION) ==========' AS msg;

-- 実行識別子（重複回避）
SET @run_id := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');
SELECT CONCAT('RUN_ID=', @run_id) AS run_id;

-- 1) actor を取得
SELECT id INTO @uid_admin  FROM people WHERE role='admin'  ORDER BY id LIMIT 1;
SELECT id INTO @uid_member FROM people WHERE role='member' ORDER BY id LIMIT 1;
SELECT CONCAT('admin_id=', @uid_admin, ', member_id=', @uid_member) AS actors;

-- 2) location / project を作成（このテスト専用）
INSERT INTO locations(name, address)
VALUES (CONCAT('RbLab-', @run_id), 'Campus');
SET @loc := LAST_INSERT_ID();
SELECT CONCAT('OK: location_id=', @loc) AS msg;

INSERT INTO projects(project_no, name, short_name, programe_name, funder, start_date, end_date, representative_id, status)
VALUES (CONCAT('P-RB-', @run_id), CONCAT('Rollback Project ', @run_id), 'RB', 'Prog', 'Funder',
        CURDATE(), CURDATE(), @uid_admin, 'ongoing');
SET @pid := LAST_INSERT_ID();
SELECT CONCAT('OK: project_id=', @pid) AS msg;

-- 3) equipment を登録（ここは「残る」前提）
--    ※ trigger要件: @actor_id / @event_type が必須
SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(
  name, model, quantity, unit, equipment_type_code, status_code,
  purchase_id, project_id, location_id, manager_id, user_id
) VALUES (
  CONCAT('RollbackItem-', @run_id), 'RB1', 1, 'pcs', 'asset', 'in_stock',
  NULL, @pid, @loc, @uid_admin, NULL
);

SET @eid := LAST_INSERT_ID();
SELECT CONCAT('OK: equipment_id=', @eid) AS msg;

-- 4) ここからが「rollback の本体」
SELECT '--- START TRANSACTION ---' AS msg;
START TRANSACTION;

-- 4-A) loan（本来は成功する更新）
--      ※ trigger要件: loan の時は @loan_to_id が必須
SET @actor_id := @uid_admin;
SET @event_type := 'loan';
SET @loan_to_id := @uid_member;

UPDATE equipment
SET status_code='loaned'
WHERE equipment_id=@eid;

SELECT 'OK: loan update (inside transaction)' AS msg;

-- 4-B) わざと失敗させる: loaned のまま discard（禁止）
--      ここで trigger が 45000 を返す想定
SELECT 'EXPECT ERROR: Cannot discard/return_to_funder while loaned (SQLSTATE 45000)' AS msg;

SET @actor_id := @uid_admin;
SET @event_type := 'discard';

UPDATE equipment
SET status_code='discarded'
WHERE equipment_id=@eid;

-- ↑ここはエラーになる想定（続けて ROLLBACK は実行されます）

SELECT '--- ROLLBACK ---' AS msg;
ROLLBACK;

-- 5) rollback 後の簡易確認（同一セッション内）
SELECT '--- check after rollback (same session) ---' AS msg;

SELECT equipment_id, name, status_code
FROM equipment
WHERE equipment_id=@eid;

SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- 6) after 用にIDを表示
SELECT '--- IDs for AFTER ---' AS msg;
SELECT @run_id AS run_id, @pid AS project_id, @loc AS location_id, @eid AS equipment_id;