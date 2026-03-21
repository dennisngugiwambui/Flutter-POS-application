import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Normalizes phone to digits only for comparison (matches SQL `check_registration_available`).
  static String normalizePhoneDigits(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  /// Whether [email] / [phone] are already used on another profile (case-insensitive email, digit phone).
  Future<({bool emailTaken, bool phoneTaken})> registrationAvailability({
    required String email,
    required String phone,
  }) async {
    final raw = await _supabase.rpc(
      'check_registration_available',
      params: {'p_email': email.trim(), 'p_phone': phone.trim()},
    );
    if (raw is Map) {
      return (
        emailTaken: raw['email_taken'] == true,
        phoneTaken: raw['phone_taken'] == true,
      );
    }
    throw Exception('Could not verify email and phone availability.');
  }

  /// True when at least one profile has role `admin` (shop already has an owner).
  /// Used so only the first self-registration becomes admin; later signups are clients only.
  Future<bool> hasAdminUser() async {
    final v = await _supabase.rpc('has_admin_user');
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == 't';
    if (v is num) return v != 0;
    return false;
  }

  /// First user only — creates the shop owner (admin). After an admin exists, use [signUpClient].
  Future<AuthResponse> signUpShopOwner({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'phone_number': phone,
        'role': 'admin',
      },
    );
    return response;
  }

  /// When a shop admin already exists — public self-registration for catalog / requests only.
  Future<AuthResponse> signUpClient({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'phone_number': phone,
        'role': 'client',
      },
    );
  }

  Future<ProfileModel?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return ProfileModel.fromJson(response);
  }

  Future<AuthResponse> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    if (emailOrPhone.contains('@')) {
      return await _supabase.auth.signInWithPassword(
        email: emailOrPhone,
        password: password,
      );
    } else {
      return await _supabase.auth.signInWithPassword(
        phone: emailOrPhone,
        password: password,
      );
    }
  }

  /// Clears the local session and revokes the refresh token on the server so
  /// another account can sign in on this device.
  Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.global);
  }

  User? get currentUser => _supabase.auth.currentUser;
}
