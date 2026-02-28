import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_security_service.dart';
import 'token_storage_service.dart';

/// Provider for the [OfflineSecurityService].
final offlineSecurityServiceProvider = Provider<OfflineSecurityService>((ref) {
  return OfflineSecurityService();
});

/// Provider for the [TokenStorageService], managing secure persistence of auth tokens.
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});
