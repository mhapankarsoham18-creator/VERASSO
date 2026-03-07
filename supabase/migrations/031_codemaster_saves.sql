-- ============================================================
-- VERASSO Schema — Part 31: Codemaster Odyssey Save State
-- ============================================================
CREATE TABLE IF NOT EXISTS public.codemaster_saves (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    fragments INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    health DOUBLE PRECISION DEFAULT 100.0,
    max_health DOUBLE PRECISION DEFAULT 100.0,
    current_region INTEGER DEFAULT 1,
    arc_index INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
-- Note: In Dart maxHealth is camelCase, in SQL we usually use snake_case.
-- However, the Dart code uses .from('codemaster_saves').upsert({ 'maxHealth': ... })
-- So I should use camelCase for the columns to match the Dart code exactly 
-- if the Dart code doesn't map them.
-- Looking at codemaster_sync_service.dart:
-- 'fragments': state.fragments,
-- 'level': state.level,
-- 'health': state.health,
-- 'maxHealth': state.maxHealth, <-- camelCase
-- 'currentRegion': state.currentRegion, <-- camelCase
-- 'arcIndex': state.unlockedArcs.length - 1, <-- camelCase
ALTER TABLE public.codemaster_saves
    RENAME COLUMN max_health TO "maxHealth";
ALTER TABLE public.codemaster_saves
    RENAME COLUMN current_region TO "currentRegion";
ALTER TABLE public.codemaster_saves
    RENAME COLUMN arc_index TO "arcIndex";
-- Enable RLS
ALTER TABLE public.codemaster_saves ENABLE ROW LEVEL SECURITY;
-- Policies
CREATE POLICY "Users can view their own game saves" ON public.codemaster_saves FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can upsert their own game saves" ON public.codemaster_saves FOR ALL USING (auth.uid() = user_id);