import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/sync/sync_service.dart';
import '../../database/database_provider.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  return service;
});

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final database = ref.watch(databaseProvider);
  
  final service = SyncService(
    authService: authService,
    database: database,
  );
  
  return service;
});

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});

// Sync status stream provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
});

// Auth state classes
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userEmail;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userEmail,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userEmail,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _authService.initialize();
    if (_authService.isAuthenticated) {
      state = AuthState(
        isAuthenticated: true,
        userId: _authService.userId,
        userEmail: _authService.userEmail,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.login(email, password);
    
    if (result.success) {
      state = AuthState(
        isAuthenticated: true,
        userId: result.userId,
        userEmail: result.email,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.register(email, password, name);
    
    if (result.success) {
      state = AuthState(
        isAuthenticated: true,
        userId: result.userId,
        userEmail: result.email,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = AuthState(isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
