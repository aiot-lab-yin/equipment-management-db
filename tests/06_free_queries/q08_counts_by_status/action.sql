-- 目的: status_code ごとの件数を出す（最も基本の読み取りテスト）
-- 実行方法: 貼り付けて実行

SET NAMES utf8mb4;

SELECT '========== FREE Q08: COUNTS BY STATUS (ACTION) ==========' AS msg;

SELECT
  e.status_code,
  COUNT(*) AS cnt
FROM equipment e
WHERE (@q_project_id IS NULL OR e.project_id=@q_project_id)
GROUP BY e.status_code
ORDER BY cnt DESC;