import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/auth_provider.dart';

/// Animated splash screen with ineTeam branding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Navigate after delay cleanly
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();

      void attemptNavigation() {
        if (!mounted) return;
        if (auth.isAuthenticated) {
          if (auth.hasCompletedProfile) {
            context.go('/home');
          } else {
            context.go('/profile-setup');
          }
        } else {
          context.go('/login');
        }
      }

      // If we are currently loading the profile from Firestore, wait up to 8 more seconds.
      if (auth.isAuthenticated && auth.isProfileLoading) {
         int attempts = 0;
         while (auth.isProfileLoading && attempts < 16 && mounted) {
           await Future.delayed(const Duration(milliseconds: 500));
           attempts++;
         }
         // Force navigation whether it finished or timed out
         attemptNavigation();
      } else {
         attemptNavigation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2ECC71).withAlpha(60),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.sports,
                    size: 64,
                    color: Color(0xFF2ECC71),
                  ),
                ),

                const SizedBox(height: 28),

                // App name
                const Text(
                  AppInfo.appName,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  AppInfo.tagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(150),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withAlpha(20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2ECC71),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
