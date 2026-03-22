bool _parseBool(dynamic v) {
  if (v == true) return true;
  if (v == false || v == null) return false;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

class ShopSettingsModel {
  final String shopName;
  final String logoUrl;
  final String poBox;
  final String address;
  final String phoneNumber;
  final String mpesaShortcode;
  final String mpesaPasskey;
  final String mpesaConsumerKey;
  final String mpesaConsumerSecret;
  final String mpesaTillNumber;
  final String mpesaBaseUrl;
  final String mpesaCallbackUrl;
  final String mpesaConfirmationUrl;
  final String mpesaValidationUrl;
  final String mpesaTransactionType;
  final bool mpesaIsSandbox;
  final String printerType;

  ShopSettingsModel({
    required this.shopName,
    this.logoUrl = '',
    this.poBox = '',
    this.address = '',
    this.phoneNumber = '',
    this.mpesaShortcode = '',
    this.mpesaPasskey = '',
    this.mpesaConsumerKey = '',
    this.mpesaConsumerSecret = '',
    this.mpesaTillNumber = '',
    this.mpesaBaseUrl = 'https://api.safaricom.co.ke',
    this.mpesaCallbackUrl = '',
    this.mpesaConfirmationUrl = '',
    this.mpesaValidationUrl = '',
    this.mpesaTransactionType = 'CustomerBuyGoodsOnline',
    this.mpesaIsSandbox = false,
    this.printerType = 'standard',
  });

  factory ShopSettingsModel.fromJson(Map<String, dynamic> json) {
    return ShopSettingsModel(
      shopName: json['shop_name'] ?? 'Pixel POS',
      logoUrl: json['logo_url'] ?? '',
      poBox: json['po_box'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      mpesaShortcode: json['mpesa_shortcode']?.toString() ?? '',
      mpesaPasskey: json['mpesa_passkey']?.toString() ?? '',
      mpesaConsumerKey: json['mpesa_consumer_key']?.toString() ?? '',
      mpesaConsumerSecret: json['mpesa_consumer_secret']?.toString() ?? '',
      mpesaTillNumber: json['mpesa_till_number']?.toString() ?? '',
      mpesaBaseUrl: json['mpesa_base_url']?.toString() ?? 'https://api.safaricom.co.ke',
      mpesaCallbackUrl: json['mpesa_callback_url']?.toString() ?? '',
      mpesaConfirmationUrl: json['mpesa_confirmation_url']?.toString() ?? '',
      mpesaValidationUrl: json['mpesa_validation_url']?.toString() ?? '',
      mpesaTransactionType: json['mpesa_transaction_type']?.toString() ?? 'CustomerBuyGoodsOnline',
      mpesaIsSandbox: _parseBool(json['mpesa_is_sandbox']),
      printerType: json['printer_type']?.toString() ?? 'standard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_name': shopName,
      'logo_url': logoUrl,
      'po_box': poBox,
      'address': address,
      'phone_number': phoneNumber,
      'mpesa_shortcode': mpesaShortcode,
      'mpesa_passkey': mpesaPasskey,
      'mpesa_consumer_key': mpesaConsumerKey,
      'mpesa_consumer_secret': mpesaConsumerSecret,
      'mpesa_till_number': mpesaTillNumber,
      'mpesa_base_url': mpesaBaseUrl,
      'mpesa_callback_url': mpesaCallbackUrl,
      'mpesa_confirmation_url': mpesaConfirmationUrl,
      'mpesa_validation_url': mpesaValidationUrl,
      'mpesa_transaction_type': mpesaTransactionType,
      'mpesa_is_sandbox': mpesaIsSandbox,
      'printer_type': printerType,
    };
  }

  /// Whether M-Pesa STK is configured enough to call the API
  bool get isMpesaConfigured =>
      mpesaConsumerKey.isNotEmpty &&
      mpesaConsumerSecret.isNotEmpty &&
      mpesaPasskey.isNotEmpty &&
      (mpesaTillNumber.isNotEmpty || mpesaShortcode.isNotEmpty) &&
      mpesaCallbackUrl.isNotEmpty;
}
