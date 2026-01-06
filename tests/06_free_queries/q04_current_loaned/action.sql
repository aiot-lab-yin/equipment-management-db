-- 目的: 現在 loaned の設備一覧 + 「最後の loan の宛先」を表示
-- 注意: loaned が1件も無いと 0行（正常）
-- 実行方法: 貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== FREE Q04: CURRENT LOANED (ACTION) ==========' AS msg;

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
    WHERE event_type='loan'
    GROUP BY equipment_id
  ) t
    ON t.equipment_id = ev1.equipment_id
   AND t.max_ts = ev1.event_timestamp
  WHERE ev1.event_type='loan'
) last_loan
  ON last_loan.equipment_id = e.equipment_id
LEFT JOIN people p_to
  ON p_to.id = last_loan.loan_to_id
WHERE e.status_code='loaned'
  AND (@q_project_id IS NULL OR e.project_id=@q_project_id)
ORDER BY last_loan.event_timestamp DESC;