-- SQL for Secure Webhook Handlers (Phase 4)
-- This file defines the infrastructure for processing Stripe webhooks securely via Supabase Edge Functions.
-- 1. Table for tracking Stripe Events (Idempotency)
CREATE TABLE IF NOT EXISTS public.stripe_webhook_events (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    -- pending, processed, failed
    payload JSONB,
    error TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- 2. Procedure for handling successful payments
CREATE OR REPLACE FUNCTION public.handle_stripe_checkout_completed(payload JSONB) RETURNS VOID AS $$
DECLARE v_user_id UUID;
v_amount INT;
v_job_id TEXT;
BEGIN v_user_id := (
    payload->'data'->'object'->'metadata'->>'user_id'
)::UUID;
v_amount := (payload->'data'->'object'->'amount_total')::INT;
v_job_id := payload->'data'->'object'->'metadata'->>'job_id';
-- Record the transaction
INSERT INTO public.talent_transactions (user_id, amount, status, metadata)
VALUES (
        v_user_id,
        v_amount / 100.0,
        'completed',
        jsonb_build_object(
            'job_id',
            v_job_id,
            'stripe_id',
            payload->'data'->'object'->>'id'
        )
    );
-- Additional logic (e.g., notify user, unlock content)
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;