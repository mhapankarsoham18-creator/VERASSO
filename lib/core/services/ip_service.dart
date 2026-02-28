import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to detect client IP address for security tracking
class IpService {
  static const String _ipCacheKey = 'cached_ip_address';
  static const String _ipCacheTimeKey = 'cached_ip_timestamp';
  static const Duration _cacheValidity = Duration(hours: 1);

  /// Get the client's public IP address
  /// Returns cached IP if available and valid, otherwise fetches from API
  Future<String> getClientIpAddress() async {
    try {
      // Try to get cached IP first
      final cachedIp = await _getCachedIp();
      if (cachedIp != null) {
        return cachedIp;
      }

      // Fetch fresh IP from multiple sources (fallback strategy)
      String? ipAddress = await _fetchIpFromApi();
      
      if (ipAddress != null) {
        await _cacheIp(ipAddress);
        return ipAddress;
      }

      // Fallback to local network IP
      return await _getLocalIpAddress();
    } catch (e) {
      // If all else fails, return a placeholder
      // This ensures the app doesn't crash, but logging will show 'unknown'
      return 'unknown';
    }
  }

  /// Fetch IP from public API (with timeout)
  Future<String?> _fetchIpFromApi() async {
    try {
      // Try primary API: ipify.org
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip'] as String?;
      }
    } catch (e) {
      // Primary API failed, try fallback
      try {
        final response = await http
            .get(Uri.parse('https://api.my-ip.io/ip'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          return response.body.trim();
        }
      } catch (fallbackError) {
        // Both APIs failed
        return null;
      }
    }
    return null;
  }

  /// Get local network IP address as fallback
  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Skip loopback address
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      // Fallback to loopback if network interfaces can't be accessed
      return '127.0.0.1';
    }

    return '127.0.0.1';
  }

  /// Get cached IP if still valid
  Future<String?> _getCachedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedIp = prefs.getString(_ipCacheKey);
      final cachedTime = prefs.getInt(_ipCacheTimeKey);

      if (cachedIp != null && cachedTime != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        final now = DateTime.now();

        if (now.difference(cacheDate) < _cacheValidity) {
          return cachedIp;
        }
      }
    } catch (e) {
      // If cache read fails, continue to fetch fresh IP
    }

    return null;
  }

  /// Cache IP address with timestamp
  Future<void> _cacheIp(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ipCacheKey, ipAddress);
      await prefs.setInt(_ipCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // If caching fails, it's not critical - continue without cache
    }
  }

  /// Clear cached IP (useful for testing or manual refresh)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ipCacheKey);
      await prefs.remove(_ipCacheTimeKey);
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  /// Get IP info (includes country, city, etc.) from api
  /// Useful for advanced security analytics
  Future<Map<String, dynamic>?> getIpInfo() async {
    try {
      final ip = await getClientIpAddress();
      
      if (ip == 'unknown' || ip == '127.0.0.1' || ip.startsWith('192.168.')) {
        return null;
      }

      final response = await http
          .get(Uri.parse('https://ipapi.co/$ip/json/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // If detailed info fails, it's okay - not critical
    }

    return null;
  }
}
