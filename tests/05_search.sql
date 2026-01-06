-- tests/05_search.sql
SET NAMES utf8mb4;

SELECT p.project_no, e.equipment_id, e.name, e.status_code, l.name AS location
FROM equipment e
JOIN projects p ON e.project_id=p.id
JOIN locations l ON e.location_id=l.id
ORDER BY e.equipment_id DESC;

-- status 别统计
SELECT status_code, COUNT(*) cnt
FROM equipment
GROUP BY status_code;

-- 最近30天内发生过 loan 的设备
SELECT DISTINCT e.equipment_id, e.name
FROM equipment e
JOIN equipment_events ev ON ev.equipment_id=e.equipment_id
WHERE ev.event_type='loan'
  AND ev.event_timestamp >= NOW() - INTERVAL 30 DAY;