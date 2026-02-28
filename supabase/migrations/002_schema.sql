-- ============================================================
-- VERASSO Schema — Part 2
-- Stories, Gamification, Learning, Marketplace, AR, Security
-- ============================================================

-- ============================================================
-- 5. STORIES & HIGHLIGHTS
-- ============================================================
CREATE TABLE public.user_stories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type TEXT DEFAULT 'image' CHECK (media_type IN ('image','video')),
    caption TEXT,
    background_color TEXT,
    font_style TEXT,
    music_url TEXT,
    views_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '24 hours'),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.story_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    story_id UUID NOT NULL REFERENCES public.user_stories(id) ON DELETE CASCADE,
    viewer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(story_id, viewer_id)
);

CREATE TABLE public.story_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    story_id UUID NOT NULL REFERENCES public.user_stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(story_id, user_id)
);

CREATE TABLE public.user_highlights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    cover_url TEXT,
    story_ids UUID[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.user_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_highlights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Stories viewable" ON public.user_stories FOR SELECT USING (true);
CREATE POLICY "Create own stories" ON public.user_stories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Delete own stories" ON public.user_stories FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Update own stories" ON public.user_stories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Views viewable" ON public.story_views FOR SELECT USING (true);
CREATE POLICY "Record view" ON public.story_views FOR INSERT WITH CHECK (auth.uid() = viewer_id);
CREATE POLICY "Reactions viewable" ON public.story_reactions FOR SELECT USING (true);
CREATE POLICY "React to story" ON public.story_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "View highlights" ON public.user_highlights FOR SELECT USING (true);
CREATE POLICY "Manage highlights" ON public.user_highlights FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_stories_user ON public.user_stories(user_id);
CREATE INDEX idx_stories_expires ON public.user_stories(expires_at);

-- Active stories view
CREATE OR REPLACE VIEW public.active_stories AS
SELECT s.*,
    (SELECT COUNT(*) FROM public.story_views WHERE story_id = s.id) AS view_count,
    (SELECT COUNT(*) FROM public.story_reactions WHERE story_id = s.id) AS reaction_count
FROM public.user_stories s
WHERE s.expires_at > now()
ORDER BY s.created_at DESC;

-- ============================================================
-- 6. GAMIFICATION & PROGRESS
-- ============================================================
CREATE TABLE public.activity_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    points INT DEFAULT 0,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.user_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    activity_category TEXT,
    points_earned INT DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.user_progress_summary (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    total_points INT DEFAULT 0,
    level INT DEFAULT 1,
    rank INT,
    streak_days INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    lessons_completed INT DEFAULT 0,
    ar_projects_created INT DEFAULT 0,
    ar_projects_completed INT DEFAULT 0,
    achievements_count INT DEFAULT 0,
    points_percentile FLOAT DEFAULT 0,
    lessons_percentile FLOAT DEFAULT 0,
    projects_percentile FLOAT DEFAULT 0,
    last_active TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.user_progress_daily (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    points_earned INT DEFAULT 0,
    UNIQUE(user_id, date)
);

CREATE TABLE public.user_weekly_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    goal_type TEXT NOT NULL,
    target_value INT NOT NULL,
    current_value INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, week_start, goal_type)
);

CREATE TABLE public.achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    category TEXT,
    requirement_type TEXT,
    requirement_value INT,
    points_reward INT DEFAULT 0,
    rarity TEXT DEFAULT 'common',
    icon TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.user_achievements (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
    progress INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    earned_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, achievement_id)
);

CREATE TABLE public.user_badges (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_id TEXT,
    unlocked_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, badge_id)
);

