-- Transaction cases for Equipment Management DB (MySQL 8.x / InnoDB)
-- 1-to-1 mapping with: docs/06_transaction_design.md (T-00 .. T-08)
--
-- Policy (Approach A / policy-2):
--   - INSERT/UPDATE equipment => triggers auto INSERT into equipment_events
--   - Before INSERT/UPDATE, session variables are required:
--       @actor_id (people.id), @event_type (string)

SET NAMES utf8mb4;

-- Optional session vars for specific event types (required when used)
SET @loan_to_id := NULL;
SET @return_to_id := NULL;

-- ==========================================================
-- 0) CHECK: Resolve IDs used in transaction cases
-- ==========================================================

-- Users
SET @uid_admin  := (SELECT id FROM people WHERE user_name='admin01');
SET @uid_member := (SELECT id FROM people WHERE user_name='member01');
SET @uid_viewer := (SELECT id FROM people WHERE user_name='viewer01');

-- Project
SET @pid_main := (SELECT id FROM projects WHERE project_no='PJ-2025-001');

SET @loc_lab   := (SELECT id FROM locations WHERE name='研究室A（本館3F）');
SET @loc_store := (SELECT id FROM locations WHERE name='倉庫（別館1F）');

-- Run tag (to make inserted sample equipment names unique per run)
SET @run_tag := DATE_FORMAT(NOW(), '%Y%m%d%H%i%s');

-- Equipment IDs (created in T-00)
SET @eid_router  := NULL;
SET @eid_sa      := NULL;
SET @eid_battery := NULL;

-- Ensure required reference IDs exist (NULLだと後続が失敗する)
SELECT
  (@uid_admin  IS NOT NULL)  AS ok_admin,
  (@uid_member IS NOT NULL)  AS ok_member,
  (@uid_viewer IS NOT NULL)  AS ok_viewer,
  (@pid_main   IS NOT NULL)  AS ok_project,
  (@loc_lab    IS NOT NULL)  AS ok_location_lab,
  (@loc_store  IS NOT NULL)  AS ok_location_store;

-- Quick sanity check
SELECT
  @uid_admin  AS admin_id,
  @uid_member AS member_id,
  @uid_viewer AS viewer_id,
  @pid_main   AS project_id,
  @loc_lab    AS location_lab,
  @loc_store  AS location_store,
  @eid_router AS equipment_router,
  @eid_sa     AS equipment_spectrum_analyzer,
  @eid_battery AS equipment_battery;


-- ==========================================================
-- T-00 新規登録（register_purchase）
-- docs/06_transaction_design.md: T-00
-- ==========================================================

-- Purpose: create purchase + equipment (and optional identifiers)
-- Note: INSERT on equipment auto INSERT into equipment_events (Approach A / policy-2)

-- Vendor (ensure exists)
INSERT INTO vendors (name, contact_name, phone, email, address)
SELECT 'サンプル商事', '担当A', '000-0000-0000', 'sales@example.com', '東京都サンプル1-2-3'
WHERE NOT EXISTS (SELECT 1 FROM vendors WHERE name='サンプル商事');
SET @vid_sample := (SELECT id FROM vendors WHERE name='サンプル商事' ORDER BY id DESC LIMIT 1);

START TRANSACTION;

SET @actor_id   := @uid_admin;
SET @event_type := 'register_purchase';

-- 1) purchases (one purchase can cover multiple equipment)
INSERT INTO purchases (vendor_id, order_date, delivery_date, purchase_date, price, note)
VALUES (
  @vid_sample,
  '2025-12-01',
  '2025-12-05',
  '2025-12-05',
  150000.00,
  CONCAT('T-00: register_purchase (授業用サンプル購入) run=', @run_tag)
);
SET @purchase_id := LAST_INSERT_ID();

-- 2) equipment A: router-like (used for deploy -> discard)
INSERT INTO equipment (
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id,
  project_id, location_id, manager_id, user_id
) VALUES (
  CONCAT('Wi-Fi ルータ (run=', @run_tag, ')'),
  'AX3000',
  1,
  '台',
  'equipment',
  'in_stock',
  @purchase_id,
  @pid_main,
  @loc_store,
  @uid_admin,
  NULL
);
SET @eid_router := LAST_INSERT_ID();

-- 3) equipment B: spectrum-analyzer-like (used for assign/loan/repair/return_to_funder)
INSERT INTO equipment (
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id,
  project_id, location_id, manager_id, user_id
) VALUES (
  CONCAT('スペクトラムアナライザ (run=', @run_tag, ')'),
  'SA-1000',
  1,
  '台',
  'equipment',
  'in_stock',
  @purchase_id,
  @pid_main,
  @loc_store,
  @uid_admin,
  NULL
);
SET @eid_sa := LAST_INSERT_ID();

