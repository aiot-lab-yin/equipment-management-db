-- sql/01_schema.sql
-- Based on: docs/05_physical_design.md (MySQL 8.x / InnoDB physical design)
-- Key decisions reflected here:
--   - NOT NULL policy: equipment.project_id/location_id/manager_id required; equipment.user_id nullable
--   - Reference tables: equipment_type_reference, equipment_status_reference (name NOT NULL)
--   - History generation: Approach A (equipment INSERT/UPDATE => equipment_events auto insert)
--   - Enforcement: session variables @actor_id and @event_type required (BEFORE UPDATE trigger)
--   - Indexes/FKs: follow physical design (FK constraints + search-oriented indexes)
-- Equipment Management DB Schema (MySQL 8.x / InnoDB)
-- Approach A: equipment INSERT/UPDATE -> auto INSERT equipment_events
-- Requires: SET @actor_id, SET @event_type before INSERT/UPDATE

SET NAMES utf8mb4;
SET time_zone = '+00:00';

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS equipment_events;
DROP TABLE IF EXISTS equipment_identifiers;
DROP TABLE IF EXISTS equipment;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS vendors;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS people;
DROP TABLE IF EXISTS equipment_status_reference;
DROP TABLE IF EXISTS equipment_type_reference;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE equipment_type_reference (
  code VARCHAR(32) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  PRIMARY KEY (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE equipment_status_reference (
  code VARCHAR(32) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  is_usable TINYINT(1) NOT NULL,
  is_terminal TINYINT(1) NOT NULL,
  PRIMARY KEY (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE people (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_name VARCHAR(64) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  mobile VARCHAR(32) NOT NULL,
  affiliation VARCHAR(255) NOT NULL,
  position VARCHAR(255) NOT NULL,
  role VARCHAR(32) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT uq_people_user_name UNIQUE (user_name),
  CONSTRAINT uq_people_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE projects (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_no VARCHAR(64) NOT NULL,
  name VARCHAR(255) NOT NULL,
  short_name VARCHAR(64) NOT NULL,
  programe_name VARCHAR(255) NOT NULL,
  funder VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  representative_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(32) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT uq_projects_project_no UNIQUE (project_no),
  CONSTRAINT fk_projects_representative FOREIGN KEY (representative_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE locations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vendors (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  contact_name VARCHAR(255) NOT NULL,
  phone VARCHAR(32) NOT NULL,
  email VARCHAR(255) NOT NULL,
  address VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purchases (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  vendor_id BIGINT UNSIGNED NOT NULL,
  order_date DATE NOT NULL,
  delivery_date DATE NOT NULL,
  purchase_date DATE NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  note TEXT NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_purchases_vendor FOREIGN KEY (vendor_id)
    REFERENCES vendors(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  INDEX idx_purchases_vendor (vendor_id),
  INDEX idx_purchases_purchase_date (purchase_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE equipment (
  equipment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  model VARCHAR(255) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit VARCHAR(32) NOT NULL,
  equipment_type_code VARCHAR(32) NOT NULL,
  status_code VARCHAR(32) NOT NULL,
  purchase_id BIGINT UNSIGNED NULL,
  project_id BIGINT UNSIGNED NOT NULL,
  location_id BIGINT UNSIGNED NOT NULL,
  manager_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (equipment_id),
  CONSTRAINT fk_equipment_type FOREIGN KEY (equipment_type_code)
    REFERENCES equipment_type_reference(code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_status FOREIGN KEY (status_code)
    REFERENCES equipment_status_reference(code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_purchase FOREIGN KEY (purchase_id)
    REFERENCES purchases(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_project FOREIGN KEY (project_id)
    REFERENCES projects(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_location FOREIGN KEY (location_id)
    REFERENCES locations(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_manager FOREIGN KEY (manager_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_equipment_user FOREIGN KEY (user_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  INDEX idx_equipment_status (status_code),
  INDEX idx_equipment_type (equipment_type_code),
  INDEX idx_equipment_project (project_id),
  INDEX idx_equipment_location (location_id),
  INDEX idx_equipment_manager (manager_id),
  INDEX idx_equipment_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE equipment_identifiers (
  equipment_id BIGINT UNSIGNED NOT NULL,
  university_id VARCHAR(64) NOT NULL,
  funding_id VARCHAR(64) NOT NULL,
  PRIMARY KEY (equipment_id),
  CONSTRAINT uq_equipment_identifiers_university_id UNIQUE (university_id),
  CONSTRAINT uq_equipment_identifiers_funding_id UNIQUE (funding_id),
  CONSTRAINT fk_identifiers_equipment FOREIGN KEY (equipment_id)
    REFERENCES equipment(equipment_id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE equipment_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  equipment_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  from_status_code VARCHAR(32) NOT NULL,
  to_status_code VARCHAR(32) NOT NULL,
  from_user_id BIGINT UNSIGNED NULL,
  to_user_id BIGINT UNSIGNED NULL,
  from_manager_id BIGINT UNSIGNED NOT NULL,
  to_manager_id BIGINT UNSIGNED NOT NULL,
  loan_to_id BIGINT UNSIGNED NULL,
  return_to_id BIGINT UNSIGNED NULL,
  actor_id BIGINT UNSIGNED NOT NULL,
  event_timestamp DATETIME NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_events_equipment FOREIGN KEY (equipment_id)
    REFERENCES equipment(equipment_id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_from_status FOREIGN KEY (from_status_code)
    REFERENCES equipment_status_reference(code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_to_status FOREIGN KEY (to_status_code)
    REFERENCES equipment_status_reference(code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_from_user FOREIGN KEY (from_user_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_to_user FOREIGN KEY (to_user_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_from_manager FOREIGN KEY (from_manager_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_to_manager FOREIGN KEY (to_manager_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_loan_to FOREIGN KEY (loan_to_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_return_to FOREIGN KEY (return_to_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  CONSTRAINT fk_events_actor FOREIGN KEY (actor_id)
    REFERENCES people(id)
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
  INDEX idx_events_equipment_time (equipment_id, event_timestamp),
  INDEX idx_events_actor_time (actor_id, event_timestamp),
  INDEX idx_events_to_status_time (to_status_code, event_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TRIGGER IF EXISTS trg_equipment_before_insert;
DROP TRIGGER IF EXISTS trg_equipment_after_insert;
DROP TRIGGER IF EXISTS trg_equipment_before_update;
DROP TRIGGER IF EXISTS trg_equipment_after_update;

DELIMITER $$

CREATE TRIGGER trg_equipment_before_insert
BEFORE INSERT ON equipment
FOR EACH ROW
BEGIN
  IF @actor_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Missing session variable: @actor_id (people.id)';
  END IF;

  IF @event_type IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Missing session variable: @event_type';
  END IF;
END$$

CREATE TRIGGER trg_equipment_after_insert
AFTER INSERT ON equipment
FOR EACH ROW
BEGIN
  INSERT INTO equipment_events (
    equipment_id,
    event_type,
    from_status_code,
    to_status_code,
    from_user_id,
    to_user_id,
    from_manager_id,
    to_manager_id,
    actor_id,
    event_timestamp
  ) VALUES (
    NEW.equipment_id,
    @event_type,
    NEW.status_code,
    NEW.status_code,
    NULL,
    NEW.user_id,
    NEW.manager_id,
    NEW.manager_id,
    @actor_id,
    NOW()
  );
END$$

CREATE TRIGGER trg_equipment_before_update
BEFORE UPDATE ON equipment
FOR EACH ROW
BEGIN
  DECLARE v_old_terminal TINYINT(1);
  DECLARE v_new_terminal TINYINT(1);

  -- Require actor/event context
  IF @actor_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Missing session variable: @actor_id (people.id)';
  END IF;

  IF @event_type IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Missing session variable: @event_type';
  END IF;

  -- Terminal status lock (do not allow any updates once terminal)
  SELECT is_terminal INTO v_old_terminal
  FROM equipment_status_reference
  WHERE code = OLD.status_code;

  IF v_old_terminal = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Terminal equipment cannot be updated (discarded/returned_to_funder, etc.)';
  END IF;

  -- Enforce event_type <-> target terminal status consistency
  IF NEW.status_code = 'discarded' AND @event_type <> 'discard' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'To set status=discarded, @event_type must be discard';
  END IF;

  IF NEW.status_code = 'returned_to_funder' AND @event_type <> 'return_to_funder' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'To set status=returned_to_funder, @event_type must be return_to_funder';
  END IF;

  -- Minimal forbidden transitions
  IF OLD.status_code = 'loaned' AND NEW.status_code = 'loaned' AND @event_type = 'loan' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Double-loan is not allowed (already loaned)';
  END IF;

  IF OLD.status_code = 'loaned' AND (NEW.status_code = 'discarded' OR NEW.status_code = 'returned_to_funder') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cannot discard/return_to_funder while loaned';
  END IF;

  -- Loan / return destination must be provided (recorded in equipment_events)
  IF @event_type = 'loan' THEN
    IF @loan_to_id IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Missing session variable: @loan_to_id (people.id) for loan';
    END IF;
  END IF;

  IF @event_type = 'return' THEN
    IF @return_to_id IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Missing session variable: @return_to_id (people.id) for return';
    END IF;
  END IF;

  -- Optional: prevent setting a terminal status via non-terminal event_type
  SELECT is_terminal INTO v_new_terminal
  FROM equipment_status_reference
  WHERE code = NEW.status_code;

  IF v_new_terminal = 1 AND NEW.status_code NOT IN ('discarded', 'returned_to_funder') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Terminal status code is not allowed';
  END IF;
END$$

CREATE TRIGGER trg_equipment_after_update
AFTER UPDATE ON equipment
FOR EACH ROW
BEGIN
  IF (OLD.status_code <> NEW.status_code)
     OR (OLD.user_id <=> NEW.user_id) = 0
     OR (OLD.manager_id <> NEW.manager_id)
     OR (OLD.project_id <> NEW.project_id)
     OR (OLD.location_id <> NEW.location_id) THEN

    INSERT INTO equipment_events (
      equipment_id,
      event_type,
      from_status_code,
      to_status_code,
      from_user_id,
      to_user_id,
      from_manager_id,
      to_manager_id,
      loan_to_id,
      return_to_id,
      actor_id,
      event_timestamp
    ) VALUES (
      NEW.equipment_id,
      @event_type,
      OLD.status_code,
      NEW.status_code,
      OLD.user_id,
      NEW.user_id,
      OLD.manager_id,
      NEW.manager_id,
      CASE WHEN @event_type = 'loan' THEN @loan_to_id ELSE NULL END,
      CASE WHEN @event_type = 'return' THEN @return_to_id ELSE NULL END,
      @actor_id,
      NOW()
    );
  END IF;
END$$

DELIMITER ;