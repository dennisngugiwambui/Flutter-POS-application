import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/shop_settings_model.dart';

class SettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ShopSettingsModel> getSettings() async {
    final response = await _supabase
        .from('shop_configs')
        .select()
        .maybeSingle();

    // Base M-Pesa config you shared (used as fallback when DB fields are empty)
    const _defaultConsumerKey = '4aEia8VMAGLQU28ZoorLQRZtMutc6A6GyGXMq9HYoNFyXNOY';
    const _defaultConsumerSecret = 'wMdKEDv2y2JZQ8ZdN1TAn4MgxbuILwrNsOu4ywi6QcVZJw4BrlEclAcW4XSduSlw';
    const _defaultShortcode = '3560959';
    const _defaultTillNumber = '6509715';
    const _defaultPasskey = 'fc087de2729c7ff67b2b2b3aacc2068039fc56284c676d56679ef86f70640d8d';
    const _defaultCallbackUrl = 'https://www.pixelsolutions.co.ke/api/mpesa/callback';
    const _defaultConfirmationUrl = 'https://www.pixelsolutions.co.ke/api/mpesa/c2b/confirmation';
    const _defaultValidationUrl = 'https://www.pixelsolutions.co.ke/api/mpesa/c2b/validation';
    const _defaultBaseUrl = 'https://api.safaricom.co.ke';

    if (response == null) {
      // First-time setup: seed the config entirely from your live M‑Pesa values.
      final seeded = ShopSettingsModel(
        shopName: 'Pixel POS',
        mpesaConsumerKey: _defaultConsumerKey,
        mpesaConsumerSecret: _defaultConsumerSecret,
        mpesaShortcode: _defaultShortcode,
        mpesaTillNumber: _defaultTillNumber,
        mpesaPasskey: _defaultPasskey,
        mpesaBaseUrl: _defaultBaseUrl,
        mpesaCallbackUrl: _defaultCallbackUrl,
        mpesaConfirmationUrl: _defaultConfirmationUrl,
        mpesaValidationUrl: _defaultValidationUrl,
        mpesaTransactionType: 'CustomerBuyGoodsOnline',
        mpesaIsSandbox: false,
      );
      await _supabase.from('shop_configs').insert(seeded.toJson());
      return seeded;
    }

    // Merge existing row with defaults so the form is always prefilled.
    final base = ShopSettingsModel.fromJson(response);

    final merged = ShopSettingsModel(
      shopName: base.shopName,
      logoUrl: base.logoUrl,
      poBox: base.poBox,
      address: base.address,
      phoneNumber: base.phoneNumber,
      mpesaShortcode: base.mpesaShortcode.isNotEmpty ? base.mpesaShortcode : _defaultShortcode,
      mpesaPasskey: base.mpesaPasskey.isNotEmpty ? base.mpesaPasskey : _defaultPasskey,
      mpesaConsumerKey: base.mpesaConsumerKey.isNotEmpty ? base.mpesaConsumerKey : _defaultConsumerKey,
      mpesaConsumerSecret: base.mpesaConsumerSecret.isNotEmpty ? base.mpesaConsumerSecret : _defaultConsumerSecret,
      mpesaTillNumber: base.mpesaTillNumber.isNotEmpty ? base.mpesaTillNumber : _defaultTillNumber,
      mpesaBaseUrl: base.mpesaBaseUrl.isNotEmpty ? base.mpesaBaseUrl : _defaultBaseUrl,
      mpesaCallbackUrl: base.mpesaCallbackUrl.isNotEmpty ? base.mpesaCallbackUrl : _defaultCallbackUrl,
      mpesaConfirmationUrl: base.mpesaConfirmationUrl.isNotEmpty ? base.mpesaConfirmationUrl : _defaultConfirmationUrl,
      mpesaValidationUrl: base.mpesaValidationUrl.isNotEmpty ? base.mpesaValidationUrl : _defaultValidationUrl,
      mpesaTransactionType: base.mpesaTransactionType.isNotEmpty ? base.mpesaTransactionType : 'CustomerBuyGoodsOnline',
      mpesaIsSandbox: base.mpesaIsSandbox,
      printerType: base.printerType,
    );

    // If we had to inject any defaults, persist them back so next load is pure DB.
    if (merged.toJson().toString() != base.toJson().toString()) {
      await updateSettings(merged);
    }

    return merged;
  }

  Future<void> updateSettings(ShopSettingsModel settings) async {
    // Check if config exists
    final existing = await _supabase.from('shop_configs').select('id').maybeSingle();
    
    if (existing == null) {
      await _supabase.from('shop_configs').insert(settings.toJson());
    } else {
      await _supabase
          .from('shop_configs')
          .update(settings.toJson())
          .eq('id', existing['id']);
    }
  }
}
