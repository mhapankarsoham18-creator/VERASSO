-- Migration 018: Seasonal Challenges & Events
-- Created: 2026-02-27
-- Description: Schema for time-boxed educational events and special rewards.
CREATE TABLE IF NOT EXISTS public.seasonal_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.event_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES public.seasonal_events(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id),
    xp_bonus INT DEFAULT 0,
    exclusive_item_id TEXT,
    -- For marketplace or profile vanity
    requirement_criteria JSONB NOT NULL,
    -- e.g. {"points": 1000}
    created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS
ALTER TABLE public.seasonal_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rewards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Events readable by all" ON public.seasonal_events FOR
SELECT USING (true);
CREATE POLICY "Rewards readable by all" ON public.event_rewards FOR
SELECT USING (true);
-- Index for expiration queries
CREATE INDEX idx_seasonal_events_active ON public.seasonal_events(start_at, end_at)
WHERE is_active = true;