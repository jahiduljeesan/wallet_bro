import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat_ai/presentation/pages/ai_chat_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../accounts/presentation/pages/accounts_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AIChatPage(), // Actually we check conditionally
    const StatisticsPage(),
    const AccountsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) { // AI Chat tab
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isGuest) {
        _showLoginGateModal(context, auth);
        return; // the index does not change
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showLoginGateModal(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: Theme.of(context).bottomSheetTheme.shape,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.indigoAccent),
                const SizedBox(height: 16),
                Text(
                  'Unlock your Personal AI Financial Assistant 💬',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in with Google to start chatting and easily manage your expenses via voice or text.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // close modal
                    await auth.logout(); // Will navigate to initial/login screen where they can google login
                    // Alternatively, call loginWithGoogle directly:
                    // await auth.loginWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary, // Primary Button
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
