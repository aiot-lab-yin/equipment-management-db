

-- sql/05_free_queries.sql
-- Free Queries (submission-ready, concrete-value examples)
-- Based on: docs/07_query_design.md (Query Design)
-- Notes:
--  - Do NOT include `USE sampledb;` here. Select DB at execution time.
--  - These queries are read-only (SELECT) and can be executed repeatedly.

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 0) Helper: resolve frequently used IDs (best-effort)
-- ---------------------------------------------------------------------
-- Project (prefer short_name='MAIN', else the newest one)
SET @pid_main := (
  SELECT id FROM projects
  WHERE short_name = 'MAIN'
  ORDER BY id DESC
  LIMIT 1
);
SET @pid_main := COALESCE(@pid_main, (SELECT id FROM projects ORDER BY id DESC LIMIT 1));

-- Locations (prefer '倉庫' and '研究室', else newest)
SET @loc_store := (
  SELECT id FROM locations
  WHERE name IN ('倉庫', 'ストレージ', '保管庫')
  ORDER BY id DESC
  LIMIT 1
);
SET @loc_lab := (
  SELECT id FROM locations
  WHERE name IN ('研究室', 'ラボ')
  ORDER BY id DESC
  LIMIT 1
);
SET @loc_store := COALESCE(@loc_store, (SELECT id FROM locations ORDER BY id DESC LIMIT 1));
SET @loc_lab   := COALESCE(@loc_lab,   (SELECT id FROM locations ORDER BY id DESC LIMIT 1));

-- People (pick any valid IDs as examples)
SET @uid_admin  := (SELECT id FROM people WHERE role='admin'  ORDER BY id ASC LIMIT 1);
SET @uid_member := (SELECT id FROM people WHERE role='member' ORDER BY id ASC LIMIT 1);
SET @uid_viewer := (SELECT id FROM people WHERE role='viewer' ORDER BY id ASC LIMIT 1);
SET @uid_admin  := COALESCE(@uid_admin,  (SELECT id FROM people ORDER BY id ASC LIMIT 1));
SET @uid_member := COALESCE(@uid_member, (SELECT id FROM people ORDER BY id ASC LIMIT 1));
SET @uid_viewer := COALESCE(@uid_viewer, (SELECT id FROM people ORDER BY id ASC LIMIT 1));

-- Latest sample equipment (created by sql/04_transaction_cases.sql; use name pattern)
SET @eid_latest_sa := (
  SELECT equipment_id
  FROM equipment
  WHERE name LIKE 'スペクトラムアナライザ%'
  ORDER BY equipment_id DESC
  LIMIT 1
);
SET @eid_latest_router := (
  SELECT equipment_id
  FROM equipment
  WHERE name LIKE 'Wi-Fi ルータ%'
  ORDER BY equipment_id DESC
  LIMIT 1
);

-- ---------------------------------------------------------------------
-- Q-01) Multi-condition search (current state)
--      (FR-07 / UC-07)
-- ---------------------------------------------------------------------
-- Example: project=@pid_main AND status='in_stock' AND location=@loc_store
SELECT
  e.equipment_id,
  e.name,
  e.model,
  e.quantity,
  e.unit,
  e.equipment_type_code,
  e.status_code,
  e.project_id,
  e.location_id,
  e.manager_id,
  e.user_id
FROM equipment e
WHERE 1=1
  AND (@pid_main   IS NULL OR e.project_id = @pid_main)
  AND ('in_stock'  IS NULL OR e.status_code = 'in_stock')
  AND (@loc_store  IS NULL OR e.location_id = @loc_store)
ORDER BY e.equipment_id DESC;

-- ---------------------------------------------------------------------
-- Q-02) Project equipment list (assignment #4)
-- ---------------------------------------------------------------------
SELECT
  e.equipment_id,
  e.name,
  e.status_code,
  e.location_id,
  e.manager_id,
  e.user_id
FROM equipment e
WHERE e.project_id = @pid_main
ORDER BY e.equipment_id DESC;

-- ---------------------------------------------------------------------
-- Q-03) Equipment that became 'loaned' within last 30 days (history)
--      (good for assignment #6)
-- ---------------------------------------------------------------------
SELECT DISTINCT
  e.equipment_id,
  e.name
FROM equipment e
JOIN equipment_events ev
  ON ev.equipment_id = e.equipment_id
WHERE (@pid_main IS NULL OR e.project_id = @pid_main)
  AND ev.to_status_code = 'loaned'
  AND ev.event_timestamp >= (NOW() - INTERVAL 30 DAY)
ORDER BY e.equipment_id DESC;

-- ---------------------------------------------------------------------
-- Q-04) Current loaned list + latest loan destination (events)
-- ---------------------------------------------------------------------
SELECT
  e.equipment_id,
  e.name,
  e.status_code,
  last_loan.event_timestamp AS loaned_at,
  p_to.full_name AS loan_to_name,
  p_to.email     AS loan_to_email