-- 4) equipment C: consumable-like (battery) (used for search/sample only)
INSERT INTO equipment (
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id,
  project_id, location_id, manager_id, user_id
) VALUES (
  CONCAT('単三電池 (run=', @run_tag, ')'),
  'AA',
  1,
  '箱',
  'consumable',
  'in_stock',
  @purchase_id,
  @pid_main,
  @loc_store,
  @uid_admin,
  NULL
);
SET @eid_battery := LAST_INSERT_ID();

COMMIT;

-- Verify (purchase + equipment + auto events)
SELECT * FROM purchases WHERE id = @purchase_id;
SELECT * FROM equipment WHERE equipment_id IN (@eid_router, @eid_sa, @eid_battery) ORDER BY equipment_id;
SELECT * FROM equipment_events WHERE equipment_id IN (@eid_router, @eid_sa, @eid_battery)
ORDER BY equipment_id, event_timestamp DESC;

-- Helper: show current state for the 3 sample equipment
SELECT equipment_id, name, status_code, project_id, location_id, manager_id, user_id
FROM equipment
WHERE equipment_id IN (@eid_router, @eid_sa, @eid_battery)
ORDER BY equipment_id;

-- ==========================================================
-- T-01 配備（deploy）
-- docs/06_transaction_design.md: T-01
-- ==========================================================

-- Purpose: assign project/location/manager, optionally move to in_service

START TRANSACTION;

SET @actor_id  := @uid_admin;
SET @event_type := 'deploy';

-- Lock row
SELECT * FROM equipment WHERE equipment_id = @eid_router FOR UPDATE;

-- Update
UPDATE equipment
SET project_id  = @pid_main,
    location_id = @loc_lab,
    manager_id  = @uid_admin,
    status_code = 'in_service'
WHERE equipment_id = @eid_router;

COMMIT;

-- Verify
SELECT * FROM equipment WHERE equipment_id = @eid_router;
SELECT * FROM equipment_events WHERE equipment_id = @eid_router ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-02 使用者変更（change_user）
-- docs/06_transaction_design.md: T-02
-- ==========================================================

START TRANSACTION;

SET @actor_id  := @uid_admin;
SET @event_type := 'change_user';

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET user_id = @uid_viewer,
    status_code = 'assigned'
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-03 貸出（loan）
-- docs/06_transaction_design.md: T-03
-- ==========================================================

START TRANSACTION;

SET @actor_id  := @uid_member;
SET @event_type := 'loan';
SET @loan_to_id := @uid_viewer; -- example: loan to viewer01

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET status_code = 'loaned'
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-04 返却（return）
-- docs/06_transaction_design.md: T-04
-- ==========================================================

START TRANSACTION;

SET @actor_id  := @uid_member;
SET @event_type := 'return';
SET @return_to_id := @uid_member; -- example: returned to member01

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET status_code = 'in_stock',
    location_id = @loc_store
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-05 故障登録（report_broken）
-- docs/06_transaction_design.md: T-05
-- ==========================================================

START TRANSACTION;

SET @actor_id  := @uid_member;
SET @event_type := 'report_broken';

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET status_code = 'broken'
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-06 修理開始/完了（start_repair / finish_repair）
-- docs/06_transaction_design.md: T-06
-- ==========================================================

-- Start repair
START TRANSACTION;

SET @actor_id  := @uid_admin;
SET @event_type := 'start_repair';

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET status_code = 'repairing'
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- Finish repair
START TRANSACTION;

SET @actor_id  := @uid_admin;
SET @event_type := 'finish_repair';

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET status_code = 'in_service'
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-07 廃棄（discard）
-- docs/06_transaction_design.md: T-07
-- ==========================================================

START TRANSACTION;

SET @actor_id  := @uid_admin;
SET @event_type := 'discard';

SELECT * FROM equipment WHERE equipment_id = @eid_router FOR UPDATE;

UPDATE equipment
SET status_code = 'discarded'
WHERE equipment_id = @eid_router;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_router;
SELECT * FROM equipment_events WHERE equipment_id = @eid_router ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- T-08 資金元返却（return_to_funder）
-- docs/06_transaction_design.md: T-08
-- ==========================================================

START TRANSACTION;

SET @actor_id  := @uid_admin;
SET @event_type := 'return_to_funder';

SELECT * FROM equipment WHERE equipment_id = @eid_sa FOR UPDATE;

UPDATE equipment
SET status_code = 'returned_to_funder'
WHERE equipment_id = @eid_sa;

COMMIT;

SELECT * FROM equipment WHERE equipment_id = @eid_sa;
SELECT * FROM equipment_events WHERE equipment_id = @eid_sa ORDER BY event_timestamp DESC LIMIT 5;

-- ==========================================================
-- End of transaction cases
-- ==========================================================