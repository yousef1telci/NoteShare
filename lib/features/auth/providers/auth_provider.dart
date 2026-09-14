import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _supabase;

  AuthController(this._supabase) : super(const AsyncValue.data(null));

  String _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (msg.contains('user_already_exists') || msg.contains('already registered') || msg.contains('user already exists')) {
      return 'Email already registered';
    }
    // Fallback: Return the actual message (e.g., 'Rate limit exceeded', 'Password should be at least 6 characters')
    // instead of hiding it behind a generic string, so users understand why signup failed.
    return e.message;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } on AuthException catch (e, st) {
      state = AsyncValue.error(_mapAuthException(e), st);
    } catch (e, st) {
      state = AsyncValue.error('An unexpected error occurred, please try again later.', st);
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      state = const AsyncValue.data(null);
    } on AuthException catch (e, st) {
      state = AsyncValue.error(_mapAuthException(e), st);
    } catch (e, st) {
      state = AsyncValue.error('An unexpected error occurred, please try again later.', st);
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(supabaseProvider));
});

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  try {
    final response = await supabase.from('profiles').select().eq('id', user.id).single();
    return response;
  } catch (e) {
    return null;
  }
});
