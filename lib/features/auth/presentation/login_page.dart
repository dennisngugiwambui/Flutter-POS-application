import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'register_page.dart';
import '../../dashboard/presentation/shell_router.dart';
import '../../../dashboard_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _loading    = false;
  bool _obscure    = true;
  bool _emailFocus = false;
  bool _passFocus  = false;

  late AnimationController _entranceCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoAnim;
  late Animation<double> _card1Anim;
  late Animation<double> _card2Anim;
  late Animation<double> _shakeAnim;

  static const _g1 = Color(0xFF1B8B5A);
  static const _g2 = Color(0xFF26B573);
  static const _g3 = Color(0xFF0F5C38);
  static const _bg = Color(0xFF071A10);

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _shakeCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _logoAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );
    _card1Anim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    );
    _card2Anim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
        emailOrPhone: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      ref.invalidate(profileProvider);

      try {
        final profile = await ref.read(profileProvider.future);
        if (profile != null && profile.isActive == false) {
          await ref.read(authRepositoryProvider).signOut();
          if (!mounted) return;
          _showError('Account pending admin approval. Contact your administrator.');
          return;
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, b) => const ShellRouter(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      _shakeCtrl.forward(from: 0);
      String msg = e.toString();
      if (msg.contains('Invalid login credentials')) msg = 'Incorrect email or password.';
      else if (msg.contains('Email not confirmed')) msg = 'Please confirm your email first.';
      if (mounted) _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFFD93D3D),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Background particles ─────────────────────────────────────────
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _BgParticlePainter(_particleCtrl.value),
              ),
            ),

            // ── Gradient orbs ────────────────────────────────────────────────
            Positioned(
              top: -80, right: -80,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + _pulseCtrl.value * 0.1,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_g1.withAlpha(80), Colors.transparent]),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60, left: -60,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_g2.withAlpha(45), Colors.transparent]),
                ),
              ),
            ),

            // ── Main scroll ──────────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height
                        - MediaQuery.of(context).padding.top
                        - MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // ── Logo ───────────────────────────────────────────
                        ScaleTransition(
                          scale: _logoAnim,
                          child: Column(children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [_g2, _g1, _g3],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(color: _g1.withAlpha(120), blurRadius: 40, spreadRadius: 2),
                                  BoxShadow(color: _g2.withAlpha(60), blurRadius: 15, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Stack(alignment: Alignment.center, children: [
                                Positioned(top: 8, left: 8,
                                  child: Container(width: 40, height: 40,
                                    decoration: BoxDecoration(shape: BoxShape.circle,
                                      color: Colors.white.withAlpha(20)))),
                                const Icon(Icons.point_of_sale_rounded, size: 50, color: Colors.white),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xFF4DFFA0), Color(0xFF26B573), Colors.white],
                              ).createShader(b),
                              child: const Text('PixelPOS', style: TextStyle(
                                fontSize: 38, fontWeight: FontWeight.w900,
                                color: Colors.white, letterSpacing: -1,
                              )),
                            ),
                            const SizedBox(height: 4),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 20, height: 0.8, color: _g1.withAlpha(120)),
                              const SizedBox(width: 8),
                              Text('POINT OF SALE', style: TextStyle(
                                fontSize: 10, letterSpacing: 4,
                                color: Colors.white.withAlpha(100), fontWeight: FontWeight.w600,
                              )),
                              const SizedBox(width: 8),
                              Container(width: 20, height: 0.8, color: _g1.withAlpha(120)),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 36),

                        // ── Form card ─────────────────────────────────────
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(sin(_shakeAnim.value * pi * 6) * 8 * (1 - _shakeAnim.value), 0),
                            child: child,
                          ),
                          child: FadeTransition(
                            opacity: _card1Anim,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                                  .animate(_card1Anim),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(8),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: Colors.white.withAlpha(18), width: 0.9),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(60),
                                      blurRadius: 40, offset: const Offset(0, 16)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          const Text('Welcome back', style: TextStyle(
                                            fontSize: 22, fontWeight: FontWeight.w900,
                                            color: Colors.white, letterSpacing: -0.5,
                                          )),
                                          const SizedBox(height: 4),
                                          Text('Sign in to your POS account', style: TextStyle(
                                            fontSize: 13, color: Colors.white.withAlpha(140),
                                            fontWeight: FontWeight.w500,
                                          )),
                                          const SizedBox(height: 24),

                                          // Email field
                                          _GlassField(
                                            controller: _emailCtrl,
                                            label: 'Email or Username',
                                            icon: Icons.person_outline_rounded,
                                            hint: 'you@example.com',
                                            keyboardType: TextInputType.emailAddress,
                                            onFocusChange: (f) => setState(() => _emailFocus = f),
                                            focused: _emailFocus,
                                            validator: (v) =>
                                              (v == null || v.isEmpty) ? 'Email is required' : null,
                                          ),
                                          const SizedBox(height: 16),

                                          // Password field
                                          _GlassField(
                                            controller: _passwordCtrl,
                                            label: 'Password',
                                            icon: Icons.lock_outline_rounded,
                                            hint: '••••••••',
                                            obscure: _obscure,
                                            onFocusChange: (f) => setState(() => _passFocus = f),
                                            focused: _passFocus,
                                            validator: (v) =>
                                              (v == null || v.isEmpty) ? 'Password is required' : null,
                                            suffix: GestureDetector(
                                              onTap: () => setState(() => _obscure = !_obscure),
                                              child: Icon(
                                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                color: Colors.white.withAlpha(120),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Forgot password
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: GestureDetector(
                                              onTap: () {},
                                              child: Text('Forgot password?', style: TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w600,
                                                color: const Color(0xFF4DFFA0),
                                              )),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Login button
                                          _GreenButton(
                                            label: 'Sign In',
                                            icon: Icons.login_rounded,
                                            loading: _loading,
                                            onTap: _loading ? null : _login,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Register link ──────────────────────────────────
                        FadeTransition(
                          opacity: _card2Anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                                .animate(_card2Anim),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text("Don't have an account? ", style: TextStyle(
                                color: Colors.white.withAlpha(120), fontSize: 14,
                              )),
                              GestureDetector(
                                onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RegisterPage())),
                                child: ShaderMask(
                                  shaderCallback: (b) => const LinearGradient(
                                    colors: [Color(0xFF4DFFA0), Color(0xFF26B573)],
                                  ).createShader(b),
                                  child: const Text('Register', style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  )),
                                ),
                              ),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Role info card ─────────────────────────────────
                        FadeTransition(
                          opacity: _card2Anim,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withAlpha(12)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _g1.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFF4DFFA0), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(
                                'One login for all roles — Admin, Manager, Cashier & Client. You\'ll be taken to your role\'s screen after sign in.',
                                style: TextStyle(
                                  fontSize: 11.5, color: Colors.white.withAlpha(130),
                                  height: 1.45, fontWeight: FontWeight.w500,
                                ),
                              )),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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

// ── Glass text field ───────────────────────────────────────────────────────────
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure, focused;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<bool> onFocusChange;
  final Widget? suffix;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onFocusChange,
    required this.focused,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  static const _g1 = Color(0xFF1B8B5A);
  static const _g2 = Color(0xFF26B573);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: focused ? const Color(0xFF4DFFA0) : Colors.white.withAlpha(160),
        letterSpacing: 0.2,
      )),
      const SizedBox(height: 7),
      Focus(
        onFocusChange: onFocusChange,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: focused ? Colors.white.withAlpha(14) : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? _g2.withAlpha(180) : Colors.white.withAlpha(20),
              width: focused ? 1.5 : 0.9,
            ),
            boxShadow: focused ? [BoxShadow(color: _g1.withAlpha(40), blurRadius: 12)] : null,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withAlpha(70), fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(icon,
                  color: focused ? const Color(0xFF4DFFA0) : Colors.white.withAlpha(120),
                  size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 52),
              suffixIcon: suffix != null ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffix,
              ) : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(color: Color(0xFFFF7070), fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              isDense: true,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Green gradient button ──────────────────────────────────────────────────────
class _GreenButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const _GreenButton({
    required this.label, required this.icon,
    required this.loading, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xFF26B573), Color(0xFF1B8B5A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: onTap == null ? Colors.white.withAlpha(20) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null ? [
            BoxShadow(color: const Color(0xFF1B8B5A).withAlpha(100), blurRadius: 18, offset: const Offset(0, 6)),
          ] : null,
        ),
        child: loading
            ? const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                )),
              ]),
      ),
    );
  }
}

// ── Background subtle particles ────────────────────────────────────────────────
class _BgParticlePainter extends CustomPainter {
  final double t;
  _BgParticlePainter(this.t);

  static final _r = Random(77);
  static final _pts = List.generate(14, (i) => [
    _r.nextDouble(), _r.nextDouble(),
    _r.nextDouble() * 0.3 + 0.05,
    _r.nextDouble() * 2 + 1,
    _r.nextDouble(),
  ]);

  @override
  void paint(Canvas canvas, Size s) {
    for (final p in _pts) {
      final phase = (t * p[2] + p[4]) % 1.0;
      final y = s.height - phase * s.height * 1.3;
      if (y < -10 || y > s.height + 10) continue;
      final opacity = sin(phase * pi) * 0.25;
      final paint = Paint()
        ..color = const Color(0xFF26B573).withOpacity(opacity.clamp(0, 0.3))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p[0] * s.width, y), p[3], paint);
    }
  }

  @override
  bool shouldRepaint(_BgParticlePainter old) => old.t != t;
}
