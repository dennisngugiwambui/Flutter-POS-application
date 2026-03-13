import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
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
        'role': 'admin', // Initial user is admin
      },
    );
    return response;
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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
