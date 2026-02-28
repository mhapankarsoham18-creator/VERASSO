import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../monitoring/app_logger.dart';
import '../monitoring/sentry_service.dart';
import '../security/pinned_http_client.dart';

/// Provider for the [SupabaseService] instance.
final supabaseServiceProvider = Provider((ref) => SupabaseService());

/// Service responsible for Supabase client initialization and access.
///
/// This service handles:
/// - Initializing Supabase with [AppConfig] credentials
/// - Configuring [PinnedHttpClient] for certificate pinning security
/// - Global access to the [SupabaseClient] instance
class SupabaseService {
  /// Access to the global [SupabaseClient] instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Initializes the Supabase client with security configurations.
  ///
  /// This must be called before using [client].
  /// Throws an exception if initialization fails.
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        httpClient: PinnedHttpClient(
          expectedHost: Uri.parse(AppConfig.supabaseUrl).host,
          allowedShas: AppConfig.allCertificatePins.isNotEmpty
              ? AppConfig.allCertificatePins
              : null,
        ),
      );

      AppLogger.info(
        'Supabase initialized successfully'
        '${AppConfig.allCertificatePins.isNotEmpty ? ' with certificate pinning' : ' (pinning not configured yet)'}',
      );
    } catch (e, stack) {
      AppLogger.error('Failed to initialize Supabase', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }
}
