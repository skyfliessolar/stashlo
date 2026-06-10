-- STASHLO COMPLETE SCHEMA MIGRATION v3
-- Safe to run multiple times - uses IF NOT EXISTS

-- 1. users (customer profiles)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE,
  name text,
  phone text,
  total_points integer DEFAULT 0,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_points integer DEFAULT 0;

-- 2. merchants
CREATE TABLE IF NOT EXISTS merchants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  shop_id text UNIQUE,
  email text UNIQUE,
  password_hash text,
  category text DEFAULT 'other',
  address text,
  open_hours text,
  logo_emoji text DEFAULT '🏪',
  logo_url text,
  loyalty_type text DEFAULT 'points',
  loyalty_value numeric DEFAULT 1,
  loyalty_threshold integer DEFAULT 100,
  lat numeric,
  lng numeric,
  active boolean DEFAULT true,
  delivery_enabled boolean DEFAULT false,
  delivery_fee numeric DEFAULT 0,
  min_order numeric DEFAULT 0,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS lat numeric;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS lng numeric;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS delivery_enabled boolean DEFAULT false;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS delivery_fee numeric DEFAULT 0;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS min_order numeric DEFAULT 0;

-- 3. cards (customer loyalty cards)
CREATE TABLE IF NOT EXISTS cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  card_id text NOT NULL,
  name text,
  shop_name text,
  emoji text DEFAULT '🛍️',
  color text DEFAULT '#6366F1',
  type text DEFAULT 'local',
  merchant_id uuid,
  points integer DEFAULT 0,
  threshold integer DEFAULT 100,
  card_number text,
  card_holder text,
  store_location text,
  visit_count integer DEFAULT 0,
  total_spend numeric DEFAULT 0,
  rewards_redeemed integer DEFAULT 0,
  latitude numeric,
  longitude numeric,
  added_at bigint DEFAULT (extract(epoch from now())*1000)::bigint,
  UNIQUE(user_id, card_id)
);
ALTER TABLE cards ADD COLUMN IF NOT EXISTS card_number text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS card_holder text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS store_location text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS latitude numeric;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS longitude numeric;

-- 4. card_locations (geofencing)
CREATE TABLE IF NOT EXISTS card_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id text NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  label text,
  radius integer DEFAULT 200,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 5. products
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  price numeric NOT NULL DEFAULT 0,
  emoji text DEFAULT '🛍️',
  category text DEFAULT 'other',
  collect boolean DEFAULT true,
  delivery boolean DEFAULT false,
  active boolean DEFAULT true,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 6. orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  merchant_id uuid REFERENCES merchants(id),
  product_id uuid REFERENCES products(id),
  product_name text,
  product_emoji text DEFAULT '📦',
  quantity integer DEFAULT 1,
  total numeric DEFAULT 0,
  type text DEFAULT 'collect',
  status text DEFAULT 'pending',
  delivery_address text,
  collect_time text,
  note text,
  merchant_note text,
  tracking_status text,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS product_emoji text DEFAULT '📦';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS merchant_note text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_status text;

-- 7. chats (order chats)
CREATE TABLE IF NOT EXISTS chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id text NOT NULL,
  sender_id text,
  sender_role text DEFAULT 'customer',
  sender_name text,
  message text NOT NULL,
  order_id uuid,
  read_by_other boolean DEFAULT false,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 8. support_chats
CREATE TABLE IF NOT EXISTS support_chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid,
  customer_email text,
  sender_role text DEFAULT 'customer',
  sender_name text,
  message text NOT NULL,
  read_by_admin boolean DEFAULT false,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);
ALTER TABLE support_chats ADD COLUMN IF NOT EXISTS read_by_admin boolean DEFAULT false;

-- 9. notifications (merchant → customer)
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  title text,
  body text,
  image_url text,
  sent_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 10. broadcasts (admin → all)
CREATE TABLE IF NOT EXISTS broadcasts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text,
  image_url text,
  audience text DEFAULT 'all',
  sent_by text,
  sent_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);
ALTER TABLE broadcasts ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE broadcasts ADD COLUMN IF NOT EXISTS audience text DEFAULT 'all';

-- 11. jobs
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  merchant_name text,
  title text NOT NULL,
  job_type text DEFAULT 'Part-time',
  salary text,
  description text,
  contact_email text,
  location text,
  active boolean DEFAULT true,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 12. rewards (redeemable offers)
CREATE TABLE IF NOT EXISTS rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  emoji text DEFAULT '🎁',
  points_cost integer DEFAULT 100,
  active boolean DEFAULT true,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 13. reward_redemptions
CREATE TABLE IF NOT EXISTS reward_redemptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  reward_id uuid REFERENCES rewards(id),
  points_used integer DEFAULT 0,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 14. payment_cards (customer payment methods - no CVV stored)
CREATE TABLE IF NOT EXISTS payment_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  holder text,
  last4 text,
  network text DEFAULT 'other',
  expiry text,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint,
  UNIQUE(user_id, last4)
);

