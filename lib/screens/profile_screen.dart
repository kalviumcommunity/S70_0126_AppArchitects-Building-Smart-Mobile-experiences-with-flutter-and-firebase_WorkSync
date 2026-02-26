import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/theme_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 200, // Reduced size for Base64 storage
        maxHeight: 200,
        imageQuality: 50, // Higher compression to keep Firestore documents small
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);

        final File imageFile = File(pickedFile.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        
        // Convert to Base64
        final String base64Image = base64Encode(imageBytes);
        final String dataUrl = "data:image/jpeg;base64,$base64Image";

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Update Firestore with Base64 string
          if (mounted) {
            await Provider.of<DatabaseService>(context, listen: false).updateUserPhoto(dataUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature coming soon!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Profile"),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'name': nameCtrl.text,
                });
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Profile Photo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A73E8)),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A73E8)),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? "user@worksync.com";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, userEmail, user?.uid ?? ""),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                    builder: (context, snapshot) {
                      String userName = "WorkSync User";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        userName = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "WorkSync User";
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Account Settings"),
                          const SizedBox(height: 12),
                          _buildSettingsCard(context, [
                            _SettingsItem(
                              icon: Icons.person_outline,
                              label: "Edit Profile",
                              onTap: () => _showEditProfileDialog(context, userName),
                            ),
                            _SettingsItem(
                              icon: Icons.notifications_none_rounded,
                              label: "Notifications",
                              trailing: const Text("On", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              onTap: () => _showComingSoon(context, "Notifications toggle"),
                            ),
                            _SettingsItem(
                              icon: Icons.security_outlined,
                              label: "Security",
                              onTap: () => _showComingSoon(context, "Security settings"),
                            ),
                          ]),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle("Preferences"),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, theme, _) => _buildSettingsCard(context, [
                      _SettingsItem(
                        icon: Icons.language_rounded,
                        label: "Language",
                        trailing: const Text("English", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        onTap: () => _showComingSoon(context, "Language selection"),
                      ),
                      _SettingsItem(
                        icon: Icons.dark_mode_outlined,
                        label: "Dark Mode",
                        trailing: Switch(
                          value: theme.isDarkMode,
                          onChanged: (val) => theme.toggleTheme(val),
                          activeColor: const Color(0xFF1A73E8),
                        ),
                        onTap: () => theme.toggleTheme(!theme.isDarkMode),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle("More"),
                  const SizedBox(height: 12),
                  _buildSettingsCard(context, [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      label: "Help Center",
                      onTap: () => _showComingSoon(context, "Help Center"),
                    ),
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      label: "About WorkSync",
                      onTap: () => _showComingSoon(context, "About WorkSync"),
                    ),
                  ]),
                  const SizedBox(height: 40),
                  _buildLogoutButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String email, String uid) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF1A73E8),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              String name = "WorkSync User";
              String? photoData;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? "WorkSync User";
                photoData = data['photoUrl'];
              }

              ImageProvider? imageProvider;
              if (photoData != null && photoData.startsWith("data:image")) {
                try {
                  final String base64String = photoData.split(",")[1];
                  imageProvider = MemoryImage(base64Decode(base64String));
                } catch (e) {
                  print("Error decoding base64 image: $e");
                }
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "U",
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showPickerOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF1A73E8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Projects", "12", Icons.folder_open_rounded, const Color(0xFF1A73E8)),
          _buildDivider(),
          _buildStatItem("Tasks", "48", Icons.check_circle_outline_rounded, const Color(0xFF0F9D58)),
          _buildDivider(),
          _buildStatItem("Clients", "8", Icons.people_outline_rounded, const Color(0xFF7B2FF7)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Theme.of(context).dividerColor.withAlpha((0.2 * 255).round()),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white.withAlpha((0.05 * 255).round())
                        : Colors.grey.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w600, 
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: item.trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text(
          "Logout",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDB4437),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
}
