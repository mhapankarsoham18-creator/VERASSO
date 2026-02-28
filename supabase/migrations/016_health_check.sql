-- ============================================================
-- VERASSO — System Health Check RPC
-- Used by heartbeat/monitoring services
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_system_health() RETURNS JSONB AS $$
DECLARE v_stats JSONB;
BEGIN -- Basic connectivity and integrity check
-- Returns a snapshot of system health indicators
SELECT jsonb_build_object(
        'status',
        'healthy',
        'timestamp',
        now(),
        'db_version',
        version(),
        'profiles_count',
        (
            SELECT count(*)
            FROM public.profiles
        ),
        'active_sessions',
        (
            SELECT count(*)
            FROM public.auth_sessions
            WHERE is_active = true
        )
    ) INTO v_stats;
RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Grant access to service role (and optionally authenticated for simple ping)
GRANT EXECUTE ON FUNCTION public.get_system_health() TO service_role;
GRANT EXECUTE ON FUNCTION public.get_system_health() TO authenticated;