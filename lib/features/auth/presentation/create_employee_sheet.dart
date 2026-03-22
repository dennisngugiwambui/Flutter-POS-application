import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../dashboard_provider.dart';
import '../../../core/app_theme.dart';
import 'auth_provider.dart';

class CreateEmployeeSheet extends ConsumerStatefulWidget {
  const CreateEmployeeSheet({super.key});

  @override
  ConsumerState<CreateEmployeeSheet> createState() => _CreateEmployeeSheetState();
}

class _CreateEmployeeSheetState extends ConsumerState<CreateEmployeeSheet>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _phone    = TextEditingController();
  final _password = TextEditingController();

  bool   _loading = false;
  bool   _obscure = true;
  String _role    = 'cashier';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose();
    _phone.dispose(); _password.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
          color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: error ? kError : kPrimary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final avail = await ref.read(authRepositoryProvider).registrationAvailability(
        email: _email.text.trim(),
        phone: _phone.text.trim(),
      );
      if (avail.emailTaken) { _showMsg('Email already registered.', error: true); return; }
      if (avail.phoneTaken) { _showMsg('Phone already used.', error: true); return; }

      final res = await Supabase.instance.client.functions.invoke(
        'admin-create-user',
        body: {
          'email': _email.text.trim(),
          'password': _password.text,
          'full_name': _name.text.trim(),
          'phone_number': _phone.text.trim(),
          'role': _role,
        },
      );

      if (res.status != 200) {
        final data = res.data;
        final err = data is Map ? (data['error'] ?? data['detail'] ?? data) : data;
        throw Exception(err?.toString() ?? 'Request failed (${res.status})');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FunctionException catch (e) {
      if (!mounted) return;
      final msg = e.status == 404
          ? 'Deploy Edge Function `admin-create-user` on Supabase first.'
          : 'Failed: ${e.reasonPhrase ?? e.toString()}';
      _showMsg(msg, error: true);
    } catch (e) {
      if (!mounted) return;
      _showMsg('Failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final isManagerOnly = profileAsync.maybeWhen(
      data: (p) => p?.role.toLowerCase() == 'manager',
      orElse: () => false,
    );
    final roleOptions = isManagerOnly ? ['cashier'] : ['cashier', 'manager', 'admin'];
    // Only clamp role once profile is known — while loading, keep full options so admin selections aren't reset to cashier.
    final profile = profileAsync.maybeWhen(data: (p) => p, orElse: () => null);
    if (profile != null) {
      final opts = profile.role.toLowerCase() == 'manager'
          ? ['cashier']
          : ['cashier', 'manager', 'admin'];
      if (!opts.contains(_role)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _role = 'cashier');
        });
      }
    }

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxScrollH = MediaQuery.sizeOf(context).height * 0.72;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle + header ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                  child: Column(children: [
                    // Drag handle
                    Center(child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                    const SizedBox(height: 14),
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B8B5A), Color(0xFF26B573)]),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Employee', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            color: kText, letterSpacing: -0.4,
                          )),
                          Text('Fill in the details below', style: TextStyle(
                            fontSize: 12, color: kTextSub,
                          )),
                        ],
                      )),
                      GestureDetector(
                        onTap: _loading ? null : () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: kSurface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: kTextSub),
                        ),
                      ),
                    ]),
                  ]),
                ),
                Divider(height: 20, color: kBorder.withAlpha(160), indent: 20, endIndent: 20),

                // ── Scrollable form ─────────────────────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxScrollH),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fields
                          _SheetField(
                            label: 'Full Name',
                            controller: _name,
                            icon: Icons.person_outline_rounded,
                            hint: 'John Doe',
                          ),
                          const SizedBox(height: 14),
                          _SheetField(
                            label: 'Email Address',
                            controller: _email,
                            icon: Icons.email_outlined,
                            hint: 'employee@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Required';
                              if (!t.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _SheetField(
                            label: 'Phone Number',
                            controller: _phone,
                            icon: Icons.phone_outlined,
                            hint: '07XX XXX XXX',
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Required';
                              if (t.length < 9) return 'Enter at least 9 digits';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _SheetField(
                            label: 'Temporary Password',
                            controller: _password,
                            icon: Icons.lock_outline_rounded,
                            hint: 'Min. 6 characters',
                            obscure: _obscure,
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: kTextMuted, size: 18,
                              ),
                            ),
                            validator: (v) =>
                              (v ?? '').length < 6 ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 20),

                          // Role selector
                          const Text('Assign Role', style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: kText,
                          )),
                          const SizedBox(height: 10),
                          Row(children: roleOptions.map((r) {
                            final active = _role == r;
                            final colors = {
                              'admin':   kWarning,
                              'manager': kAccent,
                              'cashier': kPrimary,
                            };
                            final icons = {
                              'admin':   Icons.admin_panel_settings_rounded,
                              'manager': Icons.manage_accounts_rounded,
                              'cashier': Icons.point_of_sale_rounded,
                            };
                            final c = colors[r] ?? kPrimary;
                            return Expanded(child: Padding(
                              padding: EdgeInsets.only(right: r != roleOptions.last ? 10 : 0),
                              child: GestureDetector(
                                onTap: _loading ? null : () => setState(() => _role = r),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? LinearGradient(colors: [c, c.withAlpha(200)])
                                        : null,
                                    color: active ? null : kSurface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: active ? c : kBorder, width: 0.9),
                                    boxShadow: active
                                        ? [BoxShadow(color: c.withAlpha(50), blurRadius: 10, offset: const Offset(0, 3))]
                                        : null,
                                  ),
                                  child: Column(children: [
                                    Icon(icons[r], color: active ? Colors.white : kTextSub, size: 22),
                                    const SizedBox(height: 5),
                                    Text(
                                      r[0].toUpperCase() + r.substring(1),
                                      style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w800,
                                        color: active ? Colors.white : kTextSub,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ));
                          }).toList()),
                          const SizedBox(height: 24),

                          // Create button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _create,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                disabledBackgroundColor: kPrimary.withAlpha(100),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Create Employee', style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      )),
                                    ]),
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
        ),
      ),
    );
  }
}

// ── Sheet form field ───────────────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _SheetField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: kText,
      )),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextMuted, fontWeight: FontWeight.w400, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon: suffix != null ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: suffix,
          ) : null,
          filled: true,
          fillColor: kSurface2,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorMaxLines: 2,
        ),
      ),
    ]);
  }
}
