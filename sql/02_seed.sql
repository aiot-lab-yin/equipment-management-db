-- sql/02_seed.sql
-- Seed data for Equipment Management DB (MySQL 8.x)
-- Based on: docs/05_physical_design.md + sql/01_schema.sql

SET NAMES utf8mb4;



-- 安全のため、必要に応じて TRUNCATE したい場合はコメントを外す
-- ※ 外部キーがあるため順序に注意
-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE TABLE equipment_events;
-- TRUNCATE TABLE equipment_identifiers;
-- TRUNCATE TABLE equipment;
-- TRUNCATE TABLE purchases;
-- TRUNCATE TABLE vendors;
-- TRUNCATE TABLE locations;
-- TRUNCATE TABLE projects;
-- TRUNCATE TABLE people;
-- TRUNCATE TABLE equipment_status_reference;
-- TRUNCATE TABLE equipment_type_reference;
-- SET FOREIGN_KEY_CHECKS = 1;

-- =============================
-- 1) Reference data
-- =============================

INSERT INTO equipment_type_reference (code, name, description) VALUES
  ('consumable', '消耗品', '原則として箱/単位で管理し、数量で消費を扱う'),
  ('equipment',   '備品',   '研究室内で運用し、配備/貸出/返却などの状態管理を行う'),
  ('asset',       '資産',   '資産管理対象。大学/資金元の識別子を持つ場合がある');

INSERT INTO equipment_status_reference (code, name, description, is_usable, is_terminal) VALUES
  ('in_stock',           '在庫（利用可能）', '未配備。利用可能な状態', 1, 0),
  ('in_service',         '稼働中',           'どこかに設置され稼働している状態', 1, 0),
  ('assigned',           '使用中',           '学内個人に割当され、個人が管理・使用', 1, 0),
  ('loaned',             '貸出中',           '外部または学外を含む貸出中', 0, 0),
  ('broken',             '故障中',           '使用不可。復旧待ち', 0, 0),
  ('repairing',          '修理中',           '使用不可。修理作業中', 0, 0),
  ('returned_to_funder', '資金元に返却',     '資金元へ返却済み（原則運用終了）', 0, 1),
  ('discarded',          '廃棄済み',         '廃棄済み（原則として状態を戻さない）', 0, 1);

-- =============================
-- 2) People (users)
-- 役割: admin / member / viewer / guest
-- =============================

INSERT INTO people (user_name, full_name, email, mobile, affiliation, position, role) VALUES
  ('admin01',  '管理者 太郎', 'admin01@example.ac.jp',  '090-0000-0001', '情報工学研究室', '教員',   'admin'),
  ('member01', '学生 花子',   'member01@example.ac.jp', '090-0000-0002', '情報工学研究室', '学生',   'member'),
  ('viewer01', '助手 次郎',   'viewer01@example.ac.jp', '090-0000-0003', '情報工学研究室', '研究員', 'viewer'),
  ('guest01',  '外部 来客',   'guest01@example.com',    '090-0000-0004', '外部',           '来客',   'guest');

-- =============================
-- 3) Locations
-- =============================

INSERT INTO locations (name, address) VALUES
  ('研究室A（本館3F）', '本館3階 305号室'),
  ('倉庫（別館1F）',   '別館1階 倉庫');

-- =============================
-- 4) Vendors
-- =============================

INSERT INTO vendors (name, contact_name, phone, email, address) VALUES
  ('サンプル商事株式会社', '山田 担当', '03-1111-2222', 'sales@example.co.jp', '東京都千代田区1-1-1'),
  ('計測機器販売株式会社', '佐藤 担当', '03-3333-4444', 'contact@example.co.jp', '東京都台東区2-2-2');

-- =============================
-- 5) Projects
-- status: ongoing / terminated
-- representative_id は people.id を参照
-- =============================

-- representative: admin01 (id=1 を想定。環境により変わるためサブクエリで取得)
INSERT INTO projects (
  project_no, name, short_name, programe_name, funder,
  start_date, end_date, representative_id, status
) VALUES (
  'PJ-2025-001', '無線信号指紋認証プロジェクト', 'RFID-Auth', 'AI/無線融合研究プログラム', '学内研究費',
  '2025-04-01', '2026-03-31',
  (SELECT id FROM people WHERE user_name='admin01'),
  'ongoing'
);

-- =============================
-- 6) Purchases
-- vendor_id は vendors.id を参照
-- =============================

INSERT INTO purchases (vendor_id, order_date, delivery_date, purchase_date, price, note) VALUES
  ((SELECT id FROM vendors WHERE name='サンプル商事株式会社'), '2025-10-01', '2025-10-05', '2025-10-05', 120000.00, '初回導入（備品）'),
  ((SELECT id FROM vendors WHERE name='計測機器販売株式会社'), '2025-11-10', '2025-11-20', '2025-11-20', 350000.00, '計測機器（資産）');

-- =============================
-- 7) Equipment
-- project_id/location_id/manager_id は NOT NULL
-- user_id は NULL 可
-- =============================

-- (1) 備品: 研究室ルータ
INSERT INTO equipment (
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id, project_id, location_id,
  manager_id, user_id
) VALUES (
  'Wi-Fi ルータ', 'AX6000', 1, '台',
  'equipment', 'in_stock',
  (SELECT id FROM purchases ORDER BY id LIMIT 1),
  (SELECT id FROM projects WHERE project_no='PJ-2025-001'),
  (SELECT id FROM locations WHERE name='倉庫（別館1F）'),
  (SELECT id FROM people WHERE user_name='admin01'),
  NULL
);

-- (2) 資産: スペクトラムアナライザ
INSERT INTO equipment (
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id, project_id, location_id,
  manager_id, user_id
) VALUES (
  'スペクトラムアナライザ', 'SA-3GHz', 1, '台',
  'asset', 'in_service',
  (SELECT id FROM purchases ORDER BY id DESC LIMIT 1),
  (SELECT id FROM projects WHERE project_no='PJ-2025-001'),
  (SELECT id FROM locations WHERE name='研究室A（本館3F）'),
  (SELECT id FROM people WHERE user_name='admin01'),
  (SELECT id FROM people WHERE user_name='member01')
);

-- (3) 消耗品: 電池（箱単位）
INSERT INTO equipment (
  name, model, quantity, unit,
  equipment_type_code, status_code,
  purchase_id, project_id, location_id,
  manager_id, user_id
) VALUES (
  '単三電池', 'AA-Alkaline', 10, '箱',
  'consumable', 'in_stock',
  NULL,
  (SELECT id FROM projects WHERE project_no='PJ-2025-001'),
  (SELECT id FROM locations WHERE name='倉庫（別館1F）'),
  (SELECT id FROM people WHERE user_name='admin01'),
  NULL
);

-- =============================
-- 8) Equipment identifiers (for some equipment/assets)
-- equipment_id は equipment.equipment_id を参照
-- =============================

-- スペクトラムアナライザ（asset）に大学/資金元の番号を付与
INSERT INTO equipment_identifiers (equipment_id, university_id, funding_id) VALUES
  (
    (SELECT equipment_id FROM equipment WHERE name='スペクトラムアナライザ' ORDER BY equipment_id DESC LIMIT 1),
    'UNIV-INV-0001',
    'FUND-2025-0001'
  );

-- =============================
-- 9) Notes
-- - equipment_events は UPDATE トリガにより自動生成されるため、seedでは投入しない
-- - 動作確認は tests/06_transaction_rollback.sql などで実施する
-- =============================
