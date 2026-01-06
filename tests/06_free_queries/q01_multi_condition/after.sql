-- 目的: 「条件が効いているか」を確認する（初心者向けチェック）
-- 実行方法: action の直後に貼り付け

SET NAMES utf8mb4;

SELECT '========== FREE Q01: MULTI-CONDITION (AFTER) ==========' AS msg;

-- 条件を満たす件数（0でもOK：データ状態による）
SELECT '--- matched count ---' AS msg;
SELECT COUNT(*) AS matched_cnt
FROM equipment e
WHERE 1=1
  AND (@q_project_id IS NULL OR e.project_id = @q_project_id)
  AND (@q_status     IS NULL OR e.status_code = @q_status)
  AND (@q_location   IS NULL OR e.location_id = @q_location);

-- 目視用：条件の再掲
SELECT '--- params (recheck) ---' AS msg;
SELECT @q_project_id AS q_project_id, @q_status AS q_status, @q_location AS q_location;