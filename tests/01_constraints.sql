-- tests/01_constraints.sql
-- 制约与负系测试（部分 SQL 预期失败）

SET NAMES utf8mb4;

-- ---------- reference ----------
INSERT INTO equipment_type_reference(code, name)
VALUES ('asset','資産')
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO equipment_status_reference(code, name, is_usable, is_terminal)
VALUES
 ('in_stock','在庫',1,0),
 ('loaned','貸出中',0,0),
 ('discarded','廃棄済み',0,1)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- ---------- people ----------
INSERT IGNORE INTO people(user_name, full_name, email, mobile, affiliation, position, role)
VALUES
 ('admin','Admin','admin@test','000','Lab','Staff','admin'),
 ('member','Member','member@test','001','Lab','Student','member'),
 ('viewer','Viewer','viewer@test','002','External','Guest','viewer');

SELECT id INTO @uid_admin FROM people WHERE user_name='admin';
SELECT id INTO @uid_member FROM people WHERE user_name='member';
SELECT id INTO @uid_viewer FROM people WHERE user_name='viewer';

-- ---------- minimal master ----------
INSERT INTO locations(name,address) VALUES ('ConstraintLab','Campus');
SET @loc_id := LAST_INSERT_ID();

INSERT INTO vendors(name,contact_name,phone,email,address)
VALUES ('ConstraintVendor','Taro','000','v@test','Tokyo');
SET @vendor_id := LAST_INSERT_ID();

INSERT INTO purchases(vendor_id,order_date,delivery_date,purchase_date,price,note)
VALUES (@vendor_id,CURDATE(),CURDATE(),CURDATE(),1000,'constraint test');
SET @purchase_id := LAST_INSERT_ID();

INSERT INTO projects(project_no,name,short_name,programe_name,funder,start_date,end_date,representative_id,status)
VALUES ('P-CONSTRAINT','ConstraintProj','CP','Prog','Funder',CURDATE(),CURDATE(),@uid_admin,'ongoing');
SET @project_id := LAST_INSERT_ID();

-- ---------- INSERT requires actor ----------
SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(name,model,quantity,unit,equipment_type_code,status_code,
                      purchase_id,project_id,location_id,manager_id,user_id)
VALUES ('ConstraintItem','C1',1,'pcs','asset','in_stock',
        @purchase_id,@project_id,@loc_id,@uid_admin,NULL);
SET @eid := LAST_INSERT_ID();

SELECT 'OK insert' AS msg, @eid AS equipment_id;

-- ---------- NG: missing actor ----------
SET @actor_id := NULL;
SET @event_type := 'deploy';
UPDATE equipment SET status_code='loaned' WHERE equipment_id=@eid;

-- ---------- OK loan ----------
SET @actor_id := @uid_member;
SET @event_type := 'loan';
SET @loan_to_id := @uid_viewer;
UPDATE equipment SET status_code='loaned' WHERE equipment_id=@eid;

SELECT * FROM equipment_events WHERE equipment_id=@eid ORDER BY event_timestamp;