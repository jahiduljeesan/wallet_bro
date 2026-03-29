import 'package:flutter/material.dart';
import '../../../../core/services/hive_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  guest,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _userId;

  AuthStatus get status => _status;
  String? get userId => _userId;

  bool get isGuest => _status == AuthStatus.guest;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final settingsBox = HiveService.settingsBox;
    final isGuestLoggedIn = settingsBox.get('is_guest', defaultValue: false);
    final storedUserId = settingsBox.get('user_id');

    if (storedUserId != null) {
      _userId = storedUserId;
      _status = AuthStatus.authenticated;
    } else if (isGuestLoggedIn) {
      _status = AuthStatus.guest;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    final settingsBox = HiveService.settingsBox;
    await settingsBox.put('is_guest', true);
    await settingsBox.delete('user_id');
    _status = AuthStatus.guest;
    _userId = null;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    // Scaffold for actual Google/Firebase signin
    // Simulating login flow
    final settingsBox = HiveService.settingsBox;
    await settingsBox.put('user_id', 'google_user_123');
    await settingsBox.put('is_guest', false);
    
    _userId = 'google_user_123';
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    final settingsBox = HiveService.settingsBox;
    await settingsBox.delete('is_guest');
    await settingsBox.delete('user_id');
    _status = AuthStatus.unauthenticated;
    _userId = null;
    notifyListeners();
  }
}
