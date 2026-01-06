-- tests/03_loan_return.sql
SET NAMES utf8mb4;

SELECT id INTO @uid_admin FROM people WHERE role='admin' LIMIT 1;
SELECT id INTO @uid_member FROM people WHERE role='member' LIMIT 1;
SELECT id INTO @uid_viewer FROM people WHERE role='viewer' LIMIT 1;

INSERT INTO locations(name,address) VALUES ('LoanLab','Campus');
SET @loc := LAST_INSERT_ID();

INSERT INTO vendors(name,contact_name,phone,email,address)
VALUES ('LoanVendor','Ken','222','loan@test','Tokyo');
SET @vid := LAST_INSERT_ID();

INSERT INTO purchases(vendor_id,order_date,delivery_date,purchase_date,price,note)
VALUES (@vid,CURDATE(),CURDATE(),CURDATE(),12000,'loan');
SET @purchase := LAST_INSERT_ID();

INSERT INTO projects(project_no,name,short_name,programe_name,funder,start_date,end_date,representative_id,status)
VALUES ('P-LOAN','Loan Project','LP','Prog','Funder',CURDATE(),CURDATE(),@uid_admin,'ongoing');
SET @pid := LAST_INSERT_ID();

SET @actor_id := @uid_admin;
SET @event_type := 'register';

INSERT INTO equipment(name,model,quantity,unit,equipment_type_code,status_code,
                      purchase_id,project_id,location_id,manager_id,user_id)
VALUES ('LoanItem','L1',1,'pcs','asset','in_stock',
        @purchase,@pid,@loc,@uid_admin,NULL);
SET @eid := LAST_INSERT_ID();

-- loan
SET @actor_id := @uid_member;
SET @event_type := 'loan';
SET @loan_to_id := @uid_viewer;
UPDATE equipment SET status_code='loaned' WHERE equipment_id=@eid;

-- return
SET @actor_id := @uid_member;
SET @event_type := 'return';
SET @return_to_id := @uid_admin;
UPDATE equipment SET status_code='in_stock' WHERE equipment_id=@eid;

SELECT * FROM equipment_events WHERE equipment_id=@eid ORDER BY event_timestamp;