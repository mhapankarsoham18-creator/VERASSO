# Security Audit RFP (Request for Proposal)

**Project:** VERASSO - Talent & Learning Marketplace  
**Version:** 1.0  
**Date:** February 18, 2026  
**Status:** Ready for Distribution

---

## Executive Summary

VERASSO is a Flutter/Dart mobile application currently in pre-release (v1.2.0.) designed for peer-to-peer talent exchange, advanced learning simulations, and community engagement. We are conducting an external security audit before public launch to validate our cryptographic implementation, authorization controls, and infrastructure security.

**Audit Timeline:** 2 weeks  
**Budget:** $5,000 USD  
**Start:** Week of February 24, 2026  
**Deliverable:** February 28 + March 7, 2026  

---

## Scope of Audit

### In Scope

#### 1. Backend Authorization (Supabase RLS)
- Review all row-level security policies
- Test for authorization bypass vulnerabilities
- Validate data isolation between users
- Verify policy logic for edge cases

**Tables to Review:**
- `users` - profile visibility rules
- `posts` - post visibility and edit permissions
- `messages` - conversation access control
- `auth.users` - authentication scoping
- `user_relationships` - follow/block data isolation

#### 2. Authentication Flows
- User registration (email + password)
- Email verification process
- Password reset flow
- Multi-factor authentication (MFA) if present
- Biometric login (fingerprint/face)
- Session management & token handling

**Test Cases:**
- Register new user - validate proper state
- Reset password with old link - should fail
- Verify email link reuse - should fail
- Login with invalid credentials - rate limiting?
- MFA bypass attempts

#### 3. Encryption Implementation
- E2E message encryption (chat feature)
- At-rest encryption (Hive database)
- In-transit encryption (TLS/HTTPS)
- Key management & rotation
- Padding oracle attacks on encryption

**Crypto Libraries Used:**
- `encrypt` (AES encryption)
- `crypto` (SHA256 hashing)
- `pointycastle` (RSA for asymmetric)

#### 4. API Security
- Rate limiting (auth, API endpoints)
- Input validation & sanitization
- API key exposure (hardcoding in source)
- Secrets management (Firebase, Supabase)
- CORS policies

**Rate Limit Targets:**
- Password reset: ? attempts/min (unknown - audit needs to test)
- Login: ? attempts/min (unknown)
- Search: ? requests/user/hour
- API calls: ? requests/sec/user

#### 5. Dependency Security
- Vulnerable packages identified
- Supply chain risks (`nearby_connections` is known problematic)
- Package pinning strategy
- Update policy

**Key Dependencies:**
```yaml
# Crypto
encrypt: ^4.4.1
crypto: ^3.0.3
pointycastle: ^3.6.2

# Networking
supabase_flutter: ^2.0.0
firebase_core: ^3.0.0
http: ^1.1.0

# P2P
nearby_connections: ^5.0.0  # ⚠️ FLAGGED: outdated, has BLE bugs

# Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# Auth
google_sign_in: ^6.1.0
```

#### 6. Threat Model Validation
- Does the documented threat model match implementation?
- Are threats actually mitigated?
- What are unaddressed threats?

---

### Out of Scope (For This Audit)

- Mobile app UI/UX security (covered in accessibility audit separately)
- Infrastructure hardening (DevOps audit, not security audit)
- Business logic correctness (product audit, not security audit)
- Load testing & DDoS resilience
- Source code review of all 50K+ lines (time-limited to most critical paths)

---

## Deliverables

### 1. Executive Summary (2-3 pages)
- Overall risk rating (1-10)
- Critical findings count
- Recommended launch readiness

### 2. Detailed Findings Report
- **Format:** Severity (CRITICAL/HIGH/MEDIUM/LOW)
- **For each finding:**
  - Vulnerability description
  - Attack scenario
  - Impact (data loss, unauthorized access, etc.)
  - Reproducibility (CVSS score if applicable)
  - Remediation steps
  - Timeline to fix

### 3. Remediation Prioritization
- Which issues must be fixed before launch (CRITICAL)
- Which can be fixed post-launch (HIGH/MEDIUM/LOW)
- Effort estimation per issue

### 4. Post-Audit Testing Plan
- How to validate fixes
- Security test cases (for our CI/CD)
- Regression prevention

### 5. Risk Assessment Matrix
- Likelihood vs Impact chart
- Residual risk after remediation

---

## Key Questions We're Asking

1. **RLS Policies:** Can an unprivileged user read data they shouldn't? Specifically:
   - Can user A read user B's email from the users table?
   - Can user A see private messages they're not part of?
   - Can user A modify posts they don't own?

2. **Auth Flow:** Is the authentication process robust?
   - Can password resets be used multiple times?
   - Is there a rate limit on password reset attempts?
   - Can tokens be used past their expiration?
   - Is biometric auth properly secured?

