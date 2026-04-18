import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main shell with bottom navigation for Home, My Matches, and Profile.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  // Calculate the selected index based on current route
  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // Default to My Matches
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/my-matches');
              break;
            case 1:
              context.go('/home');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_outlined),
            activeIcon: Icon(Icons.sports),
            label: 'My Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