ALTER TABLE public.activity_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_weekly_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Activity types public" ON public.activity_types FOR SELECT USING (true);
CREATE POLICY "View own activities" ON public.user_activities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Record activity" ON public.user_activities FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Progress public" ON public.user_progress_summary FOR SELECT USING (true);
CREATE POLICY "Update own progress" ON public.user_progress_summary FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "View own daily" ON public.user_progress_daily FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Record daily" ON public.user_progress_daily FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update daily" ON public.user_progress_daily FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "View own goals" ON public.user_weekly_goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Manage own goals" ON public.user_weekly_goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Achievements public" ON public.achievements FOR SELECT USING (true);
CREATE POLICY "User achievements public" ON public.user_achievements FOR SELECT USING (true);
CREATE POLICY "Award self" ON public.user_achievements FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update own achievement" ON public.user_achievements FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Badges public" ON public.user_badges FOR SELECT USING (true);
CREATE POLICY "Award badge" ON public.user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Leaderboard view
CREATE OR REPLACE VIEW public.user_leaderboard AS
SELECT ups.user_id, ups.total_points, ups.level, ups.rank,
    ups.achievements_count, ups.ar_projects_completed, ups.lessons_completed
FROM public.user_progress_summary ups
ORDER BY ups.rank ASC;

-- Update rankings function
CREATE OR REPLACE FUNCTION update_user_rankings() RETURNS void AS $$
BEGIN
    WITH ranked AS (
        SELECT user_id, ROW_NUMBER() OVER (ORDER BY total_points DESC) AS rank
        FROM public.user_progress_summary
    )
    UPDATE public.user_progress_summary ups
    SET rank = r.rank, updated_at = now()
    FROM ranked r WHERE ups.user_id = r.user_id;

    UPDATE public.user_progress_summary
    SET level = (total_points / 1000) + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================


-- ============================================================
-- 8. FLASHCARDS
-- ============================================================
CREATE TABLE public.decks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    subject TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE TABLE public.flashcards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    deck_id UUID REFERENCES public.decks(id) ON DELETE CASCADE NOT NULL,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flashcards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View decks" ON public.decks FOR SELECT USING (is_public OR auth.uid() = user_id);
CREATE POLICY "Manage decks" ON public.decks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "View cards" ON public.flashcards FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.decks WHERE id = deck_id AND (is_public OR user_id = auth.uid()))
);
CREATE POLICY "Manage cards" ON public.flashcards FOR ALL USING (
    EXISTS (SELECT 1 FROM public.decks WHERE id = deck_id AND user_id = auth.uid())
);

