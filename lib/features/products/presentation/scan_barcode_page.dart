import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );

  bool _hasResult = false;
  late AnimationController _scanAnim;
  late Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        unawaited(_controller.stop());
        break;
      case AppLifecycleState.resumed:
        if (mounted && !_hasResult) unawaited(_controller.start());
        break;
      default:
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasResult) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;
    _hasResult = true;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Scan Barcode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final torch = _controller.value.torchState;
              if (torch == TorchState.unavailable) return const SizedBox.shrink();
              final on = torch == TorchState.on || torch == TorchState.auto;
              return GestureDetector(
                onTap: () => unawaited(_controller.toggleTorch()),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: on
                        ? const Color(0xFFFFB347).withAlpha(80)
                        : Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: on
                          ? const Color(0xFFFFB347).withAlpha(150)
                          : Colors.white.withAlpha(40),
                    ),
                  ),
                  child: Icon(
                    on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: on ? const Color(0xFFFFB347) : Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Dark overlay with cutout
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _ScanOverlayPainter(
              scanBoxSize: scanBoxSize,
              cutoutTop: (size.height - scanBoxSize) / 2 - 30,
            ),
          ),

          // Scan box with animated corners + scan line
          Center(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: SizedBox(
                width: scanBoxSize,
                height: scanBoxSize,
                child: Stack(
                  children: [
                    // Corner decorations
                    ..._buildCorners(scanBoxSize),

                    // Animated scan line
                    AnimatedBuilder(
                      animation: _scanLine,
                      builder: (_, __) => Positioned(
                        top: _scanLine.value * (scanBoxSize - 2),
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF6C63FF),
                                const Color(0xFF00D4AA),
                                const Color(0xFF6C63FF),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withAlpha(150),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom instruction panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                28,
                24,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(220),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4AA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Position barcode within the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Supports EAN-13 · EAN-8 · UPC · Code128 · QR',
                    style: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(double size) {
    const cornerSize = 24.0;
    const thickness = 3.0;
    const color = Color(0xFF6C63FF);
    final br = BorderRadius.circular(4);

    Widget corner({
      required AlignmentGeometry alignment,
      required bool flipX,
      required bool flipY,
    }) {
      return Align(
        alignment: alignment,
        child: Transform.scale(
          scaleX: flipX ? -1 : 1,
          scaleY: flipY ? -1 : 1,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: cornerSize,
                    height: thickness,
                    decoration: BoxDecoration(color: color, borderRadius: br),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: thickness,
                    height: cornerSize,
                    decoration: BoxDecoration(color: color, borderRadius: br),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return [
      corner(alignment: Alignment.topLeft, flipX: false, flipY: false),
      corner(alignment: Alignment.topRight, flipX: true, flipY: false),
      corner(alignment: Alignment.bottomLeft, flipX: false, flipY: true),
      corner(alignment: Alignment.bottomRight, flipX: true, flipY: true),
    ];
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final double cutoutTop;

  _ScanOverlayPainter({required this.scanBoxSize, required this.cutoutTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(160);
    final cutoutLeft = (size.width - scanBoxSize) / 2;
    final rect = Rect.fromLTWH(cutoutLeft, cutoutTop, scanBoxSize, scanBoxSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
