// @ts-nocheck — Runs in Supabase Deno Edge Runtime, not Node.js
// ============================================================
// VERASSO — Centralized Server Edge Function
// Routes: health, feed, gamification, admin, cleanup
// ============================================================
import { createClient, SupabaseClient } from "@supabase/supabase-js"
import "edge-runtime"


// ── CORS Headers ──────────────────────────────────────────────
const CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, x-client-info, apikey",
    "Content-Type": "application/json",
}

function json(data: unknown, status = 200) {
    return new Response(JSON.stringify(data), { status, headers: CORS_HEADERS })
}

function err(message: string, status = 400) {
    return json({ error: message }, status)
}

// ── Auth helpers ──────────────────────────────────────────────
function getServiceClient(): SupabaseClient {
    return createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    )
}

function getUserClient(authHeader: string): SupabaseClient {
    return createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        { global: { headers: { Authorization: authHeader } } },
    )
}

async function requireAuth(req: Request) {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) throw new Error("Missing Authorization header")
    const client = getUserClient(authHeader)
    const { data, error } = await client.auth.getUser()
    if (error || !data.user) throw new Error("Unauthorized")
    return { user: data.user, client }
}

async function requireAdmin(req: Request) {
    const { user, client } = await requireAuth(req)
    const service = getServiceClient()
    const { data: profile } = await service
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .single()
    if (profile?.role !== "admin") throw new Error("Admin access required")
    return { user, client, service }
}

// ── Router ────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response(null, { status: 204, headers: CORS_HEADERS })
    }

    const url = new URL(req.url)
    // Strip the function prefix: /server/health → /health
    const path = url.pathname.replace(/^\/server/, "") || "/"

    try {
        // ── GET /health ─────────────────────────────────────────
        if (path === "/health" && req.method === "GET") {
            return await handleHealth()
        }

        // ── POST /feed ──────────────────────────────────────────
        if (path === "/feed" && req.method === "POST") {
            return await handleFeed(req)
        }

        // ── POST /gamification/award ────────────────────────────
        if (path === "/gamification/award" && req.method === "POST") {
            return await handleGamificationAward(req)
        }

        // ── POST /gamification/streak ───────────────────────────
        if (path === "/gamification/streak" && req.method === "POST") {
            return await handleGamificationStreak(req)
        }

        // ── GET /gamification/leaderboard ───────────────────────
        if (path === "/gamification/leaderboard" && req.method === "GET") {
            return await handleLeaderboard(url)
        }

        // ── POST /gamification/validate ─────────────────────────
        if (path === "/gamification/validate" && req.method === "POST") {
            return await handleGamificationValidate(req)
        }

        // ── GET /gamification/quests ────────────────────────────
        if (path === "/gamification/quests" && req.method === "GET") {
            return await handleGamificationQuests(req)
        }

        // ── POST /gamification/quest-progress ───────────────────
        if (path === "/gamification/quest-progress" && req.method === "POST") {
            return await handleGamificationQuestProgress(req)
        }

        // ── GET /guilds/leaderboard ─────────────────────────────
        if (path === "/guilds/leaderboard" && req.method === "GET") {
            return await handleGuildsLeaderboard(req)
        }
        
        // ── POST /guilds/create ─────────────────────────────────
        if (path === "/guilds/create" && req.method === "POST") {
            return await handleGuildsCreate(req)
        }

        // ── POST /guilds/join ───────────────────────────────────
        if (path === "/guilds/join" && req.method === "POST") {
            return await handleGuildsJoin(req)
        }

        // ── POST /guilds/leave ──────────────────────────────────
        if (path === "/guilds/leave" && req.method === "POST") {
            return await handleGuildsLeave(req)
        }

        // ── POST /guilds/promote ───────────────────────────────
        if (path === "/guilds/promote" && req.method === "POST") {
            return await handleGuildsPromote(req)
        }

        // ── POST /admin/ban ─────────────────────────────────────
        if (path === "/admin/ban" && req.method === "POST") {
            return await handleAdminBan(req)
        }

        // ── POST /admin/feature ─────────────────────────────────
        if (path === "/admin/feature" && req.method === "POST") {
            return await handleAdminFeature(req)
        }

        // ── GET /admin/stats ────────────────────────────────────
        if (path === "/admin/stats" && req.method === "GET") {
            return await handleAdminStats(req)
        }

        // ── POST /cleanup ───────────────────────────────────────
        if (path === "/cleanup" && req.method === "POST") {
            return await handleCleanup(req)
        }

        return err("Not found", 404)
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : String(error)
        const status = message.includes("Unauthorized") || message.includes("Admin") ? 403 : 500
        return err(message, status)
    }
})

