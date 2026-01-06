-- 目的: 履歴が「増えていく」ことを確認する補助
-- 実行方法: actionのあと

SET NAMES utf8mb4;

SELECT '========== FREE Q07: TIMELINE (AFTER) ==========' AS msg;

SELECT '--- event count for target ---' AS msg;
SELECT COUNT(*) AS event_cnt
FROM equipment_events
WHERE equipment_id=@eid_target;

SELECT '--- latest event for target ---' AS msg;
SELECT id, equipment_id, event_type, from_status_code, to_status_code, actor_id, event_timestamp
FROM equipment_events
WHERE equipment_id=@eid_target
ORDER BY event_timestamp DESC
LIMIT 1;