-- 15. merchant_billing (admin charges merchants)
CREATE TABLE IF NOT EXISTS merchant_billing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  merchant_name text,
  amount numeric DEFAULT 0,
  description text,
  status text DEFAULT 'pending',
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 16. merchant_customers (merchant's own customer records for till)
CREATE TABLE IF NOT EXISTS merchant_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  phone text NOT NULL,
  name text DEFAULT 'Customer',
  points integer DEFAULT 0,
  visit_count integer DEFAULT 0,
  total_spend numeric DEFAULT 0,
  last_updated bigint DEFAULT (extract(epoch from now())*1000)::bigint,
  UNIQUE(merchant_id, phone)
);

-- 17. transactions (till records)
CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  phone text,
  amount numeric DEFAULT 0,
  points_added integer DEFAULT 0,
  type text DEFAULT 'purchase',
  timestamp bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 18. stashlo_products (Stashlo store)
CREATE TABLE IF NOT EXISTS stashlo_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price numeric DEFAULT 0,
  emoji text DEFAULT '🛍️',
  category text DEFAULT 'other',
  collect boolean DEFAULT true,
  delivery boolean DEFAULT false,
  active boolean DEFAULT true,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- 19. customer_rewards (admin gives points to customer)
CREATE TABLE IF NOT EXISTS customer_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid,
  customer_email text,
  given_by_email text,
  points integer DEFAULT 0,
  description text,
  redeemed boolean DEFAULT false,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- RLS POLICIES - Enable and set permissive for app use
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_billing ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE stashlo_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_rewards ENABLE ROW LEVEL SECURITY;

-- DROP existing policies to recreate cleanly
DO $$ DECLARE
  r record;
BEGIN
  FOR r IN SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- PERMISSIVE RLS - Allow anon + authenticated for all tables
-- (Admin uses service role key which bypasses RLS entirely)
CREATE POLICY "allow_all_users" ON users FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_cards" ON cards FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_card_locations" ON card_locations FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_merchants" ON merchants FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_products" ON products FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_orders" ON orders FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_chats" ON chats FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_support_chats" ON support_chats FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_notifications" ON notifications FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_broadcasts" ON broadcasts FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_jobs" ON jobs FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_rewards" ON rewards FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_reward_redemptions" ON reward_redemptions FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_payment_cards" ON payment_cards FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_merchant_billing" ON merchant_billing FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_merchant_customers" ON merchant_customers FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_transactions" ON transactions FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_stashlo_products" ON stashlo_products FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_customer_rewards" ON customer_rewards FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Storage bucket for images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('stashlo-images', 'stashlo-images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 5242880;

-- Storage policy
DROP POLICY IF EXISTS "stashlo images public" ON storage.objects;
CREATE POLICY "stashlo images public" ON storage.objects FOR ALL TO anon, authenticated 
USING (bucket_id = 'stashlo-images') WITH CHECK (bucket_id = 'stashlo-images');


-- ===== v4 UPGRADE: FinTech features =====

-- Short loyalty ID on users
ALTER TABLE users ADD COLUMN IF NOT EXISTS loyalty_id text UNIQUE;

-- Merchant status controls (admin super app)
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS suspended boolean DEFAULT false;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS restricted boolean DEFAULT false;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS approved boolean DEFAULT true;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS bank_account text;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS bank_sort_code text;

-- Customer bank settings (admin editable)
ALTER TABLE users ADD COLUMN IF NOT EXISTS bank_account text;

-- Receipts (permanent customer storage)
CREATE TABLE IF NOT EXISTS receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  merchant_name text,
  order_id uuid,
  items text,
  total numeric DEFAULT 0,
  receipt_no text,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- Job unlocks (pay £1/£5 -> admin approval -> contact revealed)
CREATE TABLE IF NOT EXISTS job_unlocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id) ON DELETE CASCADE,
  plan text DEFAULT '1',
  amount numeric DEFAULT 1,
  status text DEFAULT 'pending_approval',
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint,
  UNIQUE(user_id, job_id)
);

-- Merchant-created rewards (e.g. free juice for 100 pts)
CREATE TABLE IF NOT EXISTS merchant_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id uuid REFERENCES merchants(id) ON DELETE CASCADE,
  name text NOT NULL,
  emoji text DEFAULT '🎁',
  points_cost integer DEFAULT 100,
  active boolean DEFAULT true,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- Audit logs (all admin actions)
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_email text,
  action text NOT NULL,
  target text,
  details text,
  created_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);

-- RLS for new tables
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow_all_receipts" ON receipts FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_job_unlocks" ON job_unlocks FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_merchant_rewards" ON merchant_rewards FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_audit_logs" ON audit_logs FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ===== v5: 3D THEME ENGINE (admin-controlled, live-applies to all apps) =====
CREATE TABLE IF NOT EXISTS app_settings (
  key text PRIMARY KEY,
  value text,
  updated_at bigint DEFAULT (extract(epoch from now())*1000)::bigint
);
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_app_settings" ON app_settings;
CREATE POLICY "allow_all_app_settings" ON app_settings FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Default 3D theme
INSERT INTO app_settings (key, value) VALUES ('theme3d',
'{"enabled":true,"depth":1,"tilt":true,"orbs":true,"glass":true,"flip":true,"primary":"#6366F1","accent":"#8B5CF6","glow":"#22d3ee"}')
ON CONFLICT (key) DO NOTHING;
