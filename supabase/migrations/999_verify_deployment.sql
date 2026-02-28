-- ============================================================
-- VERASSO - Post-Deployment Verification
-- Run this AFTER running 001-004 to verify your install
-- ============================================================

DO $$
DECLARE
    v_table_count INT;
    v_policy_count INT;
    v_trigger_count INT;
    v_function_count INT;
    v_missing_tables TEXT[];
    v_expected_tables TEXT[] := ARRAY[
        'profiles', 'posts', 'doubts', 'comments', 'likes', 'relationships',
        'polls', 'collections', 'conversations', 'messages', 'user_stories',
        'story_views', 'user_progress_summary', 'achievements', 'ar_projects', 'bugs',
        'articles', 'rate_limit_rules', 'auth_sessions', 'security_audit_log', 'invite_codes'
    ];
    t TEXT;
BEGIN
    -- 1. Count Tables
    SELECT COUNT(*) INTO v_table_count FROM information_schema.tables 
    WHERE table_schema = 'public';

    -- 2. Count RLS Policies
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies 
    WHERE schemaname = 'public';

    -- 3. Count Custom Functions
    SELECT COUNT(*) INTO v_function_count FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public';

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'VERIFICATION RESULTS';
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Tables Found: % (Expected ~72)', v_table_count;
    RAISE NOTICE 'RLS Policies: % (Expected ~140)', v_policy_count;
    RAISE NOTICE 'Functions:    % (Expected ~25)', v_function_count;

    -- 4. Check for critical tables
    FOREACH t IN ARRAY v_expected_tables LOOP
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t) THEN
           IF t != 'user_progress_summary' THEN 
               RAISE WARNING 'MISSING CRITICAL TABLE: %', t;
           END IF;
        END IF;
    END LOOP;

    -- 4b. Check for critical functions
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_nearby_users') THEN
        RAISE WARNING 'MISSING RPC: get_nearby_users';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'check_rate_limit') THEN
        RAISE WARNING 'MISSING RPC: check_rate_limit';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_recommended_posts') THEN
        RAISE WARNING 'MISSING RPC: get_recommended_posts';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'send_push_notification') THEN
        RAISE WARNING 'MISSING TRIGGER FUNCTION: send_push_notification';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_invite_code') THEN
        RAISE WARNING 'MISSING RPC: validate_invite_code';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'consume_invite_code') THEN
        RAISE WARNING 'MISSING RPC: consume_invite_code';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'search_users') THEN
        RAISE WARNING 'MISSING RPC: search_users';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_feed') THEN
        RAISE WARNING 'MISSING RPC: get_feed';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_invite_code') THEN
        RAISE WARNING 'MISSING RPC: validate_invite_code';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'consume_invite_code') THEN
        RAISE WARNING 'MISSING RPC: consume_invite_code';
    END IF;

    -- 5. Check Extensions
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        RAISE NOTICE 'Extension pgcrypto: OK';
    ELSE
        RAISE WARNING 'Extension pgcrypto: MISSING';
    END IF;

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'If no warnings above, deployment is SUCCESSFUL.';
    RAISE NOTICE '------------------------------------------------';
END $$;
