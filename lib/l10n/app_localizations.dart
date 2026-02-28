import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Verasso'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @privateAccount.
  ///
  /// In en, this message translates to:
  /// **'Private Account'**
  String get privateAccount;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @connectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get connectivity;

  /// No description provided for @privacyLegal.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Legal'**
  String get privacyLegal;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @themeForge.
  ///
  /// In en, this message translates to:
  /// **'Theme Forge'**
  String get themeForge;

  /// No description provided for @powerSaveMode.
  ///
  /// In en, this message translates to:
  /// **'Power Save Mode'**
  String get powerSaveMode;

  /// No description provided for @meshNetwork.
  ///
  /// In en, this message translates to:
  /// **'Mesh Network'**
  String get meshNetwork;

  /// No description provided for @learningHub.
  ///
  /// In en, this message translates to:
  /// **'Learning Hub'**
  String get learningHub;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// No description provided for @dailyChallengeShort.
  ///
  /// In en, this message translates to:
  /// **'Short Challenge'**
  String get dailyChallengeShort;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @discoverPeopleIdeas.
  ///
  /// In en, this message translates to:
  /// **'Discover people & ideas...'**
  String get discoverPeopleIdeas;

  /// No description provided for @exploreCommunity.
  ///
  /// In en, this message translates to:
  /// **'Explore Community'**
  String get exploreCommunity;

  /// No description provided for @suggestedForYou.
  ///
  /// In en, this message translates to:
  /// **'Suggested for you'**
  String get suggestedForYou;

  /// No description provided for @subjectCommunities.
  ///
  /// In en, this message translates to:
  /// **'Subject Communities'**
  String get subjectCommunities;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @negotiate.
  ///
  /// In en, this message translates to:
  /// **'Negotiate'**
  String get negotiate;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @mentors.
  ///
  /// In en, this message translates to:
  /// **'Mentors'**
  String get mentors;

  /// No description provided for @becomeAMentor.
  ///
  /// In en, this message translates to:
  /// **'Become a Mentor'**
  String get becomeAMentor;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @professionalProfile.
  ///
  /// In en, this message translates to:
  /// **'Professional Profile'**
  String get professionalProfile;

  /// No description provided for @postMoment.
  ///
  /// In en, this message translates to:
  /// **'Post a Moment'**
  String get postMoment;

  /// No description provided for @publishArticle.
  ///
  /// In en, this message translates to:
  /// **'Publish Article'**
  String get publishArticle;

  /// No description provided for @talentEcosystem.
  ///
  /// In en, this message translates to:
  /// **'Talent Ecosystem'**
  String get talentEcosystem;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired: Locking App'**
  String get sessionExpired;

  /// No description provided for @sessionWarning.
  ///
  /// In en, this message translates to:
  /// **'Session Expire Warning'**
  String get sessionWarning;

  /// No description provided for @stayLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Stay Logged In'**
  String get stayLoggedIn;

  /// No description provided for @privateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only followers can see your activities'**
  String get privateAccountSubtitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @checkingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Checking privacy settings'**
  String get checkingPrivacy;

  /// No description provided for @failedLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings'**
  String get failedLoadSettings;

  /// No description provided for @allowPersonalPosts.
  ///
  /// In en, this message translates to:
  /// **'Allow Personal Posts by Default'**
  String get allowPersonalPosts;

  /// No description provided for @personalPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Newly added friends can see your personal posts'**
  String get personalPostsSubtitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts for new activity'**
  String get pushNotificationsSubtitle;

  /// No description provided for @snapshotPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Privacy'**
  String get snapshotPrivacy;

  /// No description provided for @snapshotPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blur screen when app is backgrounded'**
  String get snapshotPrivacySubtitle;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @dataManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export or delete your personal data'**
  String get dataManagementSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @aboutVerasso.
  ///
  /// In en, this message translates to:
  /// **'About Verasso'**
  String get aboutVerasso;

  /// No description provided for @sessionExpireBody.
  ///
  /// In en, this message translates to:
  /// **'Your session is about to expire due to inactivity.'**
  String get sessionExpireBody;

  /// No description provided for @initializationComplete.
  ///
  /// In en, this message translates to:
  /// **'Initialization Complete'**
  String get initializationComplete;

  /// No description provided for @securityAlert.
  ///
  /// In en, this message translates to:
  /// **'Security Alert'**
  String get securityAlert;

  /// No description provided for @deviceCompromisedBody.
  ///
  /// In en, this message translates to:
  /// **'This device appears to be compromised (rooted/jailbroken).\n\nFor your security, Verasso cannot run in this environment.'**
  String get deviceCompromisedBody;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Detector'**
  String get bugReportTitle;

  /// No description provided for @bugReportHelpText.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Verasso! Valid reports earn 1000 XP and a special badge.'**
  String get bugReportHelpText;

  /// No description provided for @bugTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bugTitle;

  /// No description provided for @bugCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get bugCategory;

  /// No description provided for @reproductionSteps.
  ///
  /// In en, this message translates to:
  /// **'Reproduction Steps'**
  String get reproductionSteps;

  /// No description provided for @transmitting.
  ///
  /// In en, this message translates to:
  /// **'Transmitting...'**
  String get transmitting;

  /// No description provided for @logAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Log Anomaly'**
  String get logAnomaly;

  /// No description provided for @anomalyNeutralized.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Neutralized! ⚡'**
  String get anomalyNeutralized;

  /// No description provided for @dataLogged.
  ///
  /// In en, this message translates to:
  /// **'Data Logged'**
  String get dataLogged;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get usernameTaken;

  /// No description provided for @useMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Use Master Password'**
  String get useMasterPassword;

  /// No description provided for @verifyWithTemporalCode.
  ///
  /// In en, this message translates to:
  /// **'Verify with Temporal Code'**
  String get verifyWithTemporalCode;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get authenticationError;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @verifyBackup.
  ///
  /// In en, this message translates to:
  /// **'Verify Backup'**
  String get verifyBackup;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @accessingMesh.
  ///
  /// In en, this message translates to:
  /// **'Accessing Mesh...'**
  String get accessingMesh;

  /// No description provided for @initializingNeuralPath.
  ///
  /// In en, this message translates to:
  /// **'Initializing Neural Path...'**
  String get initializingNeuralPath;

  /// No description provided for @cooldownMessage.
  ///
  /// In en, this message translates to:
  /// **'Rate limited. Retry in {seconds}s'**
  String cooldownMessage(Object seconds);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Auth'**
  String get biometricAuth;

  /// No description provided for @enterBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Backup Code'**
  String get enterBackupCode;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @verassoUser.
  ///
  /// In en, this message translates to:
  /// **'Verasso User'**
  String get verassoUser;

  /// No description provided for @defaultUsername.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get defaultUsername;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @talentShowcase.
  ///
  /// In en, this message translates to:
  /// **'Talent Showcase'**
  String get talentShowcase;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @savedContent.
  ///
  /// In en, this message translates to:
  /// **'Saved Content'**
  String get savedContent;

  /// No description provided for @physicsLab.
  ///
  /// In en, this message translates to:
  /// **'Physics Lab'**
  String get physicsLab;

  /// No description provided for @financeHub.
  ///
  /// In en, this message translates to:
  /// **'Finance Hub'**
  String get financeHub;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @newsFeed.
  ///
  /// In en, this message translates to:
  /// **'News Feed'**
  String get newsFeed;

  /// No description provided for @classroomLabs.
  ///
  /// In en, this message translates to:
  /// **'Classroom & Labs'**
  String get classroomLabs;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get beta;

  /// No description provided for @sessionExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Session Expiring Soon'**
  String get sessionExpiringSoon;

  /// No description provided for @sessionExpireIn.
  ///
  /// In en, this message translates to:
  /// **'Your session will expire in:'**
  String get sessionExpireIn;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @alignQrCode.
  ///
  /// In en, this message translates to:
  /// **'Align the QR code within the frame to scan automatically.'**
  String get alignQrCode;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// No description provided for @strengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get strengthFair;

  /// No description provided for @strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @strengthVeryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very Strong'**
  String get strengthVeryStrong;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must contain: uppercase, lowercase, number, special character'**
  String get passwordRequirements;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @hintPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hint: {hint}'**
  String hintPrefix(Object hint);

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailTooLong.
  ///
  /// In en, this message translates to:
  /// **'Email is too long (max 254 characters)'**
  String get emailTooLong;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordNoUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain an uppercase letter'**
  String get passwordNoUppercase;

  /// No description provided for @passwordNoLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a lowercase letter'**
  String get passwordNoLowercase;

  /// No description provided for @passwordNoNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a number'**
  String get passwordNoNumber;

  /// No description provided for @passwordNoSpecial.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a special character'**
  String get passwordNoSpecial;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameTooShort;

  /// No description provided for @usernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Username must be at most 20 characters'**
  String get usernameTooLong;

  /// No description provided for @usernameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscore'**
  String get usernameInvalidChars;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be at most 50 characters'**
  String get nameTooLong;

  /// No description provided for @nameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Name can only contain letters, spaces, and hyphens'**
  String get nameInvalidChars;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String fieldRequired(Object fieldName);

  /// No description provided for @fieldTooShort.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} must be at least {minLength} characters'**
  String fieldTooShort(Object fieldName, Object minLength);

  /// No description provided for @fieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} must be at most {maxLength} characters'**
  String fieldTooLong(Object fieldName, Object maxLength);

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @phoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number must have at least 7 digits'**
  String get phoneTooShort;

  /// No description provided for @useRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Use Recovery Key'**
  String get useRecoveryKey;

  /// No description provided for @verifyTemporalCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Temporal Code'**
  String get verifyTemporalCode;

  /// No description provided for @resetAccess.
  ///
  /// In en, this message translates to:
  /// **'Reset Access'**
  String get resetAccess;

  /// No description provided for @welcomeBackPioneer.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Pioneer'**
  String get welcomeBackPioneer;

  /// No description provided for @initiateDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Initiate Discovery'**
  String get initiateDiscovery;

  /// No description provided for @recoveryKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter one of your 8-character recovery keys'**
  String get recoveryKeyBody;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @switchToAppOtp.
  ///
  /// In en, this message translates to:
  /// **'Switch to App OTP'**
  String get switchToAppOtp;

  /// No description provided for @sendMagicCode.
  ///
  /// In en, this message translates to:
  /// **'Send Magic Code'**
  String get sendMagicCode;

  /// No description provided for @checkUsername.
  ///
  /// In en, this message translates to:
  /// **'Check Username'**
  String get checkUsername;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @lostAuthApp.
  ///
  /// In en, this message translates to:
  /// **'Lost your authentication app?'**
  String get lostAuthApp;

  /// No description provided for @otpSentBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your terminal ({email})'**
  String otpSentBody(Object email);

  /// No description provided for @reestablishNeuralLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to re-establish neural link'**
  String get reestablishNeuralLink;

  /// No description provided for @reestablishingUplink.
  ///
  /// In en, this message translates to:
  /// **'Re-establishing data uplink'**
  String get reestablishingUplink;

  /// No description provided for @joinNeuralNetwork.
  ///
  /// In en, this message translates to:
  /// **'Join the global neural network'**
  String get joinNeuralNetwork;

  /// No description provided for @forgotPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordLabel;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String tooManyAttempts(Object seconds);

  /// No description provided for @loginWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometric'**
  String get loginWithBiometric;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// No description provided for @biometricLoginReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your Verasso account'**
  String get biometricLoginReason;

  /// No description provided for @otpSentFeedback.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your email'**
  String get otpSentFeedback;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get passwordResetSent;

  /// No description provided for @biometricVerified.
  ///
  /// In en, this message translates to:
  /// **'Biometric Signature Verified'**
  String get biometricVerified;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @recoverySuccessful.
  ///
  /// In en, this message translates to:
  /// **'Recovery Successful! Identity link established.'**
  String get recoverySuccessful;

  /// No description provided for @businessAndFinance.
  ///
  /// In en, this message translates to:
  /// **'Business & Finance'**
  String get businessAndFinance;

  /// No description provided for @financeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Educational only. Not investment advice. Not a brokerage platform.'**
  String get financeDisclaimer;

  /// No description provided for @financeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master business and finance concepts through interactive simulations'**
  String get financeSubtitle;

  /// No description provided for @roiSimulator.
  ///
  /// In en, this message translates to:
  /// **'ROI Simulator'**
  String get roiSimulator;

  /// No description provided for @economicsHub.
  ///
  /// In en, this message translates to:
  /// **'Economics Hub'**
  String get economicsHub;

  /// No description provided for @accountingSimulator.
  ///
  /// In en, this message translates to:
  /// **'Accounting Simulator'**
  String get accountingSimulator;

  /// No description provided for @businessWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Business Workflow'**
  String get businessWorkflow;

  /// No description provided for @portfolioTracker.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Tracker'**
  String get portfolioTracker;

  /// No description provided for @ledgerLogicAR.
  ///
  /// In en, this message translates to:
  /// **'LedgerLogic AR'**
  String get ledgerLogicAR;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get yourProgress;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get xpEarned;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get trustScore;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @noBioYet.
  ///
  /// In en, this message translates to:
  /// **'No bio added yet.'**
  String get noBioYet;

  /// No description provided for @noInterestsYet.
  ///
  /// In en, this message translates to:
  /// **'No interests listed.'**
  String get noInterestsYet;

  /// No description provided for @exportTranscript.
  ///
  /// In en, this message translates to:
  /// **'Export Verified Transcript'**
  String get exportTranscript;

  /// No description provided for @noVerifiedSkills.
  ///
  /// In en, this message translates to:
  /// **'No Verified Skills'**
  String get noVerifiedSkills;

  /// No description provided for @noVerifiedSkillsBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t earned any verified skill badges yet. Complete courses and pass assessments to generate your verified transcript.'**
  String get noVerifiedSkillsBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @verifiedTranscript.
  ///
  /// In en, this message translates to:
  /// **'Verified Transcript'**
  String get verifiedTranscript;

  /// No description provided for @verifiedTranscriptBody.
  ///
  /// In en, this message translates to:
  /// **'Your mastery levels have been cryptographically signed and are ready for institutional verification.'**
  String get verifiedTranscriptBody;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @roiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compound Interest & Investment Growth'**
  String get roiSubtitle;

  /// No description provided for @economicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supply, Demand & Market Dynamics'**
  String get economicsSubtitle;

  /// No description provided for @accountingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Double-Entry Bookkeeping & Financial Statements'**
  String get accountingSubtitle;

  /// No description provided for @businessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business Lifecycle & Management'**
  String get businessSubtitle;

  /// No description provided for @portfolioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mock Trading & Investment Portfolio'**
  String get portfolioSubtitle;

  /// No description provided for @ledgerLogicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Balance Sheet Simulation'**
  String get ledgerLogicSubtitle;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @transcriptCopied.
  ///
  /// In en, this message translates to:
  /// **'Transcript copied to clipboard'**
  String get transcriptCopied;

  /// No description provided for @feedGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get feedGlobal;

  /// No description provided for @feedFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// No description provided for @feedLabs.
  ///
  /// In en, this message translates to:
  /// **'Labs (Video)'**
  String get feedLabs;

  /// No description provided for @emptyFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Silence in the Neural Net'**
  String get emptyFeedTitle;

  /// No description provided for @emptyFeedMessage.
  ///
  /// In en, this message translates to:
  /// **'The feed is empty. Be the pioneer who sparks the conversation!'**
  String get emptyFeedMessage;

  /// No description provided for @loadMorePosts.
  ///
  /// In en, this message translates to:
  /// **'Load More Posts'**
  String get loadMorePosts;

  /// No description provided for @saveToCollection.
  ///
  /// In en, this message translates to:
  /// **'Save to Collection / Collaboration'**
  String get saveToCollection;

  /// No description provided for @collaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get collaboration;

  /// No description provided for @privateCollection.
  ///
  /// In en, this message translates to:
  /// **'Private Collection'**
  String get privateCollection;

  /// No description provided for @savedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Saved to {name}'**
  String savedToCollection(Object name);

  /// No description provided for @createNewCollection.
  ///
  /// In en, this message translates to:
  /// **'Create New Collection'**
  String get createNewCollection;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get newCollection;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection Name'**
  String get collectionName;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @muteUser.
  ///
  /// In en, this message translates to:
  /// **'Mute {name}'**
  String muteUser(Object name);

  /// No description provided for @userMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted {name}'**
  String userMuted(Object name);

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (e.g. Spam, Harassment)'**
  String get reportReasonHint;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @globalRankings.
  ///
  /// In en, this message translates to:
  /// **'Global Rankings'**
  String get globalRankings;

  /// No description provided for @karmaKings.
  ///
  /// In en, this message translates to:
  /// **'Karma Kings'**
  String get karmaKings;

  /// No description provided for @topMentors.
  ///
  /// In en, this message translates to:
  /// **'Top Mentors'**
  String get topMentors;

  /// No description provided for @champions.
  ///
  /// In en, this message translates to:
  /// **'Champions'**
  String get champions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
