import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../../core/money_format.dart';
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
                    height: 56,
                    width: 200,
                    margin: const pw.EdgeInsets.only(bottom: 8),
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
              ...items.asMap().entries.map((entry) {
                final n = entry.key + 1;
                final dynamic item = entry.value;
                final name = item.product.name as String;
                final int qty = item.quantity as int;
                final double price = (item.product.sellingPrice as num).toDouble();
                final double lineTotal = (item.totalPrice as num).toDouble();
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(width: 22, child: pw.Text('$n.', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('$qty × ${formatKes(price)}', style: pw.TextStyle(fontSize: 9)),
                                pw.Text(formatKes(lineTotal), style: pw.TextStyle(fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
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
                  pw.Text(formatKes(totalAmount), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
      backgroundColor: const Color(0xFF0D0F14),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (shopSettings.logoUrl.isNotEmpty)
                            Image.network(
                              shopSettings.logoUrl,
                              height: 88,
                              width: 200,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (c, e, s) => const SizedBox(),
                            )
                          else
                            const Icon(Icons.storefront_rounded, size: 48, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            shopSettings.shopName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (shopSettings.address.isNotEmpty)
                            Text(
                              shopSettings.address,
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                            ),
                          if (shopSettings.poBox.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'PO BOX: ${shopSettings.poBox}',
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${dateFormat.format(now)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        const Text('INV #8273', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    // Items List (numbered)
                    ...items.asMap().entries.map((entry) {
                      final n = entry.key + 1;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$n.',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54, fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text('${item.quantity} × ${formatKes(item.product.sellingPrice)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(formatKes(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 32, thickness: 1, color: Colors.black12),
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text(
                          formatKes(totalAmount),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
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
