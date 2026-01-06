-- tests/03_loan_return/action.sql
-- 目的: 貸出(loan) -> 返却(return) の代表例を実行し、eventsが残ることを確認する
-- 実行方法: MySQL端末に貼り付けて上から順に実行（途中エラーが出たらスクショ）
-- 注意:
--   - equipment INSERT/UPDATE はトリガにより @actor_id / @event_type が必須
--   - loan の時は @loan_to_id が必須
--   - return の時は @return_to_id が必須

SET NAMES utf8mb4;

SELECT '========== TEST 03: LOAN / RETURN (ACTION) ==========' AS msg;

-- 実行識別子（重複回避）
SET @run_id := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');
SELECT CONCAT('RUN_ID=', @run_id) AS run_id;

-- 1) actor（admin/member/viewer）を取得
SELECT id INTO @uid_admin  FROM people WHERE role='admin'  ORDER BY id LIMIT 1;
SELECT id INTO @uid_member FROM people WHERE role='member' ORDER BY id LIMIT 1;
SELECT id INTO @uid_viewer FROM people WHERE role='viewer' ORDER BY id LIMIT 1;

SELECT CONCAT('admin_id=', @uid_admin, ', member_id=', @uid_member, ', viewer_id=', @uid_viewer) AS actors;

-- 2) location を作成（このテスト専用）
INSERT INTO locations(name, address)
VALUES (CONCAT('LoanLab-', @run_id), 'Campus');
SET @loc := LAST_INSERT_ID();
SELECT CONCAT('OK: location_id=', @loc) AS msg;

-- 3) project を作成（project_noは UNIQUE）
INSERT INTO projects(project_no, name, short_name, programe_name, funder, start_date, end_date, representative_id, status)
VALUES (CONCAT('P-LOAN-', @run_id), CONCAT('Loan Project ', @run_id), 'LN', 'Prog', 'Funder',
        CURDATE(), CURDATE(), @uid_admin, 'ongoing');
SET @pid := LAST_INSERT_ID();
SELECT CONCAT('OK: project_id=', @pid) AS msg;

-- 4) equipment INSERT（purchase_id は NULL でもOK）
SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(
  name, model, quantity, unit, equipment_type_code, status_code,
  purchase_id, project_id, location_id, manager_id, user_id
)
VALUES (
  CONCAT('LoanItem-', @run_id), 'L1', 1, 'pcs', 'asset', 'in_stock',
  NULL, @pid, @loc, @uid_admin, NULL
);
SET @eid := LAST_INSERT_ID();
SELECT CONCAT('OK: equipment_id=', @eid) AS msg;

-- 5) loan（貸出）: status_code=loaned（@loan_to_id 必須）
--   例: member が viewer に貸し出す想定
SET @actor_id := @uid_member;
SET @event_type := 'loan';
SET @loan_to_id := @uid_viewer;

UPDATE equipment
SET status_code='loaned'
WHERE equipment_id=@eid;

SELECT 'OK: loan update' AS msg;

-- 6) return（返却）: status_code=in_stock（@return_to_id 必須）
--   例: viewer が member に返却した想定
SET @actor_id := @uid_viewer;
SET @event_type := 'return';
SET @return_to_id := @uid_member;

UPDATE equipment
SET status_code='in_stock'
WHERE equipment_id=@eid;

SELECT 'OK: return update' AS msg;

-- 7) 結果確認（equipment と events）
SELECT '--- equipment (final) ---' AS msg;
SELECT * FROM equipment WHERE equipment_id=@eid;

SELECT '--- equipment_events (time order) ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code,
       loan_to_id, return_to_id, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid
ORDER BY event_timestamp;

-- 8) after 用にIDを表示（同一セッションなら after でそのまま使える）
SELECT '--- IDs for AFTER ---' AS msg;
SELECT @run_id AS run_id, @pid AS project_id, @loc AS location_id, @eid AS equipment_id;