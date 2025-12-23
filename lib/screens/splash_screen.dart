import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showButtons = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Show first screen for 4 seconds, then show buttons
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showButtons = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goToSignup() {
    Navigator.of(context).pushReplacementNamed('/signup');
  }

  @override
  Widget build(BuildContext context) {
    if (_showButtons) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showButtons ? _buildSecondScreen() : _buildFirstScreen(),
      ),
    );
  }

  Widget _buildFirstScreen() {
    return Container(
      key: const ValueKey('first'),
      color: const Color(0xFF4F46E5),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'INVOICO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Professional Invoice Management',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondScreen() {
    return Container(
      key: const ValueKey('second'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with elevated shadow
                    PhysicalModel(
                      color: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: BoxShape.circle,
                      child: Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4F46E5).withOpacity(0.08),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Builder(builder: (context) {
                          final theme = Theme.of(context);
                          // Use the same logo icon as Splash Screen 1
                          return Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: theme.colorScheme.primary,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Brand name with enhanced typography
                    const Text(
                      'INVOICO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Professional Invoice Management',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  // Primary Sign In button with gradient
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Builder(builder: (context) {
                      final primaryColor =
                          Theme.of(context).colorScheme.primary;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4F46E5),
                              Color(0xFF3730A3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _goToLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  // Secondary Sign Up button with stronger border
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Builder(builder: (context) {
                      final primaryColor =
                          Theme.of(context).colorScheme.primary;
                      return OutlinedButton(
                        onPressed: _goToSignup,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFF4F46E5),
                            width: 2.0,
                          ),
                          foregroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4F46E5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