// ================================================================
// ROUTE HANDLERS
// ================================================================

// ── /health ─────────────────────────────────────────────────────
async function handleHealth() {
    const service = getServiceClient()

    const tables = ["profiles", "posts", "messages", "notifications", "user_stories"]
    const counts: Record<string, number> = {}

    for (const table of tables) {
        const { count } = await service
            .from(table)
            .select("*", { count: "exact", head: true })
        counts[table] = count ?? 0
    }

    // Active users in last 24h
    const { count: activeUsers } = await service
        .from("user_progress_summary")
        .select("*", { count: "exact", head: true })
        .gte("last_active", new Date(Date.now() - 86400000).toISOString())

    return json({
        status: "healthy",
        timestamp: new Date().toISOString(),
        version: "1.0.0",
        tables: counts,
        active_users_24h: activeUsers ?? 0,
    })
}

// ── /feed ───────────────────────────────────────────────────────
async function handleFeed(req: Request) {
    const { user, client } = await requireAuth(req)
    const body = await req.json().catch(() => ({}))
    const page = body.page ?? 0
    const pageSize = Math.min(body.page_size ?? 20, 50)
    const offset = page * pageSize

    const service = getServiceClient()

    // 1. Get IDs the user follows
    const { data: following } = await service
        .from("user_following")
        .select("following_id")
        .eq("follower_id", user.id)

    const followedIds = (following ?? []).map((f: { following_id: string }) => f.following_id)

    // 2. Fetch posts: followed users' posts + trending public posts
    let query = service
        .from("posts")
        .select(`
      *,
      profiles!posts_user_id_fkey (id, username, full_name, avatar_url)
    `)
        .eq("is_personal", false)
        .order("created_at", { ascending: false })
        .range(offset, offset + pageSize - 1)

    // If user follows people, prioritize their posts; otherwise show trending
    if (followedIds.length > 0) {
        // Combine: followed users + trending (high likes_count)
        query = query.or(
            `user_id.in.(${followedIds.join(",")}),likes_count.gte.5`
        )
    }

    const { data: posts, error } = await query
    if (error) return err(error.message)

    // Sort: followed users first, then by engagement score
    const sorted = (posts ?? []).sort((a: any, b: any) => {
        const aFollowed = followedIds.includes(a.user_id) ? 1 : 0
        const bFollowed = followedIds.includes(b.user_id) ? 1 : 0
        if (aFollowed !== bFollowed) return bFollowed - aFollowed

        // Engagement score: likes + comments * 2
        const aScore = (a.likes_count ?? 0) + (a.comments_count ?? 0) * 2
        const bScore = (b.likes_count ?? 0) + (b.comments_count ?? 0) * 2
        if (aScore !== bScore) return bScore - aScore

        // Recency fallback
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    })

    return json({
        posts: sorted,
        page,
        page_size: pageSize,
        has_more: (posts ?? []).length === pageSize,
    })
}

