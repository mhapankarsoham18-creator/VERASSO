# store Preparation Guide: Verasso v1.2.0

This guide outlines the assets and metadata required for submitting Verasso to the Apple App Store and Google Play Store.

## 1. App Store Metadata (iOS)

- **App Name**: Verasso
- **Subtitle**: Secure Social-Learning Ecosystem
- **Category**: Education / Social Networking
- **Keywords**: learning, social, privacy, e2ee, secure messaging, student, mentor

## 2. Play Store Metadata (Android)

- **Short Description**: A unified ecosystem for secure social learning.
- **Full Description**: Verasso brings students and mentors together in a secure environment. Featuring End-to-End Encrypted messaging, real-time collaboration, and community-driven learning modules.

## 3. Required Graphics

- **App Icon**: 1024x1024px (provided in `assets/images/app_icon.jpeg`)
- **Screenshots**:
  - **Auth**: OTP Login & MFA Enrollment.
  - **Learning**: Physics Lab simulation.
  - **Social**: Discover feed & Group chat.
  - **Profile**: Trust Score & Achievement Badges.

## 4. Launch Checklist

- [ ] Verify `PRIVACY_POLICY.md` URL is reachable.
- [ ] Confirm `TERMS_OF_SERVICE.md` link is in Settings.
- [ ] Run `flutter build appbundle` for Android.
- [ ] Run `flutter build ipa` for iOS.
