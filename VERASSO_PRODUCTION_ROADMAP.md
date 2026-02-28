# VERASSO — Production Readiness Roadmap

**Goal:** Transform VERASSO from a strong beta/prototype into a scalable, secure, and robust production application capable of handling real users, real money, and real data.

**Estimated Timeline:** 16-20 Weeks (assuming a small dedicated team). Building out the persistence for all 21 modules is a significant undertaking.

---

## Phase 1: Foundation Hardening & Security (Weeks 1-2)

*Objective: Secure the vulnerable endpoints, set up automated pipelines, and stop the bleeding of technical debt.*

1. **Security & Key Management (Immediate)**
   - **Rotate Keys:** Remove the production Supabase Anon Key from the `.env` repository immediately. Implement a proper secrets manager (e.g., Doppler, AWS Secrets Manager, or GitHub Secrets for CI).
   - **Environment Variables:** Set up strict separation of `.env.development`, `.env.staging`, and `.env.production`.
   - **Privacy Policy & Terms:** Draft and integrate actual GDPR-compliant Privacy Policies and Terms of Service (required for App Store/Play Store approval).

2. **CI/CD Pipeline Setup**
   - Implement GitHub Actions (or Codemagic/Bitrise) to automate:
     - Linting and static analysis on every PR.
     - Running the (currently small) test suite.
     - Building APK/AAB and iOS IPA for staging environments.

3. **Dependency Cleanup**
   - Audit the 80+ packages in `pubspec.yaml`.
   - Remove unused or conflicting legacy dependencies (e.g., fix the Gradle/asset copying error causing the release build to fail).
   - Upgrade outdated packages blocking the build.

---

## Phase 2: Backend Scalability & True Integration (Weeks 3-4)

*Objective: Prepare the Supabase and Firebase infrastructure to handle more than 50 concurrent users.*

1. **Database & API Scalability**
   - **Connection Pooling:** Enable Supavisor (Supabase Connection Pooling) to handle concurrent connections gracefully.
   - **Rate Limiting:** Load test the Edge Function rate-limiters. Ensure abusive IPs are temporarily blocked.
   - **RPC Verification:** Verify that ALL required RPCs (e.g., `get_active_seasonal_events_with_rewards`) are deployed to the production Supabase project and work under load.

2. **Backend Persistence for Prototype Features (The "Completion" Drive)**
   - Audit the application for all features currently relying on hardcoded UI mocks.
   - **Action:** Build out the missing Supabase tables, Edge Functions, and RPCs for:
     - The 50+ Science Simulations (track progress, scores, completion states).
     - AR/VR Labs (store lab sessions, user configurations, generated 3D models if applicable).
     - **CodeMaster Odyssey:** fully integrate the 15+ screens with the backend. Track user quest states, Python execution results, and earned rewards in real-time.
   - *Rationale:* To keep all 21 modules, they must be brought up to the same tier of backend reliability as the Auth and Profile flows.

3. **SMTP & Communications**
   - Enable the proper SMTP server in Supabase (SendGrid, AWS SES, or Resend).
   - Verify email verification, password reset, and magic link auth flows actually perform real email delivery.

---

## Phase 3: Testing & Quality Assurance (Weeks 5-7)

*Objective: Raise test coverage from 16% to an acceptable minimum of 50-60%.*

1. **Core Domain Unit Tests**
   - Focus fiercely on testing business logic. Write Unit Tests for:
     - Gamification logic (XP calculations, Leveling, Badge awading).
     - Financial transactions (if implementing early).
     - Profile and Auth state providers.

2. **Integration Tests for Golden Paths**
   - Write automated integration tests for the multi-step flows:
     1. User Signup → Email Verification → Profile Setup.
     2. Creating a Post → Liking → Commenting.
     3. Accepting a Guild Invite → Earning an Achievement.

3. **End-to-End (E2E) & UI Testing**
   - Implement Patrol or standard Flutter Integration Tests to run automated UI tests on Firebase Test Lab or physical device farms.
   - Write E2E load simulation scripts (already lightly started in `qa/load_test_simulation.dart`) to slam the staging backend with 500+ simulated users.

---

## Phase 4: Feature Completion & Real Commerce (Weeks 8-10)

*Objective: Take the "Do Not Touch" zones and make them fully operational.*

1. **Payment Gateway Integration (Marketplace)**
   - The Talent Marketplace currently lacks a way to process money.
   - Integrate Stripe (or Razorpay, which is in the `pubspec.yaml`) to handle job requests, mentorship bookings, and course purchases.
   - Ensure webhook handlers (via Supabase Edge Functions) securely confirm payments before unlocking access to courses/services.

2. **Messaging Completion (Robustness & Signal Protocol)**
   - **Action:** Transition the messaging module from scaffolded prototypes to robust real-time communication.
   - Implement true Signal-protocol E2E encryption for 1:1 and Vault chats.
   - Fix media sharing reliability by implementing robust retry/resume queues (using `flutter_downloader` or custom background isolate tasks).
   - Build out the missing Group Chat functionality with scalable Supabase Realtime channels.

3. **Third-Party Auth (Optional but recommended)**
   - Configure OAuth providers (Google, Apple) in Supabase. Apple Sign-In is mandatory if you offer any external login on iOS.

---

## Phase 5: Release Ops & Launch (Weeks 11-12)

*Objective: The final polish and submission to the wild.*

1. **External Security Audit (Penetration Test)**
   - Hire an external firm or dedicated security engineer to attempt to break the RLS policies, bypass the auth gates, and spoof gamification XP.
   - Fix findings from the audit.

2. **App Store & Google Play Optimization**
   - Generate high-quality screenshots.
   - Fill out all content rating questionnaires and privacy declarations.
   - Submit for Beta review (TestFlight and Google Play Internal Testing).

3. **Monitoring & Analytics Hookups**
   - Ensure Sentry is fully catching all staging errors.
   - Ensure analytics (Firebase Analytics or custom Supabase telemetry) are tracking core user retention metrics reliably.

4. **Production Go-Live**
   - Final Database Migration.
   - Flip DNS routing.
   - Monitor Sentry intensely for the first 24 hours.

---

### The Executive Mandate

**Do not add a single new feature until Phase 1 and Phase 2 are completely finished.** The app currently collapses under its own structural weight. By following this roadmap, you build the foundation required to hold up the 21 modules you've designed.
