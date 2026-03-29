import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import '../../../dashboard/presentation/pages/main_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (auth.status == AuthStatus.unauthenticated) {
          return const LoginPage();
        } else {
          // Both Guest and Authenticated go to the main dashboard navigation
          return const MainNavigation();
        }
      },
    );
  }
}
