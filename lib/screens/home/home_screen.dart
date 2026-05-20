import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import 'quiz_screen.dart';
import 'planner_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../notes/notes_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(currentUserProvider);
    final notesAsync = ref.watch(notesStreamProvider);

    final userName = userProfileAsync.maybeWhen(
      data: (profile) => profile?.fullName ?? authUser?.email?.split('@').first ?? 'Student',
      orElse: () => authUser?.email?.split('@').first ?? 'Student',
    );

    final profileImageUrl = userProfileAsync.maybeWhen(
      data: (profile) => profile?.profileImage,
      orElse: () => null,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Creative Photographic Background (workspace tabletop)
          Positioned.fill(
            child: Image.asset(
              'assets/images/study_laptop.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Global Frosted Glass Blur & Radial Dark Gradient Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
                      Colors.black.withValues(alpha: isDark ? 0.75 : 0.55),
                      Colors.black.withValues(alpha: isDark ? 0.92 : 0.82),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Scrollable Home Dashboard content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium App Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready to ace your exams?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Circle avatar with white glass frame
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                          child: profileImageUrl == null
                              ? Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Daily Quote Glassmorphic Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(22.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Quote of the Day',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '"Success is not final, failure is not fatal: it is the courage to continue that counts."',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Redesigned Compact Quick Access Section
                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isDesktop = width > 600;
                      
                      // Card height: 120 on desktop, 108 on mobile
                      final cardHeight = isDesktop ? 120.0 : 108.0;
                      
                      final grid = Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: _InteractiveQuickCard(
                                    title: 'Ask AI',
                                    icon: Icons.chat_bubble_outline_rounded,
                                    color: const Color(0xFF00BFA6), // Teal accent
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const AiChatScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: _InteractiveQuickCard(
                                    title: 'Summarize PDF',
                                    icon: Icons.analytics_outlined,
                                    color: const Color(0xFFFF5A79), // Coral accent
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const NotesScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: _InteractiveQuickCard(
                                    title: 'Generate Quiz',
                                    icon: Icons.lightbulb_outline_rounded,
                                    color: const Color(0xFFFF9100), // Amber accent
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const QuizScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: _InteractiveQuickCard(
                                    title: 'Study Planner',
                                    icon: Icons.event_note_outlined,
                                    color: const Color(0xFF2979FF), // Electric Blue accent
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const PlannerScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );

                      if (isDesktop) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: grid,
                          ),
                        );
                      }
                      
                      return grid;
                    },
                  ),
                  const SizedBox(height: 36),

                  // Recent Notes Section
                  const Text(
                    'Recent Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  notesAsync.when(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(22.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Center(
                            child: Text(
                              'No notes saved yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      }

                      final recentList = notes.take(3).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentList.length,
                        itemBuilder: (context, index) {
                          final note = recentList[index];
                          final dateStr = DateFormat('MMM dd, yyyy').format(note.updatedAt);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.note_alt_rounded, 
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    note.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Updated $dateStr',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded, 
                                    color: Colors.white70,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const NotesScreen()),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Failed to load notes: $err', style: const TextStyle(color: Colors.red))),
                  ),
                  const SizedBox(height: 100), // Additional padding to prevent floating bar overlapping content
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom interactive Quick Card widget with bounce animation on tap
class _InteractiveQuickCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InteractiveQuickCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_InteractiveQuickCard> createState() => _InteractiveQuickCardState();
}

class _InteractiveQuickCardState extends State<_InteractiveQuickCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: isDark ? 0.35 : 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: isDark ? 0.08 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: isDark ? Colors.white : widget.color,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
