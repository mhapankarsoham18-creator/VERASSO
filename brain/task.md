# VERASSO Phase 1 & 2: Emergency Path (Deadline 5 PM)

## Phase 1: Foundation Hardening (95% Ready)

- [x] Audit the `pubspec.yaml` packages
- [x] Upgrade AR plugin (ar_flutter_plugin -> ar_flutter_plugin_plus)
- [x] Update AR imports in Affected Screens
- [x] Fix Gradle/asset copying error (Cleanup redundant files)
- [/] Stabilize Build Environment (All Caches redirected to D: 70GB Free)
- [/] Run `flutter pub get` & `flutter build apk --release`
- [ ] Verify Supabase Auth/Security (Rotate keys)

## Phase 2: Backend Scalability & Integration (Parallelized)

- [x] Design Supabase schema for Simulations & Labs (`030_phase2_integration.sql`)
- [ ] Create Supabase tables (Execute Migration)
- [ ] Connect CodeMaster Odyssey with real-time backend
- [ ] Verify real-time messaging sync
- [ ] Configure SMTP & Connection Pooling (Supavisor)
- [ ] Deploy Seasonal Event RPCs
