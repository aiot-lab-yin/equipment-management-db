-- tests/01_constraints/action.sql
-- Purpose: Constraint validation (MANUAL EXECUTION VERSION)
--
-- How to use this file:
--   1. Open mysql interactive shell:
--        docker exec -it <container> mysql -uroot -proot <DB_NAME>
--   2. Copy & paste ONE STEP at a time into mysql>
--   3. For steps marked [NEGATIVE], the ERROR message itself is the expected result.
--   4. Take screenshots of results and error messages as evidence.

-- =========================================================
-- STEP 0: Preparation (run once)
-- =========================================================

-- Pick existing users from seed data
SET @uid_admin  := (SELECT id FROM people WHERE role='admin'  ORDER BY id LIMIT 1);
SET @uid_member := (SELECT id FROM people WHERE role='member' ORDER BY id LIMIT 1);

-- Create two locations so location updates actually change values
INSERT INTO locations(name, address) VALUES ('T01-Loc-A', 'Address A');
SET @loc_a := LAST_INSERT_ID();

INSERT INTO locations(name, address) VALUES ('T01-Loc-B', 'Address B');
SET @loc_b := LAST_INSERT_ID();

-- Create vendor and purchase
INSERT INTO vendors(name) VALUES ('T01-Vendor');
SET @vendor_id := LAST_INSERT_ID();

INSERT INTO purchases(vendor_id, order_date, purchase_date, price)
VALUES (@vendor_id, '2025-12-01', '2025-12-05', 1000);
SET @purchase_id := LAST_INSERT_ID();

-- Create project
INSERT INTO projects(
  project_no, name, short_name, programe_name,
  funder, start_date, end_date, representative_id, status
) VALUES (
  'P-T01',
  'T01 Project',
  'T01',
  'Program T01',
  'Funder T01',
  '2025-01-01',
  '2026-12-31',
  @uid_admin,
  'ongoing'
);
SET @project_id := LAST_INSERT_ID();

-- =========================================================
-- STEP 1 [POSITIVE]: INSERT equipment (should SUCCEED)
-- =========================================================

SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id, project_id, location_id, manager_id, user_id
) VALUES (
  'T01-Test-Item',
  'MODEL-01',
  1,
  'pcs',
  'asset',
  'in_stock',
  @purchase_id,
  @project_id,
  @loc_a,
  @uid_admin,
  NULL
);

SET @eid := LAST_INSERT_ID();

-- Confirm equipment and event were created
SELECT * FROM equipment WHERE equipment_id = @eid;
SELECT * FROM equipment_events WHERE equipment_id = @eid;

-- =========================================================
-- STEP 2 [NEGATIVE]: UPDATE without @actor_id (should FAIL)
-- =========================================================

SET @actor_id := NULL;
SET @event_type := 'deploy';

UPDATE equipment
SET location_id = @loc_b
WHERE equipment_id = @eid;

-- EXPECTED:
-- ERROR 1644 (45000): Missing session variable: @actor_id (people.id)

-- =========================================================
-- STEP 3 [NEGATIVE]: UPDATE without @event_type (should FAIL)
-- =========================================================

SET @actor_id := @uid_admin;
SET @event_type := NULL;

UPDATE equipment
SET location_id = @loc_a
WHERE equipment_id = @eid;

-- EXPECTED:
-- ERROR 1644 (45000): Missing session variable: @event_type

-- =========================================================
-- STEP 4 [NEGATIVE]: loan without @loan_to_id (should FAIL)
-- =========================================================

SET @actor_id := @uid_member;
SET @event_type := 'loan';
SET @loan_to_id := NULL;

UPDATE equipment
SET status_code = 'loaned'
WHERE equipment_id = @eid;

-- EXPECTED:
-- ERROR 1644 (45000): Missing session variable: @loan_to_id (people.id)

-- =========================================================
-- STEP 5 [NEGATIVE]: return without @return_to_id (should FAIL)
-- =========================================================

SET @actor_id := @uid_member;
SET @event_type := 'return';
SET @return_to_id := NULL;

UPDATE equipment
SET status_code = 'in_stock'
WHERE equipment_id = @eid;

-- EXPECTED:
-- ERROR 1644 (45000): Missing session variable: @return_to_id (people.id)

-- =========================================================
-- STEP 6A [POSITIVE]: discard equipment (should SUCCEED)
-- =========================================================

SET @actor_id := @uid_admin;
SET @event_type := 'discard';

UPDATE equipment
SET status_code = 'discarded'
WHERE equipment_id = @eid;

SELECT equipment_id, status_code FROM equipment WHERE equipment_id = @eid;

-- =========================================================
-- STEP 6B [NEGATIVE]: UPDATE after discard (should FAIL)
-- =========================================================

SET @actor_id := @uid_admin;
SET @event_type := 'deploy';

UPDATE equipment
SET location_id = @loc_a
WHERE equipment_id = @eid;

-- EXPECTED:
-- ERROR 1644 (45000): Terminal equipment cannot be updated