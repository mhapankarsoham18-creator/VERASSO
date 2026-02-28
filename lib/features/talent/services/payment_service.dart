import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [PaymentService] instance.
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Service responsible for handling payments (Phase 4 - Stubbed).
class PaymentService {
  final SupabaseClient _client;

  /// Creates a [PaymentService] instance.
  PaymentService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Initializes Stripe with the publishable key.
  Future<void> initialize(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    // Stripe.instance.applySettings() is handled internally or via specific calls if needed.
    // In v12, setting publishableKey is often enough for simple cases.
    AppLogger.info('Stripe initialized');
  }

  /// Creates a Payment Intent via a Supabase Edge Function and presents the Payment Sheet.
  ///
  /// Processes a payment for a specific job.
  Future<bool> processPayment({
    required String jobId,
    required double amount,
    required String currency,
    required String talentUserId,
  }) async {
    // STUB: Payment service is coming soon.
    AppLogger.info('Payment service is coming soon. Job: $jobId');
    return true; // Simulate success for now
    /*
    try {
      // 1. Call Supabase Edge Function to create Payment Intent
      // In production, this would securely interact with Stripe API using secrets.
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {
          'jobId': jobId,
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': currency.toLowerCase(),
          'talentId': talentUserId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create payment intent: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final paymentIntentClientSecret = data['clientSecret'];
      final ephemeralKeySecret = data['ephemeralKey'];
      final customerId = data['customer'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          customerEphemeralKeySecret: ephemeralKeySecret,
          customerId: customerId,
          merchantDisplayName: 'VERASSO Marketplace',
          style: ThemeMode.dark,
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      AppLogger.info('Payment successful for job: $jobId');
      return true;
    } on StripeException catch (e) {
      AppLogger.error('Stripe payment failed', error: e);
      return false;
    } catch (e, stack) {
      AppLogger.error('Payment processing failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return false;
    }
    */
  }

  /// Records a successful payment/transaction in the Supabase 'transactions' table.
  Future<void> recordTransaction({
    required String jobId,
    required double amount,
    required String currency,
    required String status,
    required String paymentMethod,
  }) async {
    try {
      await _client.from('transactions').insert({
        'job_id': jobId,
        'user_id': _client.auth.currentUser?.id,
        'amount': amount,
        'currency': currency,
        'status': status,
        'payment_method': paymentMethod,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.error('Failed to record transaction', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}
