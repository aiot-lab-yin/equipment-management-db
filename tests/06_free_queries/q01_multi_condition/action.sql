-- 目的: 代表的な「多条件検索」を1回実行する（現状態の絞り込み）
-- 実行方法: MySQL端末に貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== FREE Q01: MULTI-CONDITION (ACTION) ==========' AS msg;

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
  AND (@q_project_id IS NULL OR e.project_id = @q_project_id)
  AND (@q_status     IS NULL OR e.status_code = @q_status)
  AND (@q_location   IS NULL OR e.location_id = @q_location)
ORDER BY e.equipment_id DESC;