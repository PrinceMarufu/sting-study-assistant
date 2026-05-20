import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
    // Loop the floating effect after the initial entrance
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.repeat(reverse: true);
      }
    });

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        final user = ref.read(currentUserProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => user != null ? const MainShell() : const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Creative Photographic/Illustrative Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/study_laptop.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Premium Frosted Glass overlay over the entire screen
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      isDark 
                          ? Colors.black.withValues(alpha: 0.45) 
                          : Colors.white.withValues(alpha: 0.25),
                      isDark 
                          ? Colors.black.withValues(alpha: 0.85) 
                          : Colors.white.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Central Brand Composition
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatAnimation.value),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stunning Glassmorphic Brand Container
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            )
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.4),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
                              Colors.white.withValues(alpha: isDark ? 0.02 : 0.1),
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Center(
                              child: Text(
                                'SSA',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      
                      // Typography with subtle drop shadows
                      Text(
                        'Sting Study Assistant',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: isDark ? Colors.black38 : Colors.white60,
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Secondary tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'AI-Powered Productivity',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