-- ============================================================
-- 9. LEARNING HUB
-- ============================================================
CREATE TABLE public.study_groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    subject TEXT NOT NULL,
    description TEXT,
    avatar_url TEXT,
    creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.group_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.study_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(group_id, user_id)
);
CREATE TABLE public.learning_resources (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.study_groups(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    subject TEXT NOT NULL,
    description TEXT,
    file_url TEXT,
    rating FLOAT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organizer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    subject TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    link_url TEXT,
    max_attendees INT,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.daily_challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    subject TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    solution_hash TEXT,
    reward_points INT DEFAULT 20,
    active_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Groups public" ON public.study_groups FOR SELECT USING (true);
CREATE POLICY "Create groups" ON public.study_groups FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Update own groups" ON public.study_groups FOR UPDATE USING (auth.uid() = creator_id);
CREATE POLICY "Members public" ON public.group_members FOR SELECT USING (true);
CREATE POLICY "Join groups" ON public.group_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Resources public" ON public.learning_resources FOR SELECT USING (true);
CREATE POLICY "Upload resources" ON public.learning_resources FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Events public" ON public.events FOR SELECT USING (true);
CREATE POLICY "Host events" ON public.events FOR INSERT WITH CHECK (auth.uid() = organizer_id);
CREATE POLICY "Update events" ON public.events FOR UPDATE USING (auth.uid() = organizer_id);
CREATE POLICY "Challenges public" ON public.daily_challenges FOR SELECT USING (true);

-- ============================================================
-- 10. MARKETPLACE & MENTORSHIP
-- ============================================================
CREATE TABLE public.talents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    media_urls TEXT[],
    enquiry_details TEXT,
    category TEXT,
    billing_period TEXT DEFAULT 'one-off',
    is_mentor_package BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    featured_expiry TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE TABLE public.talent_profiles (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    headline TEXT,
    bio TEXT,
    skills TEXT[],
    experience JSONB DEFAULT '[]',
    education JSONB DEFAULT '[]',
    portfolio_urls TEXT[],
    service_listings_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Update talent listings count
CREATE OR REPLACE FUNCTION update_talent_counts() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        -- Ensure talent profile exists
        INSERT INTO public.talent_profiles (id) VALUES (NEW.user_id) ON CONFLICT DO NOTHING;
        UPDATE public.talent_profiles SET service_listings_count = service_listings_count + 1 WHERE id = NEW.user_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.talent_profiles SET service_listings_count = service_listings_count - 1 WHERE id = OLD.user_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_talent_change
    AFTER INSERT OR DELETE ON public.talents
    FOR EACH ROW EXECUTE FUNCTION update_talent_counts();
CREATE TABLE public.mentor_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    headline TEXT,
    degrees JSONB DEFAULT '[]',
    experience_years INT DEFAULT 0,
    specializations TEXT[] DEFAULT '{}',
    bio TEXT,
    verification_status TEXT DEFAULT 'pending',
    verification_docs TEXT[] DEFAULT '{}',
    average_rating DECIMAL DEFAULT 0.0,
    total_mentees INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.job_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    budget DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    required_skills TEXT[],
    status TEXT DEFAULT 'open' CHECK (status IN ('open','in_progress','completed','cancelled')),
    job_type TEXT DEFAULT 'Freelance' CHECK (job_type IN ('Freelance','Internship')),
    is_featured BOOLEAN DEFAULT false,
    featured_expiry TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
CREATE TABLE public.job_applications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    job_id UUID REFERENCES public.job_requests(id) ON DELETE CASCADE NOT NULL,
    talent_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(job_id, talent_id)
);
CREATE TABLE public.job_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id UUID REFERENCES public.job_requests(id) ON DELETE CASCADE NOT NULL,
    reviewer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    reviewee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.mentorship_bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    mentor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    talent_post_id UUID REFERENCES public.talents(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'pending',
    billing_period TEXT NOT NULL,
    price_at_booking DECIMAL NOT NULL,
    currency_at_booking TEXT DEFAULT 'USD',
    start_date TIMESTAMPTZ DEFAULT now(),
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.session_schedule (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES public.mentorship_bookings(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 60,
    meeting_link TEXT,
    status TEXT DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Courses
CREATE TABLE public.courses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    cover_url TEXT,
    category TEXT,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.chapters (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_markdown TEXT,
    video_url TEXT,
    external_resource_url TEXT,
    order_index INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    progress_percent INT DEFAULT 0,
    completed_chapters UUID[] DEFAULT '{}',
    enrolled_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    UNIQUE(student_id, course_id)
);
CREATE TABLE public.quizzes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES public.chapters(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    passing_score INT DEFAULT 80,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,
    correct_option_index INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.certificates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    issued_at TIMESTAMPTZ DEFAULT now(),
    certificate_url TEXT,
    verification_code TEXT UNIQUE DEFAULT substring(md5(random()::text), 1, 12),
    metadata JSONB DEFAULT '{}'
);

-- RLS for marketplace
ALTER TABLE public.talents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.talent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentorship_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Talents viewable" ON public.talents FOR SELECT USING (true);
CREATE POLICY "Create talent" ON public.talents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Manage talent" ON public.talents FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Talent profiles viewable" ON public.talent_profiles FOR SELECT USING (true);
CREATE POLICY "Manage own tp" ON public.talent_profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Mentor profiles viewable" ON public.mentor_profiles FOR SELECT USING (
    verification_status = 'verified' OR auth.uid() = user_id
);
CREATE POLICY "Manage own mp" ON public.mentor_profiles FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Jobs viewable" ON public.job_requests FOR SELECT USING (true);
CREATE POLICY "Create job" ON public.job_requests FOR INSERT WITH CHECK (auth.uid() = client_id);
CREATE POLICY "Manage own job" ON public.job_requests FOR ALL USING (auth.uid() = client_id);
CREATE POLICY "View apps" ON public.job_applications FOR SELECT USING (
    auth.uid() = talent_id OR EXISTS (SELECT 1 FROM public.job_requests WHERE id = job_id AND client_id = auth.uid())
);
CREATE POLICY "Apply" ON public.job_applications FOR INSERT WITH CHECK (auth.uid() = talent_id);
CREATE POLICY "Reviews viewable" ON public.job_reviews FOR SELECT USING (true);
CREATE POLICY "Create review" ON public.job_reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);
CREATE POLICY "View own bookings" ON public.mentorship_bookings FOR SELECT USING (
    auth.uid() = student_id OR auth.uid() = mentor_id
);
CREATE POLICY "Create booking" ON public.mentorship_bookings FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Update booking" ON public.mentorship_bookings FOR UPDATE USING (auth.uid() = mentor_id);
CREATE POLICY "View own sessions" ON public.session_schedule FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.mentorship_bookings WHERE id = booking_id AND (student_id = auth.uid() OR mentor_id = auth.uid()))
);
CREATE POLICY "Published courses" ON public.courses FOR SELECT USING (is_published OR creator_id = auth.uid());
CREATE POLICY "Manage courses" ON public.courses FOR ALL USING (creator_id = auth.uid());
CREATE POLICY "Chapters viewable" ON public.chapters FOR SELECT USING (true);
CREATE POLICY "Manage chapters" ON public.chapters FOR ALL USING (
    EXISTS (SELECT 1 FROM public.courses WHERE id = course_id AND creator_id = auth.uid())
);
CREATE POLICY "Own enrollments" ON public.enrollments FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Enroll" ON public.enrollments FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Update progress" ON public.enrollments FOR UPDATE USING (auth.uid() = student_id);
CREATE POLICY "Quizzes viewable" ON public.quizzes FOR SELECT USING (true);
CREATE POLICY "Questions viewable" ON public.questions FOR SELECT USING (true);
CREATE POLICY "Certs viewable" ON public.certificates FOR SELECT USING (true);
CREATE POLICY "Issue cert" ON public.certificates FOR INSERT WITH CHECK (auth.uid() = student_id);

-- ============================================================
-- 11. PROJECTS & CHALLENGES
-- ============================================================
CREATE TABLE public.projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    leader_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'Planning',
    github_url TEXT,
    demo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.project_members (
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'Developer',
    joined_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (project_id, user_id)
);
CREATE TABLE public.project_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'Todo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    difficulty TEXT DEFAULT 'Medium',
    karma_reward INT DEFAULT 50,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.challenge_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content_url TEXT,
    status TEXT DEFAULT 'Pending',
    feedback TEXT,
    submitted_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(challenge_id, user_id)
);

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View projects" ON public.projects FOR SELECT USING (true);
CREATE POLICY "Create project" ON public.projects FOR INSERT WITH CHECK (auth.uid() = leader_id);
CREATE POLICY "Update project" ON public.projects FOR UPDATE USING (auth.uid() = leader_id);
CREATE POLICY "View members" ON public.project_members FOR SELECT USING (true);
CREATE POLICY "Manage tasks" ON public.project_tasks FOR ALL USING (
    EXISTS (SELECT 1 FROM public.project_members WHERE project_id = project_tasks.project_id AND user_id = auth.uid())
);
CREATE POLICY "View challenges" ON public.challenges FOR SELECT USING (true);
CREATE POLICY "Create challenge" ON public.challenges FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "View submissions" ON public.challenge_submissions FOR SELECT USING (
    auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.challenges WHERE id = challenge_id AND creator_id = auth.uid())
);
CREATE POLICY "Submit entry" ON public.challenge_submissions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 12. FEATURE FLAGS & SHARED COUNTERS
-- ============================================================
CREATE TABLE public.feature_flags (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    enabled BOOLEAN DEFAULT false,
    rules JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.shared_counters (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    value BIGINT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_counters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Flags viewable" ON public.feature_flags FOR SELECT USING (true);
CREATE POLICY "Counters viewable" ON public.shared_counters FOR SELECT USING (true);

-- ============================================================
-- 13. ATTACHMENTS & UPLOADS
-- ============================================================
CREATE TABLE public.attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.form_attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    form_id UUID,
    attachment_id UUID REFERENCES public.attachments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.upload_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name TEXT,
    total_chunks INT,
    completed_chunks INT DEFAULT 0,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.upload_chunks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES public.upload_sessions(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    storage_path TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(session_id, chunk_index)
);

ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upload_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upload_chunks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own attachments" ON public.attachments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Upload attachment" ON public.attachments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Delete own attachment" ON public.attachments FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "View own forms" ON public.form_attachments FOR SELECT USING (true);
CREATE POLICY "Create form link" ON public.form_attachments FOR INSERT WITH CHECK (true);
CREATE POLICY "View own sessions" ON public.upload_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Create session" ON public.upload_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "View own chunks" ON public.upload_chunks FOR SELECT USING (true);
CREATE POLICY "Upload chunk" ON public.upload_chunks FOR INSERT WITH CHECK (true);

-- ============================================================
-- 14. SECURITY — Backup Codes, Locations, Trust
-- ============================================================
CREATE TABLE public.user_backup_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, code_hash)
);
-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS "postgis";

