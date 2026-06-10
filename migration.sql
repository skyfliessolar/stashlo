-- ============================================================
-- STASHLO COMPLETE SCHEMA MIGRATION v5.1 (type-safe)
-- No foreign-key constraints; all ID columns are text so it
-- works regardless of existing column types. Safe to re-run.
-- ============================================================

-- 1. users
CREATE TABLE IF NOT EXISTS users (
  id text PRIMARY KEY,
  email text UNIQUE,
  name text,
  phone text,
  total_points integer DEFAULT 0,
  created_at bigint
);
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_points integer DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS loyalty_id text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bank_account text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS name text;

-- 2. merchants
CREATE TABLE IF NOT EXISTS merchants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  shop_id text,
  email text,
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
  created_at bigint
);
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS lat numeric;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS lng numeric;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS delivery_enabled boolean DEFAULT false;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS delivery_fee numeric DEFAULT 0;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS min_order numeric DEFAULT 0;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS suspended boolean DEFAULT false;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS restricted boolean DEFAULT false;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS approved boolean DEFAULT true;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS bank_account text;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS bank_sort_code text;

-- 3. cards
CREATE TABLE IF NOT EXISTS cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  card_id text,
  name text,
  shop_name text,
  emoji text DEFAULT '🛍️',
  color text DEFAULT '#6366F1',
  type text DEFAULT 'local',
  merchant_id text,
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
  added_at bigint,
  UNIQUE(user_id, card_id)
);
ALTER TABLE cards ADD COLUMN IF NOT EXISTS card_number text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS card_holder text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS store_location text;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS latitude numeric;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS longitude numeric;

-- 4. card_locations
CREATE TABLE IF NOT EXISTS card_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id text,
  user_id text,
  latitude numeric,
  longitude numeric,
  label text,
  radius integer DEFAULT 200,
  created_at bigint
);

-- 5. products
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  name text,
  description text,
  price numeric DEFAULT 0,
  emoji text DEFAULT '🛍️',
  category text DEFAULT 'other',
  collect boolean DEFAULT true,
  delivery boolean DEFAULT false,
  active boolean DEFAULT true,
  created_at bigint
);

-- 6. orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  merchant_id text,
  product_id text,
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
  created_at bigint
);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS product_emoji text DEFAULT '📦';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS merchant_note text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_status text;

-- 7. chats
CREATE TABLE IF NOT EXISTS chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id text,
  sender_id text,
  sender_role text DEFAULT 'customer',
  sender_name text,
  message text,
  order_id text,
  read_by_other boolean DEFAULT false,
  created_at bigint
);

-- 8. support_chats
CREATE TABLE IF NOT EXISTS support_chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id text,
  customer_email text,
  sender_role text DEFAULT 'customer',
  sender_name text,
  message text,
  read_by_admin boolean DEFAULT false,
  created_at bigint
);
ALTER TABLE support_chats ADD COLUMN IF NOT EXISTS read_by_admin boolean DEFAULT false;

-- 9. notifications
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  title text,
  body text,
  image_url text,
  sent_at bigint
);

-- 10. broadcasts
CREATE TABLE IF NOT EXISTS broadcasts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text,
  body text,
  image_url text,
  audience text DEFAULT 'all',
  sent_by text,
  sent_at bigint
);
ALTER TABLE broadcasts ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE broadcasts ADD COLUMN IF NOT EXISTS audience text DEFAULT 'all';

-- 11. jobs
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  merchant_name text,
  title text,
  job_type text DEFAULT 'Part-time',
  salary text,
  description text,
  contact_email text,
  location text,
  active boolean DEFAULT true,
  created_at bigint
);

-- 12. rewards
CREATE TABLE IF NOT EXISTS rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  description text,
  emoji text DEFAULT '🎁',
  points_cost integer DEFAULT 100,
  active boolean DEFAULT true,
  created_at bigint
);

-- 13. reward_redemptions (user_id as text — fixes your error)
CREATE TABLE IF NOT EXISTS reward_redemptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  reward_id text,
  points_used integer DEFAULT 0,
  created_at bigint
);

-- 14. payment_cards
CREATE TABLE IF NOT EXISTS payment_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  holder text,
  last4 text,
  network text DEFAULT 'other',
  expiry text,
  created_at bigint,
  UNIQUE(user_id, last4)
);

-- 15. merchant_billing
CREATE TABLE IF NOT EXISTS merchant_billing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  merchant_name text,
  amount numeric DEFAULT 0,
  description text,
  status text DEFAULT 'pending',
  created_at bigint
);

