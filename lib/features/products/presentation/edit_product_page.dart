import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_theme.dart';
import '../../../core/money_format.dart';
import '../../../core/ui_components.dart';
import '../domain/product_model.dart';
import 'product_provider.dart';

class EditProductPage extends ConsumerStatefulWidget {
  final ProductModel product;
  const EditProductPage({super.key, required this.product});

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _barcode;
  late TextEditingController _buying;
  late TextEditingController _selling;
  late TextEditingController _stock;
  late TextEditingController _imageUrl;

  File? _imageFile;
  final _picker = ImagePicker();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p.name);
    _barcode = TextEditingController(text: p.barcode);
    _buying = TextEditingController(text: p.buyingPrice.toString());
    _selling = TextEditingController(text: p.sellingPrice.toString());
    _stock = TextEditingController(text: p.stockQuantity.toString());
    _imageUrl = TextEditingController(text: p.imageUrl);
  }

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
    final f = await _picker.pickImage(source: src, imageQuality: 80);
    if (f != null) setState(() => _imageFile = File(f.path));
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
                content: Text('Image upload failed: $e'),
                backgroundColor: kWarning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          imageUrl = widget.product.imageUrl;
        }
      }

      final updated = ProductModel(
        id: widget.product.id,
        name: _name.text.trim(),
        barcode: _barcode.text.trim(),
        buyingPrice: double.parse(_buying.text),
        sellingPrice: double.parse(_selling.text),
        stockQuantity: int.parse(_stock.text),
        imageUrl: imageUrl,
        createdBy: widget.product.createdBy,
        createdAt: widget.product.createdAt,
      );

      await ref.read(productRepositoryProvider).updateProduct(updated);

      if (mounted) {
        ref.invalidate(productsProvider);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Product updated successfully'),
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
                          'Edit Product',
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showImageSheet(context),
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  color: kSurface2,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kBorder, width: 0.9),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: _imageFile != null
                                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                                      : widget.product.imageUrl.isNotEmpty
                                          ? Image.network(
                                              widget.product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => _noImageIcon(),
                                            )
                                          : _noImageIcon(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Product Image',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: kText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Tap image or buttons to change',
                                    style: TextStyle(fontSize: 12, color: kTextSub),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _imageBtn(
                                        icon: Icons.camera_alt_rounded,
                                        label: 'Camera',
                                        onTap: () => _pickImage(ImageSource.camera),
                                      ),
                                      const SizedBox(width: 8),
                                      _imageBtn(
                                        icon: Icons.photo_library_rounded,
                                        label: 'Gallery',
                                        onTap: () => _pickImage(ImageSource.gallery),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FormField(
                        label: 'Product Name',
                        controller: _name,
                        icon: Icons.label_rounded,
                        hint: 'e.g. iPhone 13 Pro Max',
                        validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 18),
                      _FormField(
                        label: 'Barcode',
                        controller: _barcode,
                        icon: Icons.qr_code_scanner_rounded,
                        hint: 'e.g. 89796959',
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
                      const SizedBox(height: 18),
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
                        label: 'Image URL (Optional)',
                        controller: _imageUrl,
                        icon: Icons.link_rounded,
                        hint: 'https://...',
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
                            shadowColor: kPrimary.withAlpha(60),
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
                                  'Save Changes',
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

  Widget _noImageIcon() {
    return const Center(
      child: Icon(Icons.add_a_photo_outlined, size: 28, color: kTextMuted),
    );
  }

  Widget _imageBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: kPrimary.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPrimary.withAlpha(40), width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kPrimary, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kPrimary,
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
              'Change Image',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kText),
            ),
            const SizedBox(height: 16),
            _sheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              sub: 'Use camera',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _sheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              sub: 'Select from photos',
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