// ── /gamification/award ─────────────────────────────────────────
async function handleGamificationAward(req: Request) {
    const { user } = await requireAuth(req)
    const { activity_type, category, metadata } = await req.json()

    if (!activity_type) return err("activity_type is required")

    const service = getServiceClient()

    // 1. Look up points for this activity type
    const { data: activityDef } = await service
        .from("activity_types")
        .select("points, name")
        .eq("name", activity_type)
        .single()

    const points = activityDef?.points ?? 10 // Default 10 points

    // 2. Record the activity
    const { error: activityError } = await service
        .from("user_activities")
        .insert({
            user_id: user.id,
            activity_type,
            activity_category: category ?? "general",
            points_earned: points,
            metadata: metadata ?? {},
        })

    if (activityError) return err(activityError.message)

    // 3. Update progress summary
    const { data: progress } = await service
        .from("user_progress_summary")
        .select("*")
        .eq("user_id", user.id)
        .single()

    if (progress) {
        await service
            .from("user_progress_summary")
            .update({
                total_points: (progress.total_points ?? 0) + points,
                level: Math.floor(((progress.total_points ?? 0) + points) / 1000) + 1,
                last_active: new Date().toISOString(),
                updated_at: new Date().toISOString(),
            })
            .eq("user_id", user.id)
    } else {
        await service
            .from("user_progress_summary")
            .insert({
                user_id: user.id,
                total_points: points,
                level: 1,
                last_active: new Date().toISOString(),
            })
    }

    // 4. Update daily progress
    const today = new Date().toISOString().split("T")[0]
    const { data: dailyProgress } = await service
        .from("user_progress_daily")
        .select("*")
        .eq("user_id", user.id)
        .eq("date", today)
        .single()

    if (dailyProgress) {
        await service
            .from("user_progress_daily")
            .update({ points_earned: (dailyProgress.points_earned ?? 0) + points })
            .eq("user_id", user.id)
            .eq("date", today)
    } else {
        await service
            .from("user_progress_daily")
            .insert({ user_id: user.id, date: today, points_earned: points })
    }

    // 5. Check achievements
    const newTotal = (progress?.total_points ?? 0) + points
    const { data: achievements } = await service
        .from("achievements")
        .select("*")
        .eq("is_active", true)
        .lte("requirement_value", newTotal)

    const unlocked: string[] = []
    for (const achievement of achievements ?? []) {
        const { data: existing } = await service
            .from("user_achievements")
            .select("is_completed")
            .eq("user_id", user.id)
            .eq("achievement_id", achievement.id)
            .single()

        if (!existing?.is_completed) {
            await service.from("user_achievements").upsert({
                user_id: user.id,
                achievement_id: achievement.id,
                progress: newTotal,
                is_completed: true,
                earned_at: new Date().toISOString(),
            })
            unlocked.push(achievement.name)
        }
    }

    return json({
        points_awarded: points,
        total_points: newTotal,
        level: Math.floor(newTotal / 1000) + 1,
        achievements_unlocked: unlocked,
    })
}

// ── /gamification/streak ────────────────────────────────────────
async function handleGamificationStreak(req: Request) {
    const { user } = await requireAuth(req)
    const service = getServiceClient()

    // Get current progress
    const { data: progress } = await service
        .from("user_progress_summary")
        .select("streak_days, longest_streak, last_active")
        .eq("user_id", user.id)
        .single()

    if (!progress) {
        // Create initial progress
        await service.from("user_progress_summary").insert({
            user_id: user.id,
            streak_days: 1,
            longest_streak: 1,
            last_active: new Date().toISOString(),
        })
        return json({ streak_days: 1, longest_streak: 1, streak_extended: true })
    }

    const lastActive = new Date(progress.last_active)
    const now = new Date()
    const diffHours = (now.getTime() - lastActive.getTime()) / (1000 * 60 * 60)

    let streakDays = progress.streak_days ?? 0
    let longestStreak = progress.longest_streak ?? 0
    let streakExtended = false

    if (diffHours >= 24 && diffHours < 48) {
        // Consecutive day — extend streak
        streakDays += 1
        streakExtended = true
    } else if (diffHours >= 48) {
        // Streak broken — reset
        streakDays = 1
        streakExtended = true
    }
    // If < 24h, same day — no change

    longestStreak = Math.max(longestStreak, streakDays)

    await service
        .from("user_progress_summary")
        .update({
            streak_days: streakDays,
            longest_streak: longestStreak,
            last_active: now.toISOString(),
            updated_at: now.toISOString(),
        })
        .eq("user_id", user.id)

    return json({
        streak_days: streakDays,
        longest_streak: longestStreak,
        streak_extended: streakExtended,
    })
}

