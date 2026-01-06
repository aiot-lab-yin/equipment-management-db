-- tests/02_basic_crud.sql
SET NAMES utf8mb4;

SELECT id INTO @uid_admin FROM people WHERE role='admin' LIMIT 1;
SELECT id INTO @uid_member FROM people WHERE role='member' LIMIT 1;

INSERT INTO locations(name,address) VALUES ('CRUDLab','Campus');
SET @loc := LAST_INSERT_ID();

INSERT INTO vendors(name,contact_name,phone,email,address)
VALUES ('CRUDVendor','Hanako','111','crud@test','Tokyo');
SET @vid := LAST_INSERT_ID();

INSERT INTO purchases(vendor_id,order_date,delivery_date,purchase_date,price,note)
VALUES (@vid,CURDATE(),CURDATE(),CURDATE(),5000,'crud');
SET @pid_purchase := LAST_INSERT_ID();

INSERT INTO projects(project_no,name,short_name,programe_name,funder,start_date,end_date,representative_id,status)
VALUES ('P-CRUD','CRUD Project','CR','Prog','Funder',CURDATE(),CURDATE(),@uid_admin,'ongoing');
SET @pid := LAST_INSERT_ID();

SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(name,model,quantity,unit,equipment_type_code,status_code,
                      purchase_id,project_id,location_id,manager_id,user_id)
VALUES ('CRUDItem','X1',1,'pcs','asset','in_stock',
        @pid_purchase,@pid,@loc,@uid_admin,NULL);
SET @eid := LAST_INSERT_ID();

-- deploy
SET @actor_id := @uid_admin;
SET @event_type := 'deploy';
UPDATE equipment SET status_code='in_service' WHERE equipment_id=@eid;

-- assign
SET @actor_id := @uid_admin;
SET @event_type := 'assign';
UPDATE equipment SET status_code='assigned', user_id=@uid_member WHERE equipment_id=@eid;

SELECT * FROM equipment WHERE equipment_id=@eid;
SELECT * FROM equipment_events WHERE equipment_id=@eid ORDER BY event_timestamp;