-- ============================================================
-- VERASSO CONSOLIDATED FINAL MIGRATIONS (Regions 1-5 + Game State)
-- ============================================================
-- MIGRATION 030: Phase 2 Integration
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_simulation_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    sim_id TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    results JSONB DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}',
    completed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public.user_lab_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    lab_id UUID REFERENCES public.labs(id) ON DELETE CASCADE NOT NULL,
    current_step INTEGER DEFAULT 1,
    progress_data JSONB DEFAULT '{}',
    status TEXT CHECK (
        status IN ('started', 'in_progress', 'completed')
    ) DEFAULT 'started',
    last_active_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, lab_id)
);
CREATE TABLE IF NOT EXISTS public.codedex_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    lesson_id TEXT NOT NULL,
    code_snippet TEXT,
    is_passing BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.user_simulation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_lab_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.codedex_history ENABLE ROW LEVEL SECURITY;
-- Migration 031: Codemaster Odyssey Save State
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.codemaster_saves (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    fragments INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    health DOUBLE PRECISION DEFAULT 100.0,
    "maxHealth" DOUBLE PRECISION DEFAULT 100.0,
    "currentRegion" INTEGER DEFAULT 1,
    "arcIndex" INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.codemaster_saves ENABLE ROW LEVEL SECURITY;
-- Policies for MIGRATION 030 & 031
DO $$ BEGIN -- Simulation Results Policies
IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE policyname = 'Users can view their own sim results'
) THEN CREATE POLICY "Users can view their own sim results" ON public.user_simulation_results FOR
SELECT USING (auth.uid() = user_id);
END IF;
IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE policyname = 'Users can insert their own sim results'
) THEN CREATE POLICY "Users can insert their own sim results" ON public.user_simulation_results FOR
INSERT WITH CHECK (auth.uid() = user_id);
END IF;
-- Lab Progress Policies
IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE policyname = 'Users can manage their own lab progress'
) THEN CREATE POLICY "Users can manage their own lab progress" ON public.user_lab_progress FOR ALL USING (auth.uid() = user_id);
END IF;
-- CodeMaster Saves Policies
IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE policyname = 'Users can view their own game saves'
) THEN CREATE POLICY "Users can view their own game saves" ON public.codemaster_saves FOR
SELECT USING (auth.uid() = user_id);
END IF;
IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE policyname = 'Users can upsert their own game saves'
) THEN CREATE POLICY "Users can upsert their own game saves" ON public.codemaster_saves FOR ALL USING (auth.uid() = user_id);
END IF;
END $$;
-- RPC for Simulation Analytics
CREATE OR REPLACE FUNCTION get_user_sim_analytics(p_user_id UUID) RETURNS JSONB AS $$
DECLARE result JSONB;
BEGIN
SELECT jsonb_build_object(
        'total_sims',
        count(*),
        'unique_sims',
        count(DISTINCT sim_id),
        'recent_sims',
        (
            SELECT jsonb_agg(sub)
            FROM (
                    SELECT sim_id,
                        completed_at
                    FROM public.user_simulation_results
                    WHERE user_id = p_user_id
                    ORDER BY completed_at DESC
                    LIMIT 5
                ) sub
        )
    ) INTO result
FROM public.user_simulation_results
WHERE user_id = p_user_id;
RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;