FROM equipment e
JOIN (
  SELECT
    ev1.equipment_id,
    ev1.loan_to_id,
    ev1.event_timestamp
  FROM equipment_events ev1
  JOIN (
    SELECT equipment_id, MAX(event_timestamp) AS max_ts
    FROM equipment_events
    WHERE event_type = 'loan'
    GROUP BY equipment_id
  ) t
    ON t.equipment_id = ev1.equipment_id
   AND t.max_ts = ev1.event_timestamp
  WHERE ev1.event_type = 'loan'
) last_loan
  ON last_loan.equipment_id = e.equipment_id
LEFT JOIN people p_to
  ON p_to.id = last_loan.loan_to_id
WHERE e.status_code = 'loaned'
  AND (@pid_main IS NULL OR e.project_id = @pid_main)
ORDER BY last_loan.event_timestamp DESC;

-- ---------------------------------------------------------------------
-- Q-05) Reverse lookup by university_id / funding_id
-- ---------------------------------------------------------------------
-- Example: pick any existing identifiers (if none, this query returns 0 rows)
SET @example_univ_id := (SELECT university_id FROM equipment_identifiers ORDER BY equipment_id DESC LIMIT 1);
SET @example_fund_id := (SELECT funding_id    FROM equipment_identifiers ORDER BY equipment_id DESC LIMIT 1);

SELECT
  e.equipment_id,
  e.name,
  e.status_code,
  ids.university_id,
  ids.funding_id
FROM equipment_identifiers ids
JOIN equipment e
  ON e.equipment_id = ids.equipment_id
WHERE ( @example_univ_id IS NOT NULL AND ids.university_id = @example_univ_id )
   OR ( @example_fund_id IS NOT NULL AND ids.funding_id    = @example_fund_id );

-- ---------------------------------------------------------------------
-- Q-06) Purchases by vendor in last 365 days
-- ---------------------------------------------------------------------
SET @vid_latest := (SELECT id FROM vendors ORDER BY id DESC LIMIT 1);

SELECT
  pu.id AS purchase_id,
  pu.purchase_date,
  pu.price,
  pu.note,
  v.name AS vendor_name
FROM purchases pu
JOIN vendors v
  ON v.id = pu.vendor_id
WHERE pu.vendor_id = @vid_latest
  AND pu.purchase_date >= (CURDATE() - INTERVAL 365 DAY)
ORDER BY pu.purchase_date DESC;

-- ---------------------------------------------------------------------
-- Q-07) Timeline (audit) for one equipment_id
-- ---------------------------------------------------------------------
-- Example: show timeline for latest spectrum analyzer (if exists)
SELECT
  ev.event_timestamp,
  ev.event_type,
  ev.from_status_code,
  ev.to_status_code,
  ev.from_user_id,
  ev.to_user_id,
  ev.from_manager_id,
  ev.to_manager_id,
  ev.loan_to_id,
  ev.return_to_id,
  ev.actor_id
FROM equipment_events ev
WHERE ev.equipment_id = @eid_latest_sa
ORDER BY ev.event_timestamp;

-- ---------------------------------------------------------------------
-- Q-08) Dashboard: counts by status (optionally within project)
-- ---------------------------------------------------------------------
SELECT
  e.status_code,
  COUNT(*) AS cnt
FROM equipment e
WHERE (@pid_main IS NULL OR e.project_id = @pid_main)
GROUP BY e.status_code
ORDER BY cnt DESC;

-- ---------------------------------------------------------------------
-- Assignment #6 example (free): complex search combining current + history
-- ---------------------------------------------------------------------
-- Example:
--  - project=@pid_main
--  - current status is NOT terminal
--  - has at least one loan event in last 90 days
--  - currently located in lab OR store
SELECT DISTINCT
  e.equipment_id,
  e.name,
  e.status_code,
  e.location_id
FROM equipment e
JOIN equipment_events ev
  ON ev.equipment_id = e.equipment_id
JOIN equipment_status_reference sr
  ON sr.code = e.status_code
WHERE e.project_id = @pid_main
  AND sr.is_terminal = 0
  AND ev.event_type = 'loan'
  AND ev.event_timestamp >= (NOW() - INTERVAL 90 DAY)
  AND e.location_id IN (@loc_lab, @loc_store)
ORDER BY e.equipment_id DESC;