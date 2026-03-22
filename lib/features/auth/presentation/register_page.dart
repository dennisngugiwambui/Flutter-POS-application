import 'dart:math' show Random, pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard_provider.dart';
import 'auth_provider.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureC = true;

  bool _nameFocus = false;
  bool _emailFocus = false;
  bool _phoneFocus = false;
  bool _passFocus = false;
  bool _confirmFocus = false;

  late AnimationController _entranceCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;

  late Animation<double> _logoAnim;
  late Animation<double> _cardAnim;
  late Animation<double> _bottomAnim;
  late Animation<double> _shakeAnim;

  static const _g1 = Color(0xFF1B8B5A);
  static const _g2 = Color(0xFF26B573);
  static const _g3 = Color(0xFF0F5C38);
  static const _bg = Color(0xFF071A10);

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _logoAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _cardAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
    );
    _bottomAnim = CurvedAnimation(
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _showToast(String msg, {bool error = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(message: msg, isError: error),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      _showToast('Please fix the highlighted fields', error: true);
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _shakeCtrl.forward(from: 0);
      _showToast('Passwords do not match', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final avail = await repo.registrationAvailability(
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (avail.emailTaken) {
        _shakeCtrl.forward(from: 0);
        _showToast('This email is already registered.', error: true);
        return;
      }
      if (avail.phoneTaken) {
        _shakeCtrl.forward(from: 0);
        _showToast('This phone number is already registered.', error: true);
        return;
      }

      final hasAdmin = await repo.hasAdminUser();
      if (hasAdmin) {
        await repo.signUpClient(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
      } else {
        await repo.signUpShopOwner(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
      }
      ref.invalidate(profileProvider);
      if (!mounted) return;
      _successCtrl.forward();
      _showToast('Account created! You can sign in (check email if confirmation is required).', error: false);

      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      _shakeCtrl.forward(from: 0);
      var msg = e.toString();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        msg = 'This email is already registered.';
      } else if (msg.contains('weak password') || msg.contains('Password')) {
        msg = 'Password is too weak. Use at least 6 characters.';
      } else if (msg.contains('invalid email')) {
        msg = 'Please enter a valid email address.';
      } else if (msg.contains('PGRST') || msg.contains('check_registration')) {
        msg = 'Server setup: apply Supabase migration check_registration_available.sql, then try again.';
      }
      _showToast(msg, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bg : const Color(0xFFF0FAF5);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _RegParticlePainter(_particleCtrl.value, isDark),
              ),
            ),
            Positioned(
              top: -100,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + _pulseCtrl.value * 0.08,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _g1.withAlpha(isDark ? 70 : 40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_g2.withAlpha(isDark ? 40 : 25), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottom + 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _logoAnim,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withAlpha(12) : _g1.withAlpha(15),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withAlpha(20) : _g1.withAlpha(35),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: isDark ? Colors.white : _g1,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ScaleTransition(
                          scale: _logoAnim,
                          child: Column(
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.7, end: 1.0),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.elasticOut,
                                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                                child: AnimatedBuilder(
                                  animation: _successCtrl,
                                  builder: (_, child) => Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      gradient: LinearGradient(
                                        colors: _successCtrl.value > 0.5
                                            ? [const Color(0xFF00D084), _g1, _g3]
                                            : [_g2, _g1, _g3],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _g1.withAlpha(isDark ? 110 : 70),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 400),
                                      child: _successCtrl.value > 0.5
                                          ? const Icon(Icons.check_rounded, size: 44, color: Colors.white, key: ValueKey('check'))
                                          : const Icon(Icons.person_add_rounded, size: 44, color: Colors.white, key: ValueKey('person')),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ShaderMask(
                                shaderCallback: (b) => LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF4DFFA0), _g2, Colors.white]
                                      : [_g3, _g1, _g2],
                                ).createShader(b),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Join Pixel POS today',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white.withAlpha(130) : _g1.withAlpha(180),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(
                              sin(_shakeAnim.value * pi * 6) * 8 * (1 - _shakeAnim.value),
                              0,
                            ),
                            child: child,
                          ),
                          child: FadeTransition(
                            opacity: _cardAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.25),
                                end: Offset.zero,
                              ).animate(_cardAnim),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(240),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withAlpha(18) : _g1.withAlpha(30),
                                    width: 0.9,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black.withAlpha(60) : _g1.withAlpha(20),
                                      blurRadius: 40,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(22),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _RegField(
                                        controller: _nameCtrl,
                                        label: 'Full Name',
                                        icon: Icons.person_outline_rounded,
                                        hint: 'John Doe',
                                        isDark: isDark,
                                        focused: _nameFocus,
                                        onFocus: (f) => setState(() => _nameFocus = f),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                                      ),
                                      const SizedBox(height: 14),
                                      _RegField(
                                        controller: _emailCtrl,
                                        label: 'Email Address',
                                        icon: Icons.email_outlined,
                                        hint: 'you@example.com',
                                        isDark: isDark,
                                        focused: _emailFocus,
                                        keyboardType: TextInputType.emailAddress,
                                        onFocus: (f) => setState(() => _emailFocus = f),
                                        validator: (v) {
                                          final t = (v ?? '').trim();
                                          if (t.isEmpty) return 'Email is required';
                                          if (!t.contains('@') || !t.contains('.')) return 'Enter a valid email';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _RegField(
                                        controller: _phoneCtrl,
                                        label: 'Phone Number',
                                        icon: Icons.phone_outlined,
                                        hint: '07XX XXX XXX',
                                        isDark: isDark,
                                        focused: _phoneFocus,
                                        keyboardType: TextInputType.phone,
                                        onFocus: (f) => setState(() => _phoneFocus = f),
                                        validator: (v) {
                                          final t = (v ?? '').trim();
                                          if (t.isEmpty) return 'Phone is required';
                                          if (t.length < 9) return 'Enter at least 9 digits';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _RegField(
                                        controller: _passCtrl,
                                        label: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        hint: '••••••••',
                                        isDark: isDark,
                                        focused: _passFocus,
                                        obscure: _obscure,
                                        onFocus: (f) => setState(() => _passFocus = f),
                                        validator: (v) => (v ?? '').length < 6 ? 'Min 6 characters' : null,
                                        suffix: GestureDetector(
                                          onTap: () => setState(() => _obscure = !_obscure),
                                          child: Icon(
                                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 20,
                                            color: isDark ? Colors.white.withAlpha(100) : _g1.withAlpha(150),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _RegField(
                                        controller: _confirmCtrl,
                                        label: 'Confirm Password',
                                        icon: Icons.lock_outline_rounded,
                                        hint: '••••••••',
                                        isDark: isDark,
                                        focused: _confirmFocus,
                                        obscure: _obscureC,
                                        onFocus: (f) => setState(() => _confirmFocus = f),
                                        validator: (v) {
                                          if ((v ?? '').isEmpty) return 'Please confirm';
                                          if (v != _passCtrl.text) return 'Passwords do not match';
                                          return null;
                                        },
                                        suffix: GestureDetector(
                                          onTap: () => setState(() => _obscureC = !_obscureC),
                                          child: Icon(
                                            _obscureC ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 20,
                                            color: isDark ? Colors.white.withAlpha(100) : _g1.withAlpha(150),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      _RegButton(
                                        label: 'Create Account',
                                        icon: Icons.person_add_rounded,
                                        loading: _loading,
                                        isDark: isDark,
                                        onTap: _loading ? null : _register,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _bottomAnim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(_bottomAnim),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already a member? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white.withAlpha(120) : _g3.withAlpha(180),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, a, b) => const LoginPage(),
                                      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                                      transitionDuration: const Duration(milliseconds: 400),
                                    ),
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (b) => const LinearGradient(
                                      colors: [Color(0xFF4DFFA0), Color(0xFF26B573)],
                                    ).createShader(b),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _bottomAnim,
                          child: Text(
                            'By creating an account, you agree to our Terms of Service',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white.withAlpha(60) : _g1.withAlpha(100),
                            ),
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

class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark, focused, obscure;
  final ValueChanged<bool> onFocus;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffix;

  static const _g1 = Color(0xFF1B8B5A);
  static const _g2 = Color(0xFF26B573);

  const _RegField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.focused,
    required this.onFocus,
    this.obscure = false,
    this.validator,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = focused
        ? (isDark ? const Color(0xFF4DFFA0) : _g1)
        : (isDark ? Colors.white.withAlpha(160) : _g1.withAlpha(180));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor, letterSpacing: 0.2),
        ),
        const SizedBox(height: 7),
        Focus(
          onFocusChange: onFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark
                  ? (focused ? Colors.white.withAlpha(14) : Colors.white.withAlpha(8))
                  : (focused ? _g1.withAlpha(8) : Colors.white.withAlpha(200)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused
                    ? _g2.withAlpha(isDark ? 200 : 180)
                    : (isDark ? Colors.white.withAlpha(20) : _g1.withAlpha(30)),
                width: focused ? 1.5 : 0.9,
              ),
              boxShadow: focused ? [BoxShadow(color: _g1.withAlpha(isDark ? 40 : 20), blurRadius: 10)] : null,
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0C1A12),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white.withAlpha(60) : _g1.withAlpha(80),
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    icon,
                    color: focused
                        ? (isDark ? const Color(0xFF4DFFA0) : _g1)
                        : (isDark ? Colors.white.withAlpha(110) : _g1.withAlpha(140)),
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 50),
                suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
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
      ],
    );
  }
}

class _RegButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading, isDark;
  final VoidCallback? onTap;

  static const _g1 = Color(0xFF1B8B5A);

  const _RegButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xFF26B573), Color(0xFF1B8B5A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: onTap == null ? (isDark ? Colors.white.withAlpha(20) : _g1.withAlpha(60)) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: _g1.withAlpha(isDark ? 110 : 70),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  const _ToastWidget({required this.message, required this.isError});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError ? const Color(0xFFD93D3D) : const Color(0xFF1B8B5A);
    final icon = widget.isError ? Icons.error_outline_rounded : Icons.check_circle_rounded;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegParticlePainter extends CustomPainter {
  final double t;
  final bool isDark;
  _RegParticlePainter(this.t, this.isDark);

  static final _rand = Random(99);
  static final _pts = List.generate(
    18,
    (i) => [
      _rand.nextDouble(),
      _rand.nextDouble() * 0.4 + 0.05,
      _rand.nextDouble() * 2.5 + 1,
      _rand.nextDouble(),
      _rand.nextDouble(),
    ],
  );

  @override
  void paint(Canvas canvas, Size s) {
    const c = Color(0xFF26B573);
    for (final p in _pts) {
      final phase = (t * p[1] + p[3]) % 1.0;
      final y = s.height - phase * s.height * 1.3;
      if (y < -10 || y > s.height + 10) continue;
      final opacity = sin(phase * pi) * p[4] * (isDark ? 0.45 : 0.25);
      final paint = Paint()
        ..color = c.withAlpha((opacity.clamp(0.0, 0.45) * 255).round())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p[0] * s.width, y), p[2], paint);
    }
  }

  @override
  bool shouldRepaint(_RegParticlePainter o) => o.t != t;
}
