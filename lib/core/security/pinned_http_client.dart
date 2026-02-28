import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Custom HTTP Client that implements SSL/TLS certificate pinning.
///
/// This provides an additional layer of security against Man-in-the-Middle (MitM)
/// attacks by ensuring the client only trusts a specific whitelist of
/// certificate fingerprints for a given host.
class PinnedHttpClient extends http.BaseClient {
  final http.Client _client;

  /// Creates a [PinnedHttpClient] with the specified host and allowed SHA-256 fingerprints.
  PinnedHttpClient({required String expectedHost, List<String>? allowedShas})
      : _client = _createPinnedClient(expectedHost, allowedShas);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request);
  }

  /// Validates a certificate against a list of allowed SHA-256 fingerprints.
  ///
  /// This is exposed for testing purposes.
  static bool validateCertificate(
    X509Certificate cert,
    String host,
    int port,
    String expectedHost,
    List<String>? allowedShas,
  ) {
    if (allowedShas == null || allowedShas.isEmpty) {
      return false;
    }

    if (host == expectedHost) {
      final sha256Fingerprint =
          sha256.convert(cert.der).toString().toLowerCase().replaceAll(':', '');

      for (final allowedSha in allowedShas) {
        final normalizedAllowedSha =
            allowedSha.toLowerCase().replaceAll(':', '');
        if (sha256Fingerprint == normalizedAllowedSha) {
          return true; // Pin match!
        }
      }
    }

    return false;
  }

  static http.Client _createPinnedClient(
      String expectedHost, List<String>? allowedShas) {
    // SECURITY IMPROVEMENT:
    // By creating a SecurityContext with withTrustedRoots: false,
    // we ensure that the standard OS trust check will fail for ALL hosts.
    // This forces badCertificateCallback to fire for EVERY connection,
    // allowing us to perform strict SHA-256 fingerprint verification
    // even for otherwise "valid" certificates.
    final context = SecurityContext(withTrustedRoots: false);

    final httpClient = HttpClient(context: context);

    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return validateCertificate(cert, host, port, expectedHost, allowedShas);
    };

    return IOClient(httpClient);
  }
}
