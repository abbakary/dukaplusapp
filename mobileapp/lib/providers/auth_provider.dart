import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/api_client.dart';
import '../core/constants/app_constants.dart';
import 'api_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth State
// ─────────────────────────────────────────────────────────────────────────────
class AuthState {
  final AuthUser? user;
  final bool isLoading;

  /// True while we are still checking for a saved session on startup.
  /// The router must NOT redirect until this is false.
  final bool isInitialising;

  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialising = true, // starts true; set false after first check
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    bool? isInitialising,
    String? error,
    bool? isAuthenticated,
    bool clearError = false,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isInitialising: isInitialising ?? this.isInitialising,
        error: clearError ? null : (error ?? this.error),
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );

  String get businessType => user?.businessType ?? 'retail';
  String get businessName => user?.businessName ?? 'My Store';
  bool get isOwner => user?.isOwner ?? false;
  bool get isStaff => user?.isStaff ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _restoreSession();
  }

  // ── Session restore on cold start ─────────────────────────────────────────
  Future<void> _restoreSession() async {
    // 1. Try cached user from SharedPreferences (works offline)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(AppConstants.kUserData);
    if (cached != null) {
      try {
        final user = AuthUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isInitialising: false,
        );
        // Silently refresh from API in background (don't block navigation)
        _silentRefresh();
        return;
      } catch (_) {
        await prefs.remove(AppConstants.kUserData);
      }
    }

    // 2. Try live token
    final token = await ApiClient.readAccessToken();
    if (token != null) {
      try {
        final data = await _api.getMe();
        final user = AuthUser.fromJson(data);
        await _persistUser(prefs, user);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isInitialising: false,
        );
        return;
      } catch (_) {
        // Token is invalid — clear it
        await ApiClient.clearTokens();
      }
    }

    // 3. No session
    state = state.copyWith(isInitialising: false);
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await _api.getMe();
      final user = AuthUser.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await _persistUser(prefs, user);
      if (mounted) {
        state = state.copyWith(user: user);
      }
    } catch (_) {/* ignore — we already have cached user */}
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Try live API first
      final tokens = await _api.login(email, password);
      await ApiClient.saveTokens(
        tokens['access_token'].toString(),
        tokens['refresh_token'].toString(),
      );
      final data = await _api.getMe();
      final user = AuthUser.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await _persistUser(prefs, user);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } on DioException catch (de) {
      final msg = _dioErrorMessage(de);
      state = state.copyWith(isLoading: false, error: msg);
      throw Exception(msg);
    } on Exception catch (e) {
      final msg = _exceptionMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<void> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.register(data);
      // Registration succeeded — now log in
      await login(data['email'].toString(), data['password'].toString());
    } on DioException catch (de) {
      final msg = _dioErrorMessage(de);
      state = state.copyWith(isLoading: false, error: msg);
      throw Exception(msg);
    } on Exception catch (e) {
      final msg = _exceptionMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kUserData);
    await ApiClient.clearTokens();
    state = const AuthState(isInitialising: false);
  }

  // ── Update business type (settings screen) ─────────────────────────────────
  void updateBusinessType(String type) {
    if (state.user == null) return;
    final updated = state.user!.copyWith(businessType: type);
    state = state.copyWith(user: updated);
    // Persist the change so it survives restart
    SharedPreferences.getInstance().then((prefs) => _persistUser(prefs, updated));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<void> _persistUser(SharedPreferences prefs, AuthUser user) async {
    await prefs.setString(AppConstants.kUserData, jsonEncode(user.toJson()));
  }

  String _dioErrorMessage(DioException de) {
    final status = de.response?.statusCode;
    if (status == 401) return 'Invalid email or password';
    if (status == 422) return 'Please check your details and try again';
    if (status == 409) return 'An account with this email already exists';
    if (de.type == DioExceptionType.connectionError ||
        de.type == DioExceptionType.connectionTimeout ||
        de.type == DioExceptionType.unknown) {
      final msg = de.message ?? '';
      if (msg.contains('XMLHttpRequest') || msg.contains('CORS')) {
        return 'Cannot reach the local API. Start the backend on port 8000, then hot restart the app.';
      }
      return 'Unable to reach server. Start backend (port 8000) and check your connection.';
    }
    return 'Server error (${status ?? 'unknown'}). Please try again.';
  }

  String _exceptionMessage(Exception e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Invalid email or password';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

final currentUserProvider =
    Provider<AuthUser?>((ref) => ref.watch(authProvider).user);

final businessTypeProvider =
    Provider<String>((ref) => ref.watch(authProvider).businessType);

final isAuthenticatedProvider =
    Provider<bool>((ref) => ref.watch(authProvider).isAuthenticated);
