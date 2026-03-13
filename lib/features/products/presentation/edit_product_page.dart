import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _buyingPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _barcodeController = TextEditingController(text: p.barcode);
    _buyingPriceController = TextEditingController(text: p.buyingPrice.toString());
    _sellingPriceController = TextEditingController(text: p.sellingPrice.toString());
    _stockController = TextEditingController(text: p.stockQuantity.toString());
    _imageUrlController = TextEditingController(text: p.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String imageUrl = _imageUrlController.text.trim();
      
      if (_imageFile != null) {
        try {
          imageUrl = await ref.read(productRepositoryProvider).uploadImage(_imageFile!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e. Save without new image or add an image URL below.'),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          imageUrl = widget.product.imageUrl; // keep existing image on upload failure
        }
      }

      final updated = ProductModel(
        id: widget.product.id,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        buyingPrice: double.parse(_buyingPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stockQuantity: int.parse(_stockController.text),
        imageUrl: imageUrl,
        createdBy: widget.product.createdBy,
      );

      await ref.read(productRepositoryProvider).updateProduct(updated);
      
      if (mounted) {
        ref.invalidate(productsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product updated!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Edit Product', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding = isWide ? constraints.maxWidth * 0.15 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(80),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorScheme.outline.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                                    )
                                  : widget.product.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.network(
                                            widget.product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _imagePlaceholder(colorScheme),
                                          ),
                                        )
                                      : _imagePlaceholder(colorScheme),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Product image', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('Tap to replace from camera or gallery', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.photo_camera_rounded, size: 18),
                                      label: const Text('Camera'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                                      label: const Text('Gallery'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildField(context, 'Product Name', _nameController, Icons.label_outline),
                    const SizedBox(height: 16),
                    _buildField(context, 'Barcode', _barcodeController, Icons.qr_code_scanner_rounded),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            context,
                            'Buying Price',
                            _buyingPriceController,
                            Icons.attach_money_rounded,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            context,
                            'Selling Price',
                            _sellingPriceController,
                            Icons.sell_rounded,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(context, 'Stock Quantity', _stockController, Icons.inventory_2_rounded, isNumber: true),
                    const SizedBox(height: 16),
                    _buildField(context, 'Image URL (Optional)', _imageUrlController, Icons.link_rounded, required: false),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('SAVE CHANGES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text('Change Photo', style: TextStyle(color: colorScheme.primary.withAlpha(200), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildField(BuildContext context, String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool required = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
          validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 18),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withAlpha(30),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outline.withAlpha(80))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // Previous bottom-sheet image picker is no longer used; image buttons call _pickImage directly.
}
