import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../dashboard_provider.dart';
import '../domain/shop_settings_model.dart';
import 'settings_provider.dart';

class ShopSettingsPage extends ConsumerStatefulWidget {
  const ShopSettingsPage({super.key});

  @override
  ConsumerState<ShopSettingsPage> createState() => _ShopSettingsPageState();
}

class _ShopSettingsPageState extends ConsumerState<ShopSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _poBoxController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _mpesaShortcodeController;
  late TextEditingController _mpesaPasskeyController;
  late TextEditingController _mpesaConsumerKeyController;
  late TextEditingController _mpesaConsumerSecretController;
  late TextEditingController _mpesaTillNumberController;
  late TextEditingController _mpesaBaseUrlController;
  late TextEditingController _mpesaCallbackUrlController;
  bool _isLoading = false;
  String _logoUrl = '';
  bool _logoUploading = false;
  String _printerType = 'standard';
  String _mpesaTransactionType = 'CustomerBuyGoodsOnline';
  bool _mpesaIsSandbox = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _poBoxController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _mpesaShortcodeController = TextEditingController();
    _mpesaPasskeyController = TextEditingController();
    _mpesaConsumerKeyController = TextEditingController();
    _mpesaConsumerSecretController = TextEditingController();
    _mpesaTillNumberController = TextEditingController();
    _mpesaBaseUrlController = TextEditingController();
    _mpesaCallbackUrlController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsProvider.future);
    setState(() {
      _nameController.text = settings.shopName;
      _poBoxController.text = settings.poBox;
      _addressController.text = settings.address;
      _phoneController.text = settings.phoneNumber;
      _mpesaShortcodeController.text = settings.mpesaShortcode;
      _mpesaPasskeyController.text = settings.mpesaPasskey;
      _logoUrl = settings.logoUrl;
      _printerType = settings.printerType;
      _mpesaConsumerKeyController.text = settings.mpesaConsumerKey;
      _mpesaConsumerSecretController.text = settings.mpesaConsumerSecret;
      _mpesaTillNumberController.text = settings.mpesaTillNumber;
      _mpesaBaseUrlController.text = settings.mpesaBaseUrl;
      _mpesaCallbackUrlController.text = settings.mpesaCallbackUrl;
      _mpesaTransactionType = settings.mpesaTransactionType;
      _mpesaIsSandbox = settings.mpesaIsSandbox;
    });
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _logoUploading = true);
    try {
      final client = Supabase.instance.client;
      const path = 'logo.png';
      await client.storage.from('shop').upload(path, File(x.path), fileOptions: const FileOptions(upsert: true));
      final url = client.storage.from('shop').getPublicUrl(path);
      setState(() {
        _logoUrl = url;
        _logoUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo updated. Tap Save to apply.'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logoUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final settings = ShopSettingsModel(
        shopName: _nameController.text,
        logoUrl: _logoUrl,
        poBox: _poBoxController.text,
        address: _addressController.text,
        phoneNumber: _phoneController.text,
        mpesaShortcode: _mpesaShortcodeController.text.trim(),
        mpesaPasskey: _mpesaPasskeyController.text.trim(),
        mpesaConsumerKey: _mpesaConsumerKeyController.text.trim(),
        mpesaConsumerSecret: _mpesaConsumerSecretController.text.trim(),
        mpesaTillNumber: _mpesaTillNumberController.text.trim(),
        mpesaBaseUrl: _mpesaBaseUrlController.text.trim().isEmpty ? 'https://api.safaricom.co.ke' : _mpesaBaseUrlController.text.trim(),
        mpesaCallbackUrl: _mpesaCallbackUrlController.text.trim(),
        mpesaTransactionType: _mpesaTransactionType,
        mpesaIsSandbox: _mpesaIsSandbox,
        printerType: _printerType,
      );

      await ref.read(settingsRepositoryProvider).updateSettings(settings);
      ref.invalidate(settingsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated!')));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains("Could not find the 'mpesa_") || msg.contains('PGRST204')) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supabase database update needed'),
              content: const Text(
                'Your Supabase `shop_configs` table is missing the new M-Pesa columns. '
                'Open Supabase Dashboard → SQL Editor and run the migration `20260316000000_mpesa_full_config.sql`, '
                'then reopen the app and Save Settings again.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = ref.watch(profileProvider).maybeWhen(
          data: (p) => p?.role.toLowerCase() ?? '',
          orElse: () => '',
        );
    final isCashier = role == 'cashier';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Shop Settings', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Shop logo
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop logo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: isCashier || _logoUploading ? null : _pickAndUploadLogo,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outline.withAlpha(80)),
                            ),
                            child: _logoUploading
                                ? Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)))
                                : _logoUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(_logoUrl, fit: BoxFit.cover, width: 80, height: 80, errorBuilder: (_, __, ___) => Icon(Icons.store_rounded, size: 40, color: colorScheme.primary)),
                                      )
                                    : Icon(Icons.add_photo_alternate_rounded, size: 36, color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Used on receipts and reports', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              if (!isCashier)
                                TextButton.icon(
                                  onPressed: _logoUploading ? null : _pickAndUploadLogo,
                                  icon: const Icon(Icons.upload_rounded, size: 18),
                                  label: const Text('Select logo'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final themeMode = ref.watch(themeModeProvider);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.palette_outlined, color: colorScheme.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('App theme', style: TextStyle(color: colorScheme.onSurface, fontSize: 15)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _themeChip(ref, ThemeMode.light, themeMode, Icons.light_mode_rounded, 'Light', colorScheme),
                            const SizedBox(width: 8),
                            _themeChip(ref, ThemeMode.dark, themeMode, Icons.dark_mode_rounded, 'Dark', colorScheme),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
               _buildTextField('Shop Name', _nameController, Icons.storefront_rounded, colorScheme, readOnly: isCashier),
               const SizedBox(height: 20),
               _buildTextField('PO BOX', _poBoxController, Icons.mail_outline_rounded, colorScheme, readOnly: isCashier),
               const SizedBox(height: 20),
               _buildTextField('Address', _addressController, Icons.location_on_outlined, colorScheme, readOnly: isCashier),
               const SizedBox(height: 20),
               _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, colorScheme, readOnly: isCashier),
               const SizedBox(height: 20),
               Text('Printer type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
               const SizedBox(height: 8),
               IgnorePointer(
                 ignoring: isCashier,
                 child: Opacity(
                   opacity: isCashier ? 0.55 : 1,
                   child: Row(
                     children: [
                       _printerChip('standard', 'Standard (A4)', Icons.print_rounded, colorScheme),
                       const SizedBox(width: 12),
                       _printerChip('thermal', 'Thermal (80mm)', Icons.receipt_long_rounded, colorScheme),
                     ],
                   ),
                 ),
               ),
               if (!isCashier) ...[
                 const SizedBox(height: 24),
                 Text('M-Pesa (Daraja API)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                 const SizedBox(height: 6),
                 Text('Configure for STK Push. Use Callback URL from Supabase Edge Function.', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                 const SizedBox(height: 12),
                 _buildTextField('Consumer Key', _mpesaConsumerKeyController, Icons.vpn_key_rounded, colorScheme, optional: true),
                 const SizedBox(height: 12),
                 _buildTextField('Consumer Secret', _mpesaConsumerSecretController, Icons.lock_rounded, colorScheme, optional: true, obscure: true),
                 const SizedBox(height: 12),
                 _buildTextField('Shortcode', _mpesaShortcodeController, Icons.confirmation_number_outlined, colorScheme, optional: true),
                 const SizedBox(height: 12),
                 _buildTextField('Till Number (Buy Goods)', _mpesaTillNumberController, Icons.store_rounded, colorScheme, optional: true),
                 const SizedBox(height: 12),
                 _buildTextField('Passkey', _mpesaPasskeyController, Icons.key_rounded, colorScheme, optional: true, obscure: true),
                 const SizedBox(height: 12),
                 _buildTextField('Base URL', _mpesaBaseUrlController, Icons.link_rounded, colorScheme, optional: true),
                 const SizedBox(height: 12),
                 _buildTextField('Callback URL (STK result)', _mpesaCallbackUrlController, Icons.webhook_rounded, colorScheme, optional: true),
                 const SizedBox(height: 12),
                 Text('Transaction type', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                 const SizedBox(height: 6),
                 Row(
                   children: [
                     _mpesaTypeChip('CustomerBuyGoodsOnline', 'Buy Goods', colorScheme),
                     const SizedBox(width: 8),
                     _mpesaTypeChip('CustomerPayBillOnline', 'Pay Bill', colorScheme),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Icon(Icons.science_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                     const SizedBox(width: 8),
                     Text('Sandbox', style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
                     const Spacer(),
                     Switch(
                       value: _mpesaIsSandbox,
                       onChanged: (v) => setState(() => _mpesaIsSandbox = v),
                       activeTrackColor: colorScheme.primaryContainer,
                       activeThumbColor: colorScheme.primary,
                     ),
                   ],
                 ),
               ],
               const SizedBox(height: 48),
               if (!isCashier)
                 SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SAVE SETTINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mpesaTypeChip(String value, String label, ColorScheme colorScheme) {
    final selected = _mpesaTransactionType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mpesaTransactionType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline.withAlpha(80)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface)),
          ),
        ),
      ),
    );
  }

  Widget _printerChip(String value, String label, IconData icon, ColorScheme colorScheme) {
    final selected = _printerType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _printerType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeChip(WidgetRef ref, ThemeMode mode, ThemeMode current, IconData icon, String label, ColorScheme colorScheme) {
    final selected = current == mode;
    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).setTheme(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? colorScheme.onPrimary : colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? colorScheme.onPrimary : colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    ColorScheme colorScheme, {
    bool optional = false,
    bool obscure = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          validator: optional || readOnly ? null : (value) => value == null || value.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
