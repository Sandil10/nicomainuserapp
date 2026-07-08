import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  // Only publishable key in Flutter (safe)
  static const String _publishableKey =
      'pk_live_51SGwIqGmjuqXfvWlh3OdxRkOoIjK7gA0BqzF8y0wucLTvraewHKbUSJCLEWpQPg2q8KHiJ5niYgY81l0ikDmT6WZ00kqojEwol';

  // Firebase Function URL
  static const String _firebaseFunctionUrl =
      'https://us-central1-aquaflow-q4fcn.cloudfunctions.net/createPaymentIntent';

  /// Initialize Stripe
  static Future<bool> initialize() async {
    try {
      Stripe.publishableKey = _publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.example.app';
      Stripe.urlScheme = 'flutterstripepayment';
      await Stripe.instance.applySettings();
      print('✅ Stripe initialized successfully');
      debugStripeConfig();
      return true;
    } catch (e) {
      print('❌ Stripe initialization failed: $e');
      return false;
    }
  }

  /// Convert amount to cents
  static int amountToCents(double amount) {
    return (amount * 100).round(); // no .toString()
  }

  /// Create PaymentIntent (used by your StripePaymentScreen)
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount, // ✅ change to int
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_firebaseFunctionUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "amount": amount,
          "currency": currency,
          "metadata": metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'client_secret': data['clientSecret'],
          'id': data['id'],
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Error creating payment intent: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('💥 createPaymentIntent failed: $e');
      rethrow;
    }
  }

  /// Process payment using Payment Sheet
  static Future<bool> processPaymentWithSheet({
    required String clientSecret,
    required BuildContext context,
    double? amount,
  }) async {
    try {
      if (Stripe.publishableKey == null || Stripe.publishableKey!.isEmpty) {
        final initialized = await initialize();
        if (!initialized) throw Exception('Stripe not initialized');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Nico Online Mart',
          style: ThemeMode.system,
          customFlow: false,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      print('✅ Payment completed successfully!');
      return true;
    } on StripeException catch (e) {
      print(
          '💥 StripeException: ${e.error.code} - ${e.error.localizedMessage}');
      if (e.error.code == FailureCode.Canceled) return false;
      throw Exception(e.error.localizedMessage ?? 'Payment failed.');
    } catch (e) {
      print('💥 Unexpected error: $e');
      throw Exception('Payment processing failed: $e');
    }
  }

  /// Debug method to check Stripe config
  static void debugStripeConfig() {
    print('🔍 Stripe Debug Info:');
    print('   Publishable key set: ${Stripe.publishableKey != null}');
    if (Stripe.publishableKey != null) {
      print('   Key preview: ${Stripe.publishableKey!.substring(0, 20)}...');
      print(
          '   Key starts with pk_test: ${Stripe.publishableKey!.startsWith('pk_test_')}');
    }
    print('   Merchant identifier: ${Stripe.merchantIdentifier}');
    print('   URL scheme: ${Stripe.urlScheme}');
  }
}
