-- 目的: 「どの設備の履歴を見るか」を決める（確実に取れるようにフォールバック）
-- 実行方法: USE <DB名>; のあと貼り付け

SET NAMES utf8mb4;

SELECT '========== FREE Q07: TIMELINE (BEFORE) ==========' AS msg;
SELECT DATABASE() AS current_db;

-- できれば「スペクトラムアナライザ%」を使う。無ければ最新 equipment を使う。
SET @eid_target := (
  SELECT equipment_id
  FROM equipment
  WHERE name LIKE 'スペクトラムアナライザ%'
  ORDER BY equipment_id DESC
  LIMIT 1
);
SET @eid_target := COALESCE(@eid_target, (SELECT equipment_id FROM equipment ORDER BY equipment_id DESC LIMIT 1));

SELECT '--- target equipment ---' AS msg;
SELECT @eid_target AS equipment_id;

SELECT '--- equipment snapshot ---' AS msg;
SELECT equipment_id, name, status_code, project_id, location_id
FROM equipment
WHERE equipment_id=@eid_target;