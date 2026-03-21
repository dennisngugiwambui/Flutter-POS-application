import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/app_theme.dart';
import '../../../core/money_format.dart';
import '../../../core/ui_components.dart';
import '../domain/product_model.dart';
import 'product_provider.dart';
import 'scan_barcode_page.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _buying = TextEditingController();
  final _selling = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();

  File? _imageFile;
  final _picker = ImagePicker();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _buying.dispose();
    _selling.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    if (src == ImageSource.camera) {
      final status = await Permission.camera.status;
      if (!status.isGranted) await Permission.camera.request();
    } else {
      final status = await Permission.photos.status;
      if (!status.isGranted) await Permission.photos.request();
    }
    final f = await _picker.pickImage(source: src, imageQuality: 80);
    if (f != null) setState(() => _imageFile = File(f.path));
  }

  Future<void> _scanBarcode() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) await Permission.camera.request();
    if (!mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanBarcodePage()),
    );
    if (result != null && mounted) {
      setState(() => _barcode.text = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Barcode scanned: $result', style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: kPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      String imageUrl = _imageUrl.text.trim();
      if (_imageFile != null) {
        try {
          imageUrl = await ref.read(productRepositoryProvider).uploadImage(_imageFile!);
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e. Add an image URL or try again.'),
                backgroundColor: kWarning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          imageUrl = '';
        }
      }

      final product = ProductModel(
        name: _name.text.trim(),
        barcode: _barcode.text.trim(),
        buyingPrice: double.parse(_buying.text),
        sellingPrice: double.parse(_selling.text),
        stockQuantity: int.parse(_stock.text),
        imageUrl: imageUrl,
      );

      await ref.read(productRepositoryProvider).addProduct(product);

      if (mounted) {
        ref.invalidate(productsProvider);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Product added successfully'),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kBg,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      TopIconBtn(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'New Product',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: kText,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: () => _showImageSheet(context),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _imageFile != null ? kPrimary.withAlpha(60) : kBorder,
                        width: 0.9,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080A2018),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: _imageFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_imageFile!, fit: BoxFit.cover),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(160),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: kPrimary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Add Product Image',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap to take a photo or choose from gallery',
                                  style: TextStyle(fontSize: 12, color: kTextSub),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        label: 'Product Name',
                        controller: _name,
                        icon: Icons.label_rounded,
                        hint: 'e.g. iPhone 13 Pro Max',
                        validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Barcode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _barcode,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: kText,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 89796959',
                                    hintStyle: const TextStyle(color: kTextMuted, fontWeight: FontWeight.w400),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14),
                                      child: Icon(Icons.qr_code_scanner_rounded, color: kPrimary, size: 18),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                    filled: true,
                                    fillColor: kSurface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: kBorder, width: 0.9),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: kBorder, width: 0.9),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _scanBarcode,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1B8B5A),
                                        Color(0xFF26B573),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kPrimary.withAlpha(60),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              label: 'Buying Price',
                              controller: _buying,
                              icon: Icons.shopping_bag_outlined,
                              hint: '0',
                              isNumber: true,
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _FormField(
                              label: 'Selling Price',
                              controller: _selling,
                              icon: Icons.sell_rounded,
                              hint: '0',
                              isNumber: true,
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _MarginPreview(
                        buyingCtrl: _buying,
                        sellingCtrl: _selling,
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Stock Quantity',
                        controller: _stock,
                        icon: Icons.inventory_2_rounded,
                        hint: '0',
                        isNumber: true,
                        isInt: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Image URL',
                        controller: _imageUrl,
                        icon: Icons.link_rounded,
                        hint: 'https://... (optional)',
                        requiredField: false,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            disabledBackgroundColor: kPrimary.withAlpha(100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Add Product',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Image',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
            ),
            const SizedBox(height: 16),
            _sheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              sub: 'Use your camera',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _sheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              sub: 'Pick an existing photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 0.9),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kPrimary.withAlpha(15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kText)),
                Text(sub, style: const TextStyle(fontSize: 12, color: kTextSub)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: kTextMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool isNumber;
  final bool isInt;
  final bool requiredField;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.isNumber = false,
    this.isInt = false,
    this.requiredField = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kText,
                letterSpacing: -0.1,
              ),
            ),
            if (!requiredField)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text(
                  '(optional)',
                  style: TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? (isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true))
              : TextInputType.text,
          validator: validator,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kTextMuted, fontWeight: FontWeight.w400),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(icon, color: kPrimary, size: 18),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            filled: true,
            fillColor: kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder, width: 0.9),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder, width: 0.9),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kError, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kError, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ],
    );
  }
}

class _MarginPreview extends StatefulWidget {
  final TextEditingController buyingCtrl;
  final TextEditingController sellingCtrl;

  const _MarginPreview({
    required this.buyingCtrl,
    required this.sellingCtrl,
  });

  @override
  State<_MarginPreview> createState() => _MarginPreviewState();
}

class _MarginPreviewState extends State<_MarginPreview> {
  @override
  void initState() {
    super.initState();
    widget.buyingCtrl.addListener(_update);
    widget.sellingCtrl.addListener(_update);
  }

  @override
  void dispose() {
    widget.buyingCtrl.removeListener(_update);
    widget.sellingCtrl.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final buying = double.tryParse(widget.buyingCtrl.text) ?? 0;
    final selling = double.tryParse(widget.sellingCtrl.text) ?? 0;
    final profit = selling - buying;
    final margin = buying > 0 ? (profit / buying * 100) : 0.0;
    final isGood = margin >= 10;
    final color = margin < 0 ? kError : (isGood ? kPrimary : kWarning);

    if (buying == 0 && selling == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40), width: 0.9),
      ),
      child: Row(
        children: [
          Icon(
            margin < 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              margin < 0
                  ? 'Selling below cost — loss of ${formatKes(profit.abs())}'
                  : 'Profit: ${formatKes(profit)}  ·  Margin: ${margin.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
