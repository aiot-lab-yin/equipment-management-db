-- tests/06_transaction_rollback.sql
SET NAMES utf8mb4;

SELECT id INTO @uid_admin FROM people WHERE role='admin' LIMIT 1;

INSERT INTO locations(name,address) VALUES ('RollbackLab','Campus');
SET @loc := LAST_INSERT_ID();

INSERT INTO vendors(name,contact_name,phone,email,address)
VALUES ('RBVendor','RB','444','rb@test','Tokyo');
SET @vid := LAST_INSERT_ID();

INSERT INTO purchases(vendor_id,order_date,delivery_date,purchase_date,price,note)
VALUES (@vid,CURDATE(),CURDATE(),CURDATE(),1111,'rollback');
SET @purchase := LAST_INSERT_ID();

INSERT INTO projects(project_no,name,short_name,programe_name,funder,start_date,end_date,representative_id,status)
VALUES ('P-RB','Rollback Project','RB','Prog','Funder',CURDATE(),CURDATE(),@uid_admin,'ongoing');
SET @pid := LAST_INSERT_ID();

SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(name,model,quantity,unit,equipment_type_code,status_code,
                      purchase_id,project_id,location_id,manager_id,user_id)
VALUES ('RBItem','RB1',1,'pcs','asset','in_stock',
        @purchase,@pid,@loc,@uid_admin,NULL);
SET @eid := LAST_INSERT_ID();

START TRANSACTION;
  SET @actor_id := @uid_admin;
  SET @event_type := 'mark_broken';
  UPDATE equipment SET status_code='broken' WHERE equipment_id=@eid;
ROLLBACK;

SELECT equipment_id, status_code FROM equipment WHERE equipment_id=@eid;
SELECT * FROM equipment_events WHERE equipment_id=@eid ORDER BY event_timestamp;