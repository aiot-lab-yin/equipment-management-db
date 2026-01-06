-- 目的: 1台の「イベント履歴」を時系列で表示
-- 実行方法: 貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== FREE Q07: TIMELINE (ACTION) ==========' AS msg;

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
WHERE ev.equipment_id=@eid_target
ORDER BY ev.event_timestamp;