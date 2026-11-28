import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FakeAuthRepository(),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  /// Null means signed out.
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> restoreSession() async {
    final user = await ref.read(authRepositoryProvider).currentUser();
    state = AuthState(user: user);
  }

  Future<void> signIn(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password),
  );

  Future<void> signUp(String name, String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUp(name: name, email: email, password: password),
  );

  /// Drops an old error when the user moves to another auth screen.
  void clearError() {
    if (state.errorMessage != null) state = const AuthState();
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState();
  }

  Future<void> _run(Future<AppUser> Function() action) async {
    if (state.isLoading) return;
    state = const AuthState(isLoading: true);
    try {
      state = AuthState(user: await action());
    } on AuthException catch (e) {
      state = AuthState(errorMessage: e.message);
    }
  }
}
