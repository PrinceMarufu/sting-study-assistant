import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'auth/login_screen.dart';
import '../widgets/ssa_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _scrollOffset = 0.0;
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Welcome to SSA",
      "description": "Your ultimate AI-powered study assistant. Manage notes, generate quizzes, and study smarter.",
      "image": "assets/images/study_home.png",
      "icon": "school"
    },
    {
      "title": "AI Chat & Summarizer",
      "description": "Upload PDFs and let AI summarize them for you. Ask questions and get instant explanations.",
      "image": "assets/images/study_notes.png",
      "icon": "auto_awesome"
    },
    {
      "title": "Plan Your Success",
      "description": "Keep track of your study schedule, tasks, and stay on top of your academic goals.",
      "image": "assets/images/study_group.png",
      "icon": "calendar_today"
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _scrollOffset = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case "school":
        return Icons.school_outlined;
      case "auto_awesome":
        return Icons.auto_awesome_outlined;
      case "calendar_today":
        return Icons.calendar_today_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _onNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mathematical cross-fade opacities based on scrollOffset
    double opacity1 = (1.0 - _scrollOffset).clamp(0.0, 1.0);
    double opacity2 = (1.0 - (_scrollOffset - 1.0).abs()).clamp(0.0, 1.0);
    double opacity3 = (_scrollOffset - 1.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Stacked background images with real-time mathematical cross-fading
          Positioned.fill(
            child: Opacity(
              opacity: opacity1,
              child: Image.asset(
                _onboardingData[0]["image"]!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: opacity2,
              child: Image.asset(
                _onboardingData[1]["image"]!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: opacity3,
              child: Image.asset(
                _onboardingData[2]["image"]!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Artistic overlay to darken the edges and make the UI modern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                    Colors.black.withValues(alpha: isDark ? 0.7 : 0.45),
                    Colors.black.withValues(alpha: isDark ? 0.9 : 0.75),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Main Onboarding UI Layout
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini SSA logo mark in glass
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Text(
                          'SSA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black38,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 4. Premium Frosted Glass Bottom Card for Content and Actions
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Accent Icon with soft background glow
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: _currentPage == 0
                                      ? const SSALogo(size: 44)
                                      : Icon(
                                          _getIcon(_onboardingData[_currentPage]["icon"]!),
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Swipeable PageView wrapper just for text & indicator
                              SizedBox(
                                height: 160,
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemCount: _onboardingData.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        Text(
                                          _onboardingData[index]["title"]!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          _onboardingData[index]["description"]!,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 15,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Action Bar: Dots & Circular Next Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Customized Smooth Slider Indicator
                                  Row(
                                    children: List.generate(
                                      _onboardingData.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.only(right: 8),
                                        height: 6,
                                        width: _currentPage == index ? 24 : 6,
                                        decoration: BoxDecoration(
                                          color: _currentPage == index
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.white.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Glowing Next Circular Button
                                  GestureDetector(
                                    onTap: _onNext,
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.black87,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