// ── /gamification/leaderboard ───────────────────────────────────
async function handleLeaderboard(url: URL) {
    const limit = Math.min(parseInt(url.searchParams.get("limit") ?? "20"), 100)
    const service = getServiceClient()

    const { data, error } = await service
        .from("user_progress_summary")
        .select(`
      user_id,
      total_points,
      level,
      rank,
      streak_days,
      achievements_count,
      profiles!user_progress_summary_user_id_fkey (username, full_name, avatar_url)
    `)
        .order("total_points", { ascending: false })
        .limit(limit)

    if (error) return err(error.message)

    return json({
        leaderboard: data ?? [],
        total: (data ?? []).length,
    })
}

// ── /gamification/validate ──────────────────────────────────────
async function handleGamificationValidate(req: Request) {
    const { user, client } = await requireAuth(req)
    const { action_type } = await req.json()
    const { data, error } = await client.rpc('validate_gamification_action', {
        p_user_id: user.id,
        p_action_type: action_type,
        p_cooldown_seconds: 60
    })
    if (error) return err(error.message)
    return json(data)
}

// ── /gamification/quests ────────────────────────────────────────
async function handleGamificationQuests(req: Request) {
    const { client } = await requireAuth(req)
    const { data: quests, error } = await client
        .from('quests')
        .select('*')
        .eq('is_active', true)
    if (error) return err(error.message)
    return json({ quests })
}

// ── /gamification/quest-progress ────────────────────────────────
async function handleGamificationQuestProgress(req: Request) {
    await requireAuth(req)
    // Server-side forced quest progress update (bypass event bus if needed)
    return json({ success: true, message: "Use the event bus for standard progress tracking." })
}

// ── /guilds/leaderboard ─────────────────────────────────────────
async function handleGuildsLeaderboard(req: Request) {
    const { client } = await requireAuth(req)
    const { data, error } = await client
        .from('guilds')
        .select('*')
        .eq('is_active', true)
        .order('guild_xp', { ascending: false })
        .limit(20)
    if (error) return err(error.message)
    return json({ leaderboard: data })
}

// ── /admin/ban ──────────────────────────────────────────────────
async function handleAdminBan(req: Request) {
    const { user, service } = await requireAdmin(req)
    const { target_user_id, banned, reason } = await req.json()

    if (!target_user_id) return err("target_user_id is required")

    // Update profile to reflect ban (using trust_score = -1 for banned)
    const { error } = await service
        .from("profiles")
        .update({
            trust_score: banned ? -1 : 0,
            bio: banned ? `[BANNED: ${reason ?? "Policy violation"}]` : null,
        })
        .eq("id", target_user_id)

    if (error) return err(error.message)

    // Log the action
    await service.rpc("log_security_event", {
        p_user_id: user.id,
        p_action: banned ? "user_banned" : "user_unbanned",
        p_resource_type: "user",
        p_resource_id: target_user_id,
        p_metadata: { reason, admin_id: user.id },
        p_severity: "critical",
    })

    return json({ success: true, target_user_id, banned })
}

