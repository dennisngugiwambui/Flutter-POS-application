import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sale/data/mpesa_repository.dart';
import '../settings/domain/shop_settings_model.dart';

final mpesaServiceProvider = Provider<MpesaService>((ref) => MpesaService());

/// High-level M-Pesa STK result for checkout and other flows.
class MpesaPayResult {
  final bool success;
  final String message;
  final String? errorMessage;
  final String? receiptNumber;
  final int resultCode;

  const MpesaPayResult({
    required this.success,
    required this.message,
    this.errorMessage,
    this.receiptNumber,
    this.resultCode = -1,
  });

  factory MpesaPayResult.fromStk(MpesaStkResult r) {
    return MpesaPayResult(
      success: r.success,
      message: r.message,
      errorMessage: r.success ? null : r.message,
      receiptNumber: r.receiptNumber,
      resultCode: r.resultCode,
    );
  }
}

/// Facade over [MpesaRepository] with settings checks, phone normalization, and status updates.
class MpesaService {
  MpesaService({MpesaRepository? repository}) : _repo = repository ?? MpesaRepository();

  final MpesaRepository _repo;

  /// Normalizes to digits starting with 254 (Daraja).
  static String normalizePhoneForDaraja(String phone) {
    var d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) {
      d = '254${d.substring(1)}';
    } else if (!d.startsWith('254')) {
      d = '254$d';
    }
    return d;
  }

  /// STK Lipa Na M-Pesa: Edge Function + poll [mpesa_callback_results].
  ///
  /// [settings] must have M-Pesa fields filled ([ShopSettingsModel.isMpesaConfigured]).
  /// [accountReference] is passed to Daraja (max 12 chars in Edge Function).
  Future<MpesaPayResult> pay({
    required String phone,
    required double amount,
    required ShopSettingsModel settings,
    required String accountReference,
    void Function(String message)? onStatusUpdate,
  }) async {
    if (!settings.isMpesaConfigured) {
      return const MpesaPayResult(
        success: false,
        message: '',
        errorMessage:
            'M-Pesa is not configured. Add Consumer Key, Secret, Passkey, Till/Shortcode, and Callback URL in Shop Settings.',
        resultCode: -3,
      );
    }

    final ref = accountReference.length > 12 ? accountReference.substring(0, 12) : accountReference;
    final normalized = normalizePhoneForDaraja(phone);

    final stk = await _repo.initiateStkPush(
      amount: amount,
      phone: normalized,
      reference: ref.isEmpty ? 'POS' : ref,
      mpesaConfig: settings.toJson(),
      onStatusUpdate: onStatusUpdate,
    );

    return MpesaPayResult.fromStk(stk);
  }
}
