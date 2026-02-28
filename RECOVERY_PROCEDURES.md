# VERASSO Emergency Rollback & Recovery Procedures

This document outlines the steps to take if a production deployment or beta rollout encounters critical failures.

## 1. Immediate "Panic Mode" (Emergency Shutdown)

If data integrity is at risk or a major security exploit is found:

### Disable Auth Signups

1. Go to **Supabase Dashboard → Auth → Settings**.
2. Toggle **Allow new users to sign up** to **OFF**.

### Disable Realtime (Temporary)

1. Go to **Supabase Dashboard → Realtime → Settings**.
2. Toggle **Realtime** to **OFF** to stop all live data streams.

---

## 2. Database Rollback

### Reverting Migration 017 (Beta Invites)

If invite codes are failing or causing DB performance issues:

```sql
-- Revert 017
DROP POLICY IF EXISTS "Invite codes are readable by anyone" ON public.invite_codes;
DROP TABLE IF EXISTS public.invite_codes;
DROP POLICY IF EXISTS "Users can insert their own feedback" ON public.user_feedback;
DROP POLICY IF EXISTS "Users can view their own feedback" ON public.user_feedback;
DROP TABLE IF EXISTS public.user_feedback;
```

---

## 3. App Version Rollback

### Android (Google Play)

1. Go to **Play Console → Production → Releases**.
2. You cannot "revert" a version code, you must upload a **New Build** with a higher version code (e.g., from `1.3.0` to `1.3.1`) that contains the stable code from the previous branch.

### iOS (App Store)

1. Go to **App Store Connect → My Apps → Pricing and Availability**.
2. Select **Remove from Sale** to immediately pull the app from the store.
3. Submit a hotfix version to Apple for expedited review.

---

## 4. Useful Monitoring Links

- **Sentry Dashboard**: [https://sentry.io/organizations/verasso/issues/](https://sentry.io/organizations/verasso/issues/)
- **Supabase Metrics**: [https://supabase.com/dashboard/project/YOUR_ID/reports](https://supabase.com/dashboard/project/YOUR_ID/reports)
