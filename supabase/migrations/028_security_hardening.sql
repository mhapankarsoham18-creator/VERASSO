-- ============================================================
-- 028: SECURITY HARDENING
-- Data Isolation & RLS Tightening
-- ============================================================
-- 1. Create Private Wallets Table
-- This isolates financial data from the public profile view
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance DECIMAL(12, 2) DEFAULT 0.00 NOT NULL,
    currency TEXT DEFAULT 'INR',
    updated_at TIMESTAMPTZ DEFAULT now()
);
-- Migrating existing data from profiles (if any)
DO $$ BEGIN IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'profiles'
        AND column_name = 'earnings_balance'
) THEN
INSERT INTO public.wallets (user_id, balance)
SELECT id,
    earnings_balance
FROM public.profiles ON CONFLICT (user_id) DO
UPDATE
SET balance = EXCLUDED.balance;
-- Remove sensitive field from public profiles
ALTER TABLE public.profiles DROP COLUMN earnings_balance;
END IF;
END $$;
-- 2. Configure Wallet RLS
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only view their own wallet" ON public.wallets FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service role can manage all wallets" ON public.wallets FOR ALL USING (auth.jwt()->>'role' = 'service_role');
-- 3. Tighten Profiles RLS
-- Existing policy allows public view if NOT is_private. 
-- We'll keep it for now as we removed the sensitive column.
-- 4. Tighten Messaging RLS
DROP POLICY IF EXISTS "Update own messages" ON public.messages;
CREATE POLICY "Receiver can mark as read" ON public.messages FOR
UPDATE USING (auth.uid() = receiver_id) WITH CHECK (auth.uid() = receiver_id);
-- 5. Tighten Analytics RLS
DROP POLICY IF EXISTS "Users can view own events" ON public.analytics_events;
CREATE POLICY "Analytics strictly private" ON public.analytics_events FOR
SELECT USING (auth.uid() = user_id);
-- 6. Trigger to auto-create wallet on profile creation
CREATE OR REPLACE FUNCTION public.handle_new_wallet() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO public.wallets (user_id)
VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_profile_created_wallet
AFTER
INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_new_wallet();
-- 7. Trigger to keep wallet balance in sync with transactions
CREATE OR REPLACE FUNCTION public.handle_transaction_sync() RETURNS TRIGGER AS $$ BEGIN
UPDATE public.wallets
SET balance = balance + NEW.amount,
    updated_at = now()
WHERE user_id = NEW.user_id;
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_transaction_recorded_sync
AFTER
INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.handle_transaction_sync();
-- 8. RPC: Get User Balance (Unified)
CREATE OR REPLACE FUNCTION public.get_user_balance(user_id UUID) RETURNS DECIMAL AS $$
DECLARE v_balance DECIMAL;
BEGIN
SELECT balance INTO v_balance
FROM public.wallets
WHERE wallets.user_id = $1;
RETURN COALESCE(v_balance, 0.00);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;