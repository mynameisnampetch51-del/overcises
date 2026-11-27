class AppUser {
  const AppUser({required this.name, required this.email});

  final String name;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

/// What the screens need from authentication.
/// A real backend can replace [FakeAuthRepository] without touching the UI.
abstract interface class AuthRepository {
  /// The user still logged in from earlier, or null.
  Future<AppUser?> currentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

/// In-memory accounts for the demo. Everything is lost on restart.
class FakeAuthRepository implements AuthRepository {
  static const demoEmail = 'demo@overcise.app';
  static const demoPassword = '123456';
  static const _delay = Duration(milliseconds: 600);

  final Map<String, ({String name, String password})> _accounts = {
    demoEmail: (name: 'Demo', password: demoPassword),
  };

  AppUser? _current;

  @override
  Future<AppUser?> currentUser() async => _current;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_delay);
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account.password != password) {
      throw const AuthException('Wrong email or password');
    }
    return _current = AppUser(name: account.name, email: key);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_delay);
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('This email already has an account');
    }
    _accounts[key] = (name: name.trim(), password: password);
    return _current = AppUser(name: name.trim(), email: key);
  }

  @override
  Future<void> signOut() async => _current = null;
}
