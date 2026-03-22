import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../../dashboard/presentation/shell_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _barCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotate;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _pulse;
  late Animation<double> _barWidth;

  static const _green1 = Color(0xFF1B8B5A);
  static const _green2 = Color(0xFF26B573);

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );
    _pulse = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _barWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl.forward().then((_) {
      _textCtrl.forward();
      _barCtrl.forward();
    });

    Timer(const Duration(milliseconds: 3400), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => session != null ? const ShellRouter() : const LoginPage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071A10), Color(0xFF0A2218), Color(0xFF0D1F15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Animated particles ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  progress: _particleCtrl.value,
                  color1: _green1,
                  color2: _green2,
                ),
              ),
            ),

            // ── Radial glow behind logo ────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Center(
                child: Transform.translate(
                  offset: const Offset(0, -60),
                  child: Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _green1.withAlpha(55),
                            _green2.withAlpha(20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Ring decoration ────────────────────────────────────────────────
            Center(
              child: Transform.translate(
                offset: const Offset(0, -60),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + ((_pulse.value - 0.95) * 0.3),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green1.withAlpha(40), width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: const Offset(0, -60),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + ((_pulse.value - 0.95) * 0.5),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green1.withAlpha(18), width: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotate.value,
                          child: child,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF26B573), Color(0xFF1B8B5A), Color(0xFF0F5C38)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _green1.withAlpha(130),
                            blurRadius: 50,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: _green2.withAlpha(60),
                            blurRadius: 20,
                            spreadRadius: -5,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Shine overlay
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(18),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.point_of_sale_rounded,
                            size: 58,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // App name
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF4DFFA0), Color(0xFF26B573), Colors.white],
                          stops: [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: const Text(
                          'PixelPOS',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: SlideTransition(
                      position: _subtitleSlide,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 30, height: 0.8, color: _green1.withAlpha(120)),
                              const SizedBox(width: 12),
                              const Text(
                                'POINT OF SALE SYSTEM',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 4,
                                  color: Color(0xFF4DFFA0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 30, height: 0.8, color: _green1.withAlpha(120)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Empowering Kenyan Businesses',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withAlpha(110),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Loading bar
                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Column(
                      children: [
                        Container(
                          width: 160,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AnimatedBuilder(
                            animation: _barWidth,
                            builder: (_, __) => FractionallySizedBox(
                              widthFactor: _barWidth.value,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4DFFA0), Color(0xFF26B573)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _green2.withAlpha(100),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Opacity(
                            opacity: _pulse.value,
                            child: Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withAlpha(70),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom version badge ───────────────────────────────────────────
            Positioned(
              bottom: 32, left: 0, right: 0,
              child: FadeTransition(
                opacity: _subtitleOpacity,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Text(
                      'v1.0.0  ·  Powered by Pixel Solutions',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(60),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating particle painter ──────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  _ParticlePainter({required this.progress, required this.color1, required this.color2});

  static final _rand = Random(42);
  static final _particles = List.generate(22, (i) => [
    _rand.nextDouble(),  // x ratio
    _rand.nextDouble(),  // y start ratio
    _rand.nextDouble() * 0.6 + 0.2,  // speed factor
    _rand.nextDouble() * 3 + 1.5,    // radius
    _rand.nextDouble(),  // opacity factor
    _rand.nextDouble(),  // phase
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = p[0] * size.width;
      final phase = (progress * p[2] + p[5]) % 1.0;
      final y = size.height - (phase * size.height * 1.2);
      if (y < -20 || y > size.height + 20) continue;
      final opacity = (sin(phase * pi) * p[4] * 0.5).clamp(0.0, 0.5);
      final paint = Paint()
        ..color = (p[4] > 0.5 ? color2 : color1).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p[3], paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