3. **Encryption:** Is E2E actually end-to-end?
   - Where are encryption keys stored?
   - Can device compromise leak all past messages?
   - Is key rotation supported?
   - Are keys backed up/synchronized? (risks?)

4. **Rate Limiting:** Are we adequately protected from brute force?
   - What's the current rate limit configuration?
   - Is it enforced consistently across all endpoints?
   - Can it handle 10K requests/second?

5. **Offline Sync:** Does offline support create vulnerabilities?
   - Can syncing offline data conflict with cloud?
   - Could data corruption occur?
   - Are conflicts resolved safely?

6. **Supply Chain:** Can we trust our dependencies?
   - Are all packages from trusted sources?
   - Any known vulnerabilities in used versions?
   - Should we pin all versions?
   - Status of `nearby_connections` library (P2P mesh)?

7. **Infrastructure:** Are secret credentials exposed?
   - Firebase API keys in source control?
   - Supabase admin keys in version history?
   - Environment variable handling secure?

8. **Compliance:** Are we ready for app store review?
   - Apple's privacy policy requirements met?
   - Google Play Store security requirements met?
   - GDPR compliance (for EU users)?

9. **Testing:** What are we missing?
   - No security tests in CI/CD?
   - No pen testing?
   - No vulnerability scanning?

10. **Scalability:** Can security hold at 10K+ users?
    - Rate limits adequate for peak load?
    - Database security at scale?
    - Cache poisoning risks?

---

## Technical Details

### Application Architecture
- **Frontend:** Flutter (Dart) for iOS/Android
- **Backend:** Supabase (PostgreSQL + Auth)
- **Storage:** Firebase Cloud Storage + Hive (local)
- **Real-time:** Supabase Realtime (WebSocket subscriptions)
- **P2P:** Nearby Connections (Bluetooth Mesh for offline)

### Key Endpoints
```
POST /auth/v1/signup - User registration
POST /auth/v1/token - Login/token exchange
POST /api/rpc/update_profile - Profile updates (RLS protected)
GET /rest/v1/posts - Feed (paginated, user-visible only)
POST /rest/v1/messages - Send encrypted message
WS /realtime/v1/* - Realtime subscriptions
```

### Sensitive Data
- User email (authentication, password recovery)
- User passwords (must be hashed)
- Encryption keys (must be secure)
- Payment info (none currently, will be added in Phase 11)
- Direct messages (encrypted)
- Location data (from Bluetooth mesh)

### Compliance Requirements
- GDPR (EU data privacy)
- CCPA (California data privacy)
- Apple App Store privacy policy
- Google Play Store privacy policy

---

## Credentials & Access

**What we'll provide to the audit firm:**

1. **Supabase Admin Access** (read-only preferred)
   - URL: https://xxxxx.supabase.co
   - API Key: [will provide securely]
   - Database: PostgreSQL (pg_dumpable for structure review)

2. **Firebase Project Access** (if needed)
   - Project ID: xxxxx
   - Role: Auditor (read-only)

3. **Source Code Access** (GitHub)
   - Private repo link
   - Read-only access
   - ~50K lines of Dart code

4. **Test Credentials**
   - Test user account (non-real, for pen testing)
   - Email: audit-test@verasso.local
   - Password: [will provide]

5. **Test Environment** (optional)
   - Staging Supabase project (separate from production)
   - Test data: 100 users, 500 messages, etc.

---

## Timeline & Milestones

| Week | Deliverable | Status |
|------|-------------|--------|
| Feb 24-28 | RLS policy audit + initial findings | In Progress |
| Mar 3-7 | Auth flow testing + encryption review | In Progress |
| Mar 7-10 | Final report + remediation plan | Awaiting |

---

## Budget Breakdown

| Item | Cost | Notes |
|------|------|-------|
| RLS Policy Audit (20 hours @ $250/hr) | $5,000 | Includes write-up |
| Auth Flow Testing (included) | — | Covered in above |
| Encryption Review (included) | — | Covered in above |
| **Total** | **$5,000 USD** | — |

Additional options (if budget increases):
- Full source code review: +$3,000
- Penetration testing (24 hours): +$6,000
- Post-audit retesting: +$1,500

---

## Confidentiality & NDA

- Audit findings are confidential
- Report shared only with core team
- Proof of fix shared with auditor for retesting
- No public disclosure without consent

---

## Contact & Next Steps

**To submit a proposal, please provide:**

1. Audit team credentials & experience
2. Proposed timeline (must fit 2-week window)
3. Access requirements (what data do you need?)
4. Deliverable samples (show example reports)
5. References (2-3 prior audits)
6. Insurance/liability coverage

**Timeline:**
- Deadline to submit proposal: Feb 22, 2026
- Selection: Feb 23, 2026
- Work begins: Feb 24, 2026
- Final report: Mar 10, 2026

---

**Prepared by:** VERASSO Product Security Team  
**Date:** February 18, 2026  
**Status:** Ready for distribution to audit firms
