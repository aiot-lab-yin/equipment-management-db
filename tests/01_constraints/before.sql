-- tests/01_constraints/before.sql
-- Purpose:
--   Confirm database state BEFORE running constraint validation.
--   (1) Connected database
--   (2) Required tables / triggers exist
--   (3) Seed data is loaded (minimum counts)

-- ==============================
-- Section: Environment
-- ==============================
SELECT '01_constraints: BEFORE' AS section;
SELECT DATABASE() AS current_db;
SELECT VERSION()  AS mysql_version;

-- ==============================
-- Section: Tables
-- ==============================
SELECT 'tables' AS label;
SHOW TABLES;

-- ==============================
-- Section: Triggers (equipment)
-- ==============================
SELECT 'triggers_equipment' AS label;
SHOW TRIGGERS LIKE 'equipment%';

-- ==============================
-- Section: Seed data counts
-- ==============================
SELECT 'seed_counts' AS label;
SELECT 'people' AS table_name, COUNT(*) AS cnt FROM people
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'locations', COUNT(*) FROM locations
UNION ALL SELECT 'vendors', COUNT(*) FROM vendors
UNION ALL SELECT 'purchases', COUNT(*) FROM purchases
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'equipment_events', COUNT(*) FROM equipment_events;

-- ==============================
-- Section: Latest events (reference)
-- ==============================
SELECT 'latest_events (top 5)' AS label;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
ORDER BY event_timestamp DESC, id DESC
LIMIT 5;