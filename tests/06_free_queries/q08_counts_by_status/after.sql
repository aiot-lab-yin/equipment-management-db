-- 目的: 合計が一致するか（初心者向けの確かめ方）
-- 実行方法: action の直後

SET NAMES utf8mb4;

SELECT '========== FREE Q08: COUNTS BY STATUS (AFTER) ==========' AS msg;

-- ステータス別合計（GROUP BY の合計）
SELECT '--- sum of grouped counts ---' AS msg;
SELECT SUM(t.cnt) AS sum_cnt
FROM (
  SELECT COUNT(*) AS cnt
  FROM equipment e
  WHERE (@q_project_id IS NULL OR e.project_id=@q_project_id)
  GROUP BY e.status_code
) t;

-- 比較用：equipmentの総件数（project条件を合わせる）
SELECT '--- total equipment (same filter) ---' AS msg;
SELECT COUNT(*) AS total_cnt
FROM equipment e
WHERE (@q_project_id IS NULL OR e.project_id=@q_project_id);