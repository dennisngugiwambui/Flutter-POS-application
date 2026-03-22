import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../dashboard_provider.dart';
import 'auth_provider.dart';

class CreateEmployeeSheet extends ConsumerStatefulWidget {
  const CreateEmployeeSheet({super.key});

  @override
  ConsumerState<CreateEmployeeSheet> createState() => _CreateEmployeeSheetState();
}

class _CreateEmployeeSheetState extends ConsumerState<CreateEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  /// Target role in `profiles` / auth metadata: cashier | manager | admin
  String _role = 'cashier';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please fix the highlighted fields above.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final avail = await ref.read(authRepositoryProvider).registrationAvailability(
            email: _email.text.trim(),
            phone: _phone.text.trim(),
          );
      if (avail.emailTaken) {
        _showMessage('This email is already registered.', error: true);
        return;
      }
      if (avail.phoneTaken) {
        _showMessage('This phone number is already used by another account.', error: true);
        return;
      }

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

      final data = res.data;
      if (data is Map && data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Could not create user');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FunctionException catch (e) {
      if (!mounted) return;
      final msg = e.status == 404
          ? 'Create-user service missing. Deploy Edge Function `admin-create-user` on Supabase (run scripts/deploy_supabase_functions.ps1 after login), then try again.'
          : 'Failed: ${e.reasonPhrase ?? e.toString()}';
      _showMessage(msg, error: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    // Sheet is shown inside a rounded [Material] from the caller — no full-screen [Scaffold].
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withAlpha(70),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'New employee',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                          onPressed: _loading ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _field('Full name', _name, Icons.person_rounded, colorScheme),
                    const SizedBox(height: 10),
                    _field(
                      'Email',
                      _email,
                      Icons.email_rounded,
                      colorScheme,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Required';
                        if (!t.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(
                      'Phone',
                      _phone,
                      Icons.phone_rounded,
                      colorScheme,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Required';
                        if (t.length < 9) return 'Enter at least 9 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(
                      'Temporary password',
                      _password,
                      Icons.lock_rounded,
                      colorScheme,
                      keyboardType: TextInputType.visiblePassword,
                      obscure: true,
                      validator: (v) {
                        final t = (v ?? '');
                        if (t.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Role',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final isManagerOnly = ref.watch(profileProvider).maybeWhen(
                              data: (p) => p?.role.toLowerCase() == 'manager',
                              orElse: () => false,
                            );
                        final roleOptions = isManagerOnly ? ['cashier'] : ['cashier', 'manager', 'admin'];
                        if (!roleOptions.contains(_role)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _role = 'cashier');
                          });
                        }
                        return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in roleOptions)
                          ChoiceChip(
                            label: Text(r[0].toUpperCase() + r.substring(1)),
                            selected: _role == r,
                            onSelected: _loading
                                ? null
                                : (sel) {
                                    if (sel) setState(() => _role = r);
                                  },
                          ),
                      ],
                    );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _create,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('CREATE EMPLOYEE', style: TextStyle(fontWeight: FontWeight.w800)),
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

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
    ColorScheme colorScheme, {
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        errorMaxLines: 2,
      ),
    );
  }
}
