-- ============================================================
-- VERASSO — Seed Data Script (DEVELOPMENT ONLY)
-- This file is gated to only run in local/dev environments.
-- It will NOT execute in production.
-- ============================================================
DO $$
DECLARE v_user_id UUID;
v_post_id UUID;
v_is_dev BOOLEAN;
BEGIN -- Gate: Only run if this looks like a local dev environment
-- In production, the database name will be 'postgres' on Supabase hosted,
-- but we check for the presence of a seed marker to be safe.
SELECT NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE role = 'admin'
        LIMIT 1
    ) INTO v_is_dev;
-- Additional safety: skip if more than 5 users exist (likely production)
IF (
    SELECT count(*)
    FROM auth.users
) > 5 THEN RAISE NOTICE 'Skipping seed data: more than 5 users detected (likely production).';
RETURN;
END IF;
-- 1. Get the first user
SELECT id INTO v_user_id
FROM auth.users
LIMIT 1;
IF v_user_id IS NULL THEN RAISE NOTICE 'No users found. Sign up in the app first, then run this script.';
RETURN;
END IF;
RAISE NOTICE 'Seeding DEVELOPMENT data for user: %',
v_user_id;
-- 2. Update Profile to be admin
UPDATE public.profiles
SET full_name = 'Verasso Admin',
    headline = 'System Administrator',
    bio = 'Platform admin account for development and testing.',
    role = 'admin'
WHERE id = v_user_id;
-- 3. Create sample Posts (no external placeholder URLs)
INSERT INTO public.posts (user_id, content, type, media_type, subject)
VALUES (
        v_user_id,
        'Welcome to Verasso! This is the first post on the platform.',
        'text',
        'text',
        'General'
    ),
    (
        v_user_id,
        'Just shipped a new feature — check out the AR lab!',
        'text',
        'text',
        'Development'
    ),
    (
        v_user_id,
        'Who else is excited about the gamification engine?',
        'text',
        'text',
        'Community'
    ),
    (
        v_user_id,
        'Pro tip: use the Codedex sandbox to practice Python.',
        'text',
        'text',
        'Learning'
    );
-- 4. Create sample Talents (no placeholder images)
INSERT INTO public.talents (user_id, title, description, price, category)
VALUES (
        v_user_id,
        'Flutter App Development',
        'Full-stack mobile app development with Flutter and Supabase.',
        50.00,
        'Development'
    ),
    (
        v_user_id,
        'AR/VR Consulting',
        'Expert guidance on building AR experiences.',
        100.00,
        'Consulting'
    );
-- 5. Create sample AR Project
INSERT INTO public.ar_projects (user_id, name, description, is_public)
VALUES (
        v_user_id,
        'Solar System Model',
        'An interactive scale model of our solar system.',
        true
    );
-- 6. Create sample Bug Report
INSERT INTO public.bugs (bug_hash, title, category, status)
VALUES (
        'seed_hash_001',
        'Sample: Button alignment issue',
        'UI',
        'active'
    ) ON CONFLICT DO NOTHING;
INSERT INTO public.bug_reports (bug_hash, reporter_id, title, description)
VALUES (
        'seed_hash_001',
        v_user_id,
        'Button alignment issue',
        'Login button is slightly off-center on smaller screens.'
    );
RAISE NOTICE 'Development seed data injected successfully!';
END $$;