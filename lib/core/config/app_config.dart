/// Global configuration for the Verasso application.
///
/// This class provides static access to environment-defined variables
/// and handles configuration validation for production builds.
class AppConfig {
  /// The base URL for the Supabase API.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fdsxklbqjgxfkxebybrn.supabase.co',
  );

  /// The anonymous public key for Supabase authentication.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkc3hrbGJxamd4Zmt4ZWJ5YnJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMzU4NDMsImV4cCI6MjA4NzcxMTg0M30.k_sD0IJdqCI9dIMX-zQHqfg2wFnrOJ7KiFwa8RkMMuI',
  );

  /// The API key for Google Gemini AI services.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// The Key ID for Razorpay payments.
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  /// Whether to enable incomplete beta modules for testing.
  static const bool enableBetaModules = bool.fromEnvironment(
    'ENABLE_BETA_MODULES',
    defaultValue: false,
  );

  /// Certificate pinning configuration
  /// These are SHA256 public key pins for Supabase API
  /// IMPORTANT: Request actual pins from Supabase support at:
  /// https://supabase.com/support or via your account dashboard
  ///
  /// Primary pins (current certificates)
  static const List<String> supabaseCertificatePins = [
    // Format: "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    // Actual pins should be obtained from Supabase support for production
  ];

  /// Backup certificate pins for graceful rotation
  static const List<String> supabaseBackupPins = [
    // Add backup pins here before scheduled certificate rotations
  ];

  /// Combined list of all trusted pins.
  static List<String> get allCertificatePins => [
        ...supabaseCertificatePins,
        ...supabaseBackupPins
      ].where((pin) => pin.isNotEmpty).toList();

  /// Validates that the current configuration is safe for the detected environment.
  ///
  /// Throws an [Exception] if critical environment variables are missing in production.
  static Future<void> validateConfig() async {
    const isProduction =
        bool.fromEnvironment('dart.vm.product', defaultValue: false);
    const hasEnvironmentDefinedUrl = bool.hasEnvironment('SUPABASE_URL');
    const hasEnvironmentDefinedKey = bool.hasEnvironment('SUPABASE_ANON_KEY');

    if (isProduction) {
      if (!hasEnvironmentDefinedUrl || !hasEnvironmentDefinedKey) {
        throw Exception(
          'CRITICAL SECURITY ERROR: Production builds MUST provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define. '
          'Defaulting to embedded keys is disabled in production for security.',
        );
      }
    }

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'Supabase configuration missing. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are provided via --dart-define');
    }
  }
}
