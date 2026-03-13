import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'cart_provider.dart';
import '../../settings/domain/shop_settings_model.dart';
import '../../settings/presentation/settings_provider.dart';

class ReceiptPage extends ConsumerWidget {
  final ShopSettingsModel? initialShopSettings;
  final List<dynamic> items;
  final double totalAmount;

  const ReceiptPage({
    super.key,
    this.initialShopSettings,
    required this.items,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return settingsAsync.when(
      data: (settings) => _buildReceiptView(context, ref, settings, dateFormat, now),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => _buildReceiptView(context, ref, initialShopSettings ?? ShopSettingsModel(shopName: 'POS'), dateFormat, now),
    );
  }

  Future<void> _exportReceiptPdf(BuildContext context, ShopSettingsModel shopSettings, DateFormat dateFormat, DateTime now) async {
    Uint8List? logoBytes;
    if (shopSettings.logoUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(shopSettings.logoUrl));
        if (res.statusCode == 200) {
          logoBytes = res.bodyBytes;
        }
      } catch (_) {}
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Center(
                  child: pw.Container(
                    height: 40,
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                  ),
                ),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      shopSettings.shopName,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    if (shopSettings.address.isNotEmpty)
                      pw.Text(shopSettings.address, style: const pw.TextStyle(fontSize: 9)),
                    if (shopSettings.poBox.isNotEmpty)
                      pw.Text('PO BOX: ${shopSettings.poBox}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Date: ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Divider(),
              ...items.map((dynamic item) {
                final name = item.product.name as String;
                final int qty = item.quantity as int;
                final double price = (item.product.sellingPrice as num).toDouble();
                final double lineTotal = (item.totalPrice as num).toDouble();
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$qty x \$${price.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9)),
                          pw.Text('\$${lineTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with us!',
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Receipt_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }

  Widget _buildReceiptView(BuildContext context, WidgetRef ref, ShopSettingsModel shopSettings, DateFormat dateFormat, DateTime now) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _exportReceiptPdf(context, shopSettings, dateFormat, now),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _exportReceiptPdf(context, shopSettings, dateFormat, now),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    // Shop Header
                    if (shopSettings.logoUrl.isNotEmpty) 
                      Image.network(shopSettings.logoUrl, height: 60, errorBuilder: (c, e, s) => const SizedBox())
                    else
                      const Icon(Icons.storefront_rounded, size: 60, color: Color(0xFF6366F1)),
                    
                    const SizedBox(height: 12),
                    Text(
                      shopSettings.shopName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(shopSettings.address, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    Text('PO BOX: ${shopSettings.poBox}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${dateFormat.format(now)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        const Text('INV #8273', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    // Items List
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                Text('${item.quantity} x \$${item.product.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('\$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    )),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                     const Text('Thank you for shopping with us!', style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic)),
                     const SizedBox(height: 16),
                     // Mock Barcode for receipt
                     Container(
                       height: 40,
                       width: 200,
                       decoration: const BoxDecoration(
                         gradient: LinearGradient(
                           colors: [Colors.black, Colors.white, Colors.black, Colors.white, Colors.black],
                         ),
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).clearCart();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('BACK TO POS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
