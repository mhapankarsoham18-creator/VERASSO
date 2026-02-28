-- ============================================================
-- VERASSO Schema — Part 30: Phase 2 Integration
-- ============================================================
-- 1. Create user_simulation_results table
-- Persists performance data from client-side sims (50+ screens)
CREATE TABLE IF NOT EXISTS public.user_simulation_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    sim_id TEXT NOT NULL,
    -- e.g. 'projectile_motion', 'molecular_builder'
    parameters JSONB DEFAULT '{}',
    -- input conditions (angle, velocity, etc.)
    results JSONB DEFAULT '{}',
    -- outcomes (distance, stability, etc.)
    performance_metrics JSONB DEFAULT '{}',
    -- for analytics
    completed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
-- 2. Create user_lab_progress table
-- Tracks granular progress in AR labs
CREATE TABLE IF NOT EXISTS public.user_lab_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    lab_id UUID REFERENCES public.labs(id) ON DELETE CASCADE NOT NULL,
    current_step INTEGER DEFAULT 1,
    progress_data JSONB DEFAULT '{}',
    -- step-specific state
    status TEXT CHECK (
        status IN ('started', 'in_progress', 'completed')
    ) DEFAULT 'started',
    last_active_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, lab_id)
);
-- 3. Create codedex_history table
-- Persists user snippets and success from CodeMaster Odyssey
CREATE TABLE IF NOT EXISTS public.codedex_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    lesson_id TEXT NOT NULL,
    code_snippet TEXT,
    is_passing BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
-- 4. Enable RLS
ALTER TABLE public.user_simulation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_lab_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.codedex_history ENABLE ROW LEVEL SECURITY;
-- 5. Policies
CREATE POLICY "Users can view their own sim results" ON public.user_simulation_results FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own sim results" ON public.user_simulation_results FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can manage their own lab progress" ON public.user_lab_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own codedex history" ON public.codedex_history FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own codedex history" ON public.codedex_history FOR
INSERT WITH CHECK (auth.uid() = user_id);
-- 6. RPC for Bulk Simulation Stats (Phase 2 Requirement)
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