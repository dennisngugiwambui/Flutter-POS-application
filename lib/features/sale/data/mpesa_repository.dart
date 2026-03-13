import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of polling for STK callback.
class MpesaStkResult {
  final bool success;
  final String message;
  final int resultCode;

  const MpesaStkResult({required this.success, required this.message, this.resultCode = -1});
}

/// Initiates STK push via Edge Function and polls for callback result.
class MpesaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int _pollIntervalSeconds = 2;
  static const int _maxPollAttempts = 45; // ~90 seconds

  /// Invoke Edge Function to send STK push, then poll mpesa_callback_results for outcome.
  Future<MpesaStkResult> initiateStkPush({
    required double amount,
    required String phone,
    String reference = 'POS',
  }) async {
    final res = await _supabase.functions.invoke(
      'mpesa-stk-push',
      body: {
        'amount': amount,
        'phone': phone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0'), '254'),
        'reference': reference,
      },
    );

    if (res.status != 200) {
      final err = res.data is Map ? (res.data['error'] ?? res.data['detail'] ?? res.data) : res.data;
      return MpesaStkResult(
        success: false,
        message: err?.toString() ?? 'STK push request failed',
      );
    }

    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      return MpesaStkResult(
        success: false,
        message: data?['error']?.toString() ?? data?['message']?.toString() ?? 'No checkout ID',
      );
    }

    final checkoutRequestId = data['checkoutRequestId']?.toString();
    if (checkoutRequestId == null || checkoutRequestId.isEmpty) {
      return MpesaStkResult(success: false, message: 'No checkout request ID returned');
    }

    return _pollForResult(checkoutRequestId);
  }

  Future<MpesaStkResult> _pollForResult(String checkoutRequestId) async {
    for (var i = 0; i < _maxPollAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: _pollIntervalSeconds));

      final response = await _supabase
          .from('mpesa_callback_results')
          .select('result_code, result_desc')
          .eq('checkout_request_id', checkoutRequestId)
          .maybeSingle();

      if (response != null) {
        final code = response['result_code'] is int
            ? response['result_code'] as int
            : int.tryParse(response['result_code']?.toString() ?? '') ?? -1;
        final desc = response['result_desc']?.toString() ?? '';
        return MpesaStkResult(
          success: code == 0,
          message: desc.isEmpty ? (code == 0 ? 'Payment successful' : 'Payment failed') : desc,
          resultCode: code,
        );
      }
    }

    return const MpesaStkResult(
      success: false,
      message: 'Payment timed out. Ask customer to check phone or try again.',
      resultCode: -2,
    );
  }
}
