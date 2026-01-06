-- 目的: 結果の読み方（確認ポイントだけ）
-- 実行方法: action の直後

SET NAMES utf8mb4;

SELECT '========== FREE Q04: CURRENT LOANED (AFTER) ==========' AS msg;

-- 確認用：loanイベントが最近ある設備（上位10件）
SELECT '--- latest loan events (top 10) ---' AS msg;
SELECT
  id, equipment_id, event_type, from_status_code, to_status_code, loan_to_id, actor_id, event_timestamp
FROM equipment_events
WHERE event_type='loan'
ORDER BY event_timestamp DESC
LIMIT 10;