// ── /admin/feature ──────────────────────────────────────────────
async function handleAdminFeature(req: Request) {
    const { service } = await requireAdmin(req)
    const { entity_type, entity_id, featured, duration_days } = await req.json()

    if (!entity_type || !entity_id) return err("entity_type and entity_id are required")

    const expiry = duration_days
        ? new Date(Date.now() + duration_days * 86400000).toISOString()
        : null

    if (entity_type === "talent") {
        const { error } = await service
            .from("talents")
            .update({ is_featured: featured ?? true, featured_expiry: expiry })
            .eq("id", entity_id)
        if (error) return err(error.message)
    } else if (entity_type === "job") {
        const { error } = await service
            .from("job_requests")
            .update({ is_featured: featured ?? true, featured_expiry: expiry })
            .eq("id", entity_id)
        if (error) return err(error.message)
    } else {
        return err("Unsupported entity_type. Use: talent, job")
    }

    return json({ success: true, entity_type, entity_id, featured: featured ?? true })
}

// ── /admin/stats ────────────────────────────────────────────────
async function handleAdminStats(req: Request) {
    const { service } = await requireAdmin(req)

    const tableCounts: Record<string, number> = {}
    const tables = [
        "profiles", "posts", "comments", "likes", "messages",
        "conversations", "notifications", "user_stories",
        "talents", "job_requests", "courses", "enrollments",
        "challenges", "user_activities",
    ]

    for (const table of tables) {
        const { count } = await service
            .from(table)
            .select("*", { count: "exact", head: true })
        tableCounts[table] = count ?? 0
    }

    // Users by role
    const { data: roleCounts } = await service
        .from("profiles")
        .select("role")

    const roles: Record<string, number> = {}
    for (const row of roleCounts ?? []) {
        roles[row.role] = (roles[row.role] ?? 0) + 1
    }

    // New users this week
    const weekAgo = new Date(Date.now() - 7 * 86400000).toISOString()
    const { count: newUsersWeek } = await service
        .from("profiles")
        .select("*", { count: "exact", head: true })
        .gte("created_at", weekAgo)

    // Active users today
    const dayAgo = new Date(Date.now() - 86400000).toISOString()
    const { count: activeToday } = await service
        .from("user_progress_summary")
        .select("*", { count: "exact", head: true })
        .gte("last_active", dayAgo)

    return json({
        table_counts: tableCounts,
        users_by_role: roles,
        new_users_this_week: newUsersWeek ?? 0,
        active_users_today: activeToday ?? 0,
        generated_at: new Date().toISOString(),
    })
}

// ── /cleanup ────────────────────────────────────────────────────
async function handleCleanup(req: Request) {
    await requireAdmin(req)
    const service = getServiceClient()

    const results: Record<string, string> = {}

    // 1. Clean expired stories
    try {
        await service.rpc("cleanup_expired_stories")
        results.stories = "ok"
    } catch { results.stories = "skipped" }

    // 2. Clean expired rate limits
    try {
        await service.rpc("cleanup_rate_limits")
        results.rate_limits = "ok"
    } catch { results.rate_limits = "skipped" }

    // 3. Clean expired sessions
    try {
        await service.rpc("cleanup_expired_sessions")
        results.sessions = "ok"
    } catch { results.sessions = "skipped" }

    // 4. Clean old notifications
    try {
        await service.rpc("cleanup_old_notifications")
        results.notifications = "ok"
    } catch { results.notifications = "skipped" }

    // 5. Update rankings
    try {
        await service.rpc("update_user_rankings")
        results.rankings = "ok"
    } catch { results.rankings = "skipped" }

    return json({
        success: true,
        cleanup_results: results,
        ran_at: new Date().toISOString(),
    })
}
// ── /guilds/create ─────────────────────────────────────────────
async function handleGuildsCreate(req: Request) {
    const { user, client } = await requireAuth(req)
    const { name, description, emblem_url } = await req.json()

    if (!name) return err("Guild name is required")

    // 1. Check if user is already in a guild
    const { data: existingMember } = await client
        .from('guild_members')
        .select('guild_id')
        .eq('user_id', user.id)
        .maybeSingle()

    if (existingMember) return err("You are already a member of a guild")

    // 2. Create the guild
    const { data: guild, error: guildError } = await client
        .from('guilds')
        .insert({
            name,
            description,
            emblem_url,
            leader_id: user.id,
            member_count: 1
        })
        .select()
        .single()

    if (guildError) return err(guildError.message)

    // 3. Add leader as member
    const { error: memberError } = await client
        .from('guild_members')
        .insert({
            guild_id: guild.id,
            user_id: user.id,
            role: 'leader'
        })

    if (memberError) return err(memberError.message)

    return json({ success: true, guild })
}

