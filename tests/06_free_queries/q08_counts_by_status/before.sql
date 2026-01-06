-- 目的: ダッシュボード表示の前提確認
-- 実行方法: USE <DB名>; のあと貼り付け

SET NAMES utf8mb4;

SELECT '========== FREE Q08: COUNTS BY STATUS (BEFORE) ==========' AS msg;
SELECT DATABASE() AS current_db;

-- project: MAIN優先、なければ最新（絞りたくないなら NULL にしてOK）
SET @pid_main := (
  SELECT id FROM projects
  WHERE short_name='MAIN'
  ORDER BY id DESC LIMIT 1
);
SET @pid_main := COALESCE(@pid_main, (SELECT id FROM projects ORDER BY id DESC LIMIT 1));

SET @q_project_id := NULL;  -- ← projectで絞るなら @pid_main を入れる

SELECT '--- params ---' AS msg;
SELECT @q_project_id AS q_project_id;

SELECT '--- equipment total ---' AS msg;
SELECT COUNT(*) AS equipment_total FROM equipment;