CREATE TABLE public.user_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOGRAPHY(POINT, 4326),  -- Added for PostGIS
    accuracy DOUBLE PRECISION,
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

-- Spatial Index
CREATE INDEX idx_user_locations_geo ON public.user_locations USING GIST(location);

-- Trigger to update 'location' column from lat/long if provided
CREATE OR REPLACE FUNCTION public.update_location_column() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_location_update
    BEFORE INSERT OR UPDATE ON public.user_locations
    FOR EACH ROW EXECUTE FUNCTION public.update_location_column();

CREATE TABLE public.document_edits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    document_id TEXT,
    edit_type TEXT,
    content JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    amount DECIMAL NOT NULL,
    category TEXT,
    description TEXT,
    reference_id UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.student_karma (
    student_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_karma INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.user_backup_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_edits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_karma ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View own codes" ON public.user_backup_codes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Insert own codes" ON public.user_backup_codes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update own codes" ON public.user_backup_codes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Delete own codes" ON public.user_backup_codes FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "View own location" ON public.user_locations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Update location" ON public.user_locations FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "View own edits" ON public.document_edits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Record edit" ON public.document_edits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "View own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Record transaction" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Karma public" ON public.student_karma FOR SELECT USING (true);
CREATE POLICY "Manage own karma" ON public.student_karma FOR ALL USING (auth.uid() = student_id);

CREATE INDEX idx_user_backup_codes_user ON public.user_backup_codes(user_id);
CREATE INDEX idx_transactions_user_date ON public.transactions(user_id, created_at);

-- ============================================================
-- 15. SEED DATA
-- ============================================================
INSERT INTO public.activity_types (name, category, points, description, icon) VALUES
    ('lesson_completed', 'learning', 50, 'Complete a lesson', '📚'),
    ('quiz_passed', 'learning', 75, 'Pass a quiz with >70%', '✅'),
    ('quiz_perfect', 'learning', 150, 'Get 100% on a quiz', '🎯'),
    ('project_created', 'building', 100, 'Create an AR project', '🏗️'),
    ('project_completed', 'building', 200, 'Complete an AR project', '🎉'),
    ('circuit_simulated', 'building', 25, 'Run a circuit simulation', '⚡'),
    ('post_created', 'social', 10, 'Create a post', '📝'),
    ('comment_made', 'social', 5, 'Comment on a post', '💬'),
    ('daily_login', 'engagement', 10, 'Log in daily', '📅'),
    ('achievement_earned', 'achievement', 50, 'Earn an achievement', '🏆')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.achievements (name, description, category, requirement_type, requirement_value, points_reward, rarity) VALUES
    ('First Steps', 'Complete your first lesson', 'learning', 'lessons_completed', 1, 50, 'common'),
    ('Scholar', 'Complete 10 lessons', 'learning', 'lessons_completed', 10, 200, 'uncommon'),
    ('Expert', 'Complete 50 lessons', 'learning', 'lessons_completed', 50, 1000, 'rare'),
    ('Master Builder', 'Create 10 AR projects', 'building', 'projects_created', 10, 500, 'uncommon'),
    ('100 Club', 'Earn 100 total points', 'achievement', 'total_points', 100, 100, 'common'),
    ('1K Club', 'Earn 1000 total points', 'achievement', 'total_points', 1000, 500, 'uncommon'),
    ('Week Warrior', '7-day streak', 'engagement', 'streak_days', 7, 300, 'uncommon'),
    ('Monthly Marvel', '30-day streak', 'engagement', 'streak_days', 30, 1500, 'rare')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- DONE
-- ============================================================
