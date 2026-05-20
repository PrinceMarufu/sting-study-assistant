import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'home/home_screen.dart';
import 'ai/ai_chat_screen.dart';
import 'notes/notes_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AiChatScreen(),
    const NotesScreen(),
    const ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
      'label': 'Home',
    },
    {
      'icon': Icons.auto_awesome_outlined,
      'activeIcon': Icons.auto_awesome_rounded,
      'label': 'Assistant',
    },
    {
      'icon': Icons.note_alt_outlined,
      'activeIcon': Icons.note_alt_rounded,
      'label': 'Notes',
    },
    {
      'icon': Icons.person_outline_rounded,
      'activeIcon': Icons.person_rounded,
      'label': 'Profile',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Ensures navigation bar doesn't warp with keyboards
      body: Stack(
        children: [
          // 1. Core Screen Panel with bottom padding to ensure content is not hidden by the floating bar
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Padding to allow scrolling past bottom bar
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
          
          // 2. High-end Premium Floating Navigation Bar
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.7) 
                    : Colors.black.withValues(alpha: 0.85), // Keep bottom bar premium dark
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final isActive = _currentIndex == index;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated circle background glow for active item
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  isActive ? item['activeIcon'] : item['icon'],
                                  size: 24,
                                  color: isActive 
                                      ? Theme.of(context).colorScheme.primary 
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Active underline bar indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: isActive ? 16 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
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
