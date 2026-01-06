-- tests/01_constraints/after.sql
-- Purpose: Manually confirm DB state AFTER running action.sql
-- This file is intended to be copied & pasted into the MySQL console.
-- No assertions, no EXPECT/FAIL logic. Human-readable results only.

SELECT '01_constraints: AFTER (manual check)' AS section;

-- ------------------------------------------------------------
-- 1. Show recently created equipment for this test
-- ------------------------------------------------------------
-- Confirm:
--  - equipment was inserted
--  - final status (e.g. discarded) is reflected
SELECT
  equipment_id,
  name,
  status_code,
  project_id,
  location_id,
  manager_id,
  user_id
FROM equipment
WHERE name LIKE 'T01-Constraints-%'
ORDER BY equipment_id DESC
LIMIT 5;

-- ------------------------------------------------------------
-- 2. Show related events (history)
-- ------------------------------------------------------------
-- Confirm:
--  - register event exists
--  - discard event exists
--  - actor_id is recorded
SELECT
  ev.id,
  ev.equipment_id,
  ev.event_type,
  ev.from_status_code,
  ev.to_status_code,
  ev.actor_id,
  ev.event_timestamp
FROM equipment_events ev
JOIN equipment e ON e.equipment_id = ev.equipment_id
WHERE e.name LIKE 'T01-Constraints-%'
ORDER BY ev.event_timestamp DESC, ev.id DESC
LIMIT 20;

-- ------------------------------------------------------------
-- 3. Reference: current table sizes (sanity check)
-- ------------------------------------------------------------
SELECT 'table_counts' AS info;
SELECT 'equipment' AS table_name, COUNT(*) AS cnt FROM equipment
UNION ALL
SELECT 'equipment_events', COUNT(*) FROM equipment_events;