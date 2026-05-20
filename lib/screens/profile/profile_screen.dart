import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../auth/login_screen.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _uploadProfileImage(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        
        messenger.showSnackBar(
          const SnackBar(content: Text('Uploading profile image...')),
        );

        final imageUrl = await ref.read(authRepositoryProvider).uploadProfileImage(
          result.files.single.name,
          bytes,
        );

        if (imageUrl != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(userProfileProvider);
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName, String currentAcademicLevel) {
    final nameController = TextEditingController(text: currentName);
    final academicController = TextEditingController(text: currentAcademicLevel);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[950],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: academicController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Academic Level / Course',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Academic info required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final client = ref.read(supabaseClientProvider);
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;

                  await client.from('users').update({
                    'full_name': nameController.text.trim(),
                    'academic_level': academicController.text.trim(),
                  }).eq('id', user.id);

                  ref.invalidate(userProfileProvider);
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Solid Black Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          final userName = profile?.fullName ?? authUser?.email?.split('@').first ?? 'Student User';
          final userEmail = profile?.email ?? authUser?.email ?? 'student@university.edu';
          final academicLevel = profile?.academicLevel ?? 'Undergraduate';
          final profileImageUrl = profile?.profileImage;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // Profile Header with glowing multi-layered neon border
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _uploadProfileImage(context, ref),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Neon Glowing Blue Outer Ring
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFF2979FF),
                                    Color(0xFF00BFA6),
                                    Color(0xFFFF5A79),
                                    Color(0xFF2979FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2979FF).withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Black inner separator ring
                            Container(
                              width: 108,
                              height: 108,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                            
                            // Core Profile Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[900],
                              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                              child: profileImageUrl == null
                                  ? Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        fontSize: 36,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tap photo to change',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          academicLevel,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Settings Cards with premium dark glassmorphism
                _buildOptionTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () => _showEditProfileDialog(context, ref, userName, academicLevel),
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Theme Mode',
                  onTap: () {},
                  trailing: Switch(
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    value: true, // App theme is kept modern dark
                    onChanged: (value) {},
                  ),
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const SizedBox(height: 28),
                
                // Modern glowing red Logout Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120), // Padding to clear bottom navigation bar
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load profile: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04), // Translucent card fill
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white70, size: 22),
            ),
            title: Text(
              title, 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