// ── /guilds/join ───────────────────────────────────────────────
async function handleGuildsJoin(req: Request) {
    const { user, client } = await requireAuth(req)
    const { guild_id } = await req.json()

    if (!guild_id) return err("guild_id is required")

    // 1. Check if user is already in a guild
    const { data: existingMember } = await client
        .from('guild_members')
        .select('guild_id')
        .eq('user_id', user.id)
        .maybeSingle()

    if (existingMember) return err("You are already a member of a guild")

    // 2. Check guild capacity
    const { data: guild, error: guildError } = await client
        .from('guilds')
        .select('member_count, max_members')
        .eq('id', guild_id)
        .single()

    if (guildError) return err("Guild not found")
    if ((guild.member_count ?? 0) >= (guild.max_members ?? 20)) {
        return err("Guild is full")
    }

    // 3. Join guild
    const { error: joinError } = await client
        .from('guild_members')
        .insert({
            guild_id,
            user_id: user.id,
            role: 'member'
        })

    if (joinError) return err(joinError.message)

    return json({ success: true, message: "Joined guild successfully" })
}

// ── /guilds/leave ──────────────────────────────────────────────
async function handleGuildsLeave(req: Request) {
    const { user, client } = await requireAuth(req)

    // 1. Check role (leaders cannot leave without promoting or deleting)
    const { data: member, error: memberError } = await client
        .from('guild_members')
        .select('guild_id, role')
        .eq('user_id', user.id)
        .single()

    if (memberError) return err("You are not in a guild")
    if (member.role === 'leader') {
        return err("Leaders cannot leave a guild. Promote someone else or delete the guild.")
    }

    // 2. Leave
    const { error: leaveError } = await client
        .from('guild_members')
        .delete()
        .eq('guild_id', member.guild_id)
        .eq('user_id', user.id)

    if (leaveError) return err(leaveError.message)

    return json({ success: true, message: "Left guild successfully" })
}

// ── /guilds/promote ────────────────────────────────────────────
async function handleGuildsPromote(req: Request) {
    const { user, client } = await requireAuth(req)
    const { target_user_id, new_role } = await req.json()

    if (!target_user_id || !new_role) return err("target_user_id and new_role are required")
    if (!['officer', 'leader'].includes(new_role)) return err("Invalid role")

    // 1. Verify caller is leader
    const { data: caller, error: callerError } = await client
        .from('guild_members')
        .select('guild_id, role')
        .eq('user_id', user.id)
        .single()

    if (callerError || caller.role !== 'leader') return err("Only leaders can promote members")

    // 2. Update target member
    const { error: updateError } = await client
        .from('guild_members')
        .update({ role: new_role })
        .eq('guild_id', caller.guild_id)
        .eq('user_id', target_user_id)

    if (updateError) return err(updateError.message)

    // 3. If promoting to leader, demote self to officer
    if (new_role === 'leader') {
        await client
            .from('guild_members')
            .update({ role: 'officer' })
            .eq('guild_id', caller.guild_id)
            .eq('user_id', user.id)
            
        await client
            .from('guilds')
            .update({ leader_id: target_user_id })
            .eq('id', caller.guild_id)
    }

    return json({ success: true, message: `User promoted to ${new_role}` })
}
