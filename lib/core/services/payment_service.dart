import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:verasso/core/config/app_config.dart';
import 'package:verasso/core/services/error_service.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [PaymentService].
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final error = ref.watch(errorServiceProvider);
  final service = PaymentService(error);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Service responsible for handling payment transactions via Razorpay.
class PaymentService {
  final Razorpay _razorpay;
  final ErrorService _errorService;

  /// Creates a [PaymentService] instance.
  PaymentService(this._errorService) : _razorpay = Razorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Initiates a payment checkout flow.
  ///
  /// [amount] is in the smallest currency unit (e.g., paise for INR).
  /// [description] is shown to the user on the checkout screen.
  /// [metadata] can contain order details like courseId, etc.
  Future<void> checkout({
    required int amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Create order on server side (Supabase RPC)
      // This ensures we have a record before the transaction starts
      final orderResponse =
          await SupabaseService.client.rpc('create_payment_order', params: {
        'amount': amount,
        'currency': 'INR',
        'metadata': metadata,
      });

      final String? orderId =
          orderResponse['sdk_order_id']; // ID from Razorpay server-side API

      final options = {
        'key': AppConfig.razorpayKeyId,
        'amount': amount,
        'name': 'Verasso',
        'order_id': orderId,
        'description': description,
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact': '', // To be filled from user profile
          'email': '', // To be filled from user profile
        },
        'external': {
          'wallets': ['paytm']
        },
        'notes': metadata ?? {},
      };

      _razorpay.open(options);
    } catch (e, stack) {
      _errorService.logError('Payment initiation failed', e, stack);
      rethrow;
    }
  }

  /// Disposes of the Razorpay instance.
  void dispose() {
    _razorpay.clear();
  }

  void _handleExternalWallet(dynamic response) {
    // Handle external wallet selection
  }

  void _handlePaymentError(dynamic response) {
    _errorService.logError(
      'Payment failed',
      'Code: ${response.code}, Message: ${response.message}',
      StackTrace.current,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment on server side
    try {
      await SupabaseService.client.rpc('verify_payment', params: {
        'payment_id': response.paymentId,
        'order_id': response.orderId,
        'signature': response.signature,
      });
      // Trigger UI update or navigation via a state provider if needed
    } catch (e, stack) {
      _errorService.logError('Payment verification failed', e, stack);
    }
  }
}
