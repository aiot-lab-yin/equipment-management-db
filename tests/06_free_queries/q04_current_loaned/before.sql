-- 目的: loaned一覧を見る準備（project条件は任意）
-- 実行方法: USE <DB名>; のあと貼り付け

SET NAMES utf8mb4;

SELECT '========== FREE Q04: CURRENT LOANED (BEFORE) ==========' AS msg;
SELECT DATABASE() AS current_db;

-- project: MAIN優先、なければ最新
SET @pid_main := (
  SELECT id FROM projects
  WHERE short_name='MAIN'
  ORDER BY id DESC LIMIT 1
);
SET @pid_main := COALESCE(@pid_main, (SELECT id FROM projects ORDER BY id DESC LIMIT 1));

-- 条件：projectで絞りたいなら @pid_main、絞らないなら NULL
SET @q_project_id := @pid_main;

SELECT '--- params ---' AS msg;
SELECT @q_project_id AS q_project_id;

SELECT '--- current loaned count ---' AS msg;
SELECT COUNT(*) AS loaned_cnt
FROM equipment
WHERE status_code='loaned'
  AND (@q_project_id IS NULL OR project_id=@q_project_id);