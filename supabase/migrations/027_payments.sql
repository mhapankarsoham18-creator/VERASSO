-- Create payments table
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount INTEGER NOT NULL,
    -- in smallest currency unit
    currency TEXT DEFAULT 'INR',
    status TEXT DEFAULT 'pending',
    -- pending, captured, failed, refunded
    sdk_order_id TEXT UNIQUE,
    -- Razorpay order_id
    sdk_payment_id TEXT,
    -- Razorpay payment_id
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
-- Enable RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
-- RLS Policies
CREATE POLICY "Users can view their own payments" ON public.payments FOR
SELECT USING (auth.uid() = user_id);
-- RPC: Create Payment Order
CREATE OR REPLACE FUNCTION public.create_payment_order(
        amount INTEGER,
        currency TEXT,
        metadata JSONB
    ) RETURNS JSONB AS $$
DECLARE new_order_id UUID;
v_user_id UUID;
BEGIN v_user_id := auth.uid();
INSERT INTO public.payments (user_id, amount, currency, metadata)
VALUES (v_user_id, amount, currency, metadata)
RETURNING id INTO new_order_id;
-- In a real production scenario, you would call Razorpay's API from an Edge Function
-- and return the real sdk_order_id here. 
-- For this prototype/MVP, we'll return a placeholder order_id if not calling an Edge Function.
-- However, the Flutter SDK will expect a real order_id from Razorpay.
-- So we return the internal ID which the Edge Function would eventually link.
RETURN jsonb_build_object(
    'order_id',
    new_order_id,
    'sdk_order_id',
    'order_' || extensions.uuid_generate_v4() -- Mock for now
);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- RPC: Verify Payment
CREATE OR REPLACE FUNCTION public.verify_payment(
        payment_id TEXT,
        order_id TEXT,
        signature TEXT
    ) RETURNS BOOLEAN AS $$ BEGIN -- This RPC should verify the signature using Razorpay secret.
    -- In a real scenario, this would be handled in an Edge Function.
    -- For now, we update the status in the DB.
UPDATE public.payments
SET status = 'captured',
    sdk_payment_id = payment_id,
    updated_at = now()
WHERE sdk_order_id = order_id
    OR id::text = order_id;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;