-- 16. merchant_customers
CREATE TABLE IF NOT EXISTS merchant_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  phone text,
  name text DEFAULT 'Customer',
  points integer DEFAULT 0,
  visit_count integer DEFAULT 0,
  total_spend numeric DEFAULT 0,
  last_updated bigint,
  UNIQUE(merchant_id, phone)
);

-- 17. transactions
CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  phone text,
  amount numeric DEFAULT 0,
  points_added integer DEFAULT 0,
  type text DEFAULT 'purchase',
  timestamp bigint
);

-- 18. stashlo_products
CREATE TABLE IF NOT EXISTS stashlo_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  description text,
  price numeric DEFAULT 0,
  emoji text DEFAULT '🛍️',
  category text DEFAULT 'other',
  collect boolean DEFAULT true,
  delivery boolean DEFAULT false,
  active boolean DEFAULT true,
  created_at bigint
);

-- 19. customer_rewards
CREATE TABLE IF NOT EXISTS customer_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id text,
  customer_email text,
  given_by_email text,
  points integer DEFAULT 0,
  description text,
  redeemed boolean DEFAULT false,
  created_at bigint
);

-- 20. receipts
CREATE TABLE IF NOT EXISTS receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  merchant_name text,
  order_id text,
  items text,
  total numeric DEFAULT 0,
  receipt_no text,
  image_url text,
  created_at bigint
);
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS image_url text;

-- 21. job_unlocks
CREATE TABLE IF NOT EXISTS job_unlocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text,
  job_id text,
  plan text DEFAULT '1',
  amount numeric DEFAULT 1,
  status text DEFAULT 'pending_approval',
  created_at bigint,
  UNIQUE(user_id, job_id)
);

-- 22. merchant_rewards
CREATE TABLE IF NOT EXISTS merchant_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id text,
  name text,
  emoji text DEFAULT '🎁',
  points_cost integer DEFAULT 100,
  active boolean DEFAULT true,
  created_at bigint
);

-- 23. audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_email text,
  action text,
  target text,
  details text,
  created_at bigint
);

-- 24. app_settings (3D theme engine)
CREATE TABLE IF NOT EXISTS app_settings (
  key text PRIMARY KEY,
  value text,
  updated_at bigint
);

-- Default 3D theme seed
INSERT INTO app_settings (key, value) VALUES ('theme3d',
'{"enabled":true,"depth":1,"tilt":true,"orbs":true,"glass":true,"flip":true,"primary":"#6366F1","accent":"#8B5CF6","glow":"#22d3ee"}')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ============================================================
-- RLS: enable + permissive policies on every table
-- ============================================================
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','merchants','cards','card_locations','products','orders',
    'chats','support_chats','notifications','broadcasts','jobs',
    'rewards','reward_redemptions','payment_cards','merchant_billing',
    'merchant_customers','transactions','stashlo_products','customer_rewards',
    'receipts','job_unlocks','merchant_rewards','audit_logs','app_settings'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'allow_all_'||t, t);
    EXECUTE format('CREATE POLICY %I ON %I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true)', 'allow_all_'||t, t);
  END LOOP;
END $$;

-- ============================================================
-- Storage bucket (exception-safe: skipped if SQL editor lacks
-- permission — create bucket via Dashboard > Storage instead)
-- ============================================================
DO $$
BEGIN
  BEGIN
    INSERT INTO storage.buckets (id, name, public, file_size_limit)
    VALUES ('stashlo-images', 'stashlo-images', true, 5242880)
    ON CONFLICT (id) DO UPDATE SET public = true;
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'Skipped bucket creation: %', SQLERRM;
  END;
  BEGIN
    EXECUTE 'DROP POLICY IF EXISTS "stashlo images public" ON storage.objects';
    EXECUTE 'CREATE POLICY "stashlo images public" ON storage.objects FOR ALL TO anon, authenticated USING (bucket_id = ''stashlo-images'') WITH CHECK (bucket_id = ''stashlo-images'')';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'Skipped storage policy: %', SQLERRM;
  END;
END $$;

-- Verify key rows
SELECT key, left(value, 60) AS value_preview FROM app_settings;

-- v6.1: credit waitlist (future Stashlo Credit service)
CREATE TABLE IF NOT EXISTS credit_waitlist (
  user_id text PRIMARY KEY,
  email text,
  name text,
  created_at bigint
);
ALTER TABLE credit_waitlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_credit_waitlist" ON credit_waitlist;
CREATE POLICY "allow_all_credit_waitlist" ON credit_waitlist FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
