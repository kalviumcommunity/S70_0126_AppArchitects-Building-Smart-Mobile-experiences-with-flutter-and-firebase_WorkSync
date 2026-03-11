import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../services/database_service.dart';
import '../services/theme_provider.dart';
import '../services/language_provider.dart';
import 'login_screen.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/client.dart';
import 'about_screen.dart';
import 'help_center_screen.dart';
import '../utils/app_security.dart';
import '../widgets/translated_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isUploadingCover = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      AppSecurity.pauseLifecycleLock = true;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 200, // Reduced size for Base64 storage
        maxHeight: 200,
        imageQuality: 50, // Higher compression to keep Firestore documents small
      );
      AppSecurity.lastAuthenticateTime = DateTime.now();
      AppSecurity.pauseLifecycleLock = false;

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
              const SnackBar(
                content: TranslatedText('Profile photo updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Error updating photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      AppSecurity.pauseLifecycleLock = true;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 60,
      );
      AppSecurity.lastAuthenticateTime = DateTime.now();
      AppSecurity.pauseLifecycleLock = false;

      if (pickedFile != null) {
        setState(() => _isUploadingCover = true);

        final File imageFile = File(pickedFile.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        
        final String base64Image = base64Encode(imageBytes);
        final String dataUrl = "data:image/jpeg;base64,$base64Image";

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          if (mounted) {
            await Provider.of<DatabaseService>(context, listen: false).updateUserCover(dataUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: TranslatedText('Cover photo updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Error updating cover: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCover = false);
      }
    }
  }

  void _confirmRemovePhoto() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const TranslatedText("Remove Photo"),
        content: const TranslatedText("Are you sure you want to remove your profile photo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const TranslatedText("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                setState(() => _isUploading = true);
                if (mounted) {
                  await Provider.of<DatabaseService>(context, listen: false).updateUserPhoto("remove_photo");
                  setState(() => _isUploading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: TranslatedText('Profile photo removed'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const TranslatedText("Remove"),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveCover() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const TranslatedText("Remove Background"),
        content: const TranslatedText("Are you sure you want to remove your background image?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const TranslatedText("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                setState(() => _isUploadingCover = true);
                if (mounted) {
                  await Provider.of<DatabaseService>(context, listen: false).updateUserCover("remove_cover");
                  setState(() => _isUploadingCover = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: TranslatedText('Background removed'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const TranslatedText("Remove"),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      const Color(0xFF1A73E8), // Default Blue
      const Color(0xFF0F9D58), // Green
      const Color(0xFFDB4437), // Red
      const Color(0xFFF4B400), // Yellow
      const Color(0xFF7B2FF7), // Purple
      const Color(0xFFE91E8C), // Pink
      const Color(0xFF212121), // Dark
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TranslatedText("Select Background Color", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((color) {
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final String colorString = "color:#${color.value.toRadixString(16).substring(2)}";
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        setState(() => _isUploadingCover = true);
                        await Provider.of<DatabaseService>(context, listen: false).updateUserCover(colorString);
                        setState(() => _isUploadingCover = false);
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCoverPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                child: TranslatedText("Background Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A73E8)),
                title: const TranslatedText("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickCover(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A73E8)),
                title: const TranslatedText("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickCover(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens_rounded, color: Color(0xFF1A73E8)),
                title: const TranslatedText("Choose Solid Color"),
                onTap: () {
                  Navigator.pop(context);
                  _showColorPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const TranslatedText("Remove Background", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveCover();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText("$feature coming soon!"),
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
        title: const TranslatedText("Edit Profile"),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const TranslatedText("Cancel")),
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
            child: const TranslatedText("Save"),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(String currentTargetLang) {
    final indianLanguages = ["Hindi", "Bengali", "Telugu", "Marathi", "Tamil", "Urdu", "Gujarati", "Kannada", "Odia", "Malayalam"];
    final internationalLanguages = ["English", "Mandarin", "Spanish", "French", "Arabic", "Russian", "Portuguese", "German", "Japanese"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: TranslatedText("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF1A73E8),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF1A73E8),
                        tabs: [Tab(text: "Indian"), Tab(text: "International")],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView.builder(
                              itemCount: indianLanguages.length,
                              itemBuilder: (ctx, i) => ListTile(
                                title: Text(indianLanguages[i]),
                                trailing: currentTargetLang == indianLanguages[i] ? const Icon(Icons.check, color: Color(0xFF1A73E8)) : null,
                                onTap: () => _updateLanguage(indianLanguages[i], context),
                              ),
                            ),
                            ListView.builder(
                              itemCount: internationalLanguages.length,
                              itemBuilder: (ctx, i) => ListTile(
                                title: Text(internationalLanguages[i]),
                                trailing: currentTargetLang == internationalLanguages[i] ? const Icon(Icons.check, color: Color(0xFF1A73E8)) : null,
                                onTap: () => _updateLanguage(internationalLanguages[i], context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateLanguage(String newLang, BuildContext ctx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'language': newLang});
    }
    if (ctx.mounted) {
      Provider.of<LanguageProvider>(ctx, listen: false).setLanguage(newLang);
      Navigator.pop(ctx);
    }
  }

  void _showSecurityBottomSheet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isBiometricEnabled = prefs.getBool('${user.uid}_biometric_enabled') ?? false;
    bool isFaceUnlockEnabled = prefs.getBool('${user.uid}_face_unlock_enabled') ?? false;

    final LocalAuthentication auth = LocalAuthentication();
    List<BiometricType> availableBiometrics = [];
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } catch (e) {}
    
    // Check if Face ID or strong biometrics are available
    bool hasFaceId = availableBiometrics.contains(BiometricType.face) || 
                     availableBiometrics.contains(BiometricType.strong);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: TranslatedText("Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: Color(0xFF1A73E8)),
                    title: const TranslatedText("Reset Password"),
                    subtitle: const TranslatedText("Send a password reset email"),
                    onTap: () async {
                      Navigator.pop(context);
                      final user = FirebaseAuth.instance.currentUser;
                      if (user?.email != null) {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: TranslatedText('Password reset email sent!'), backgroundColor: Colors.green));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: TranslatedText('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: Color(0xFF1A73E8)),
                    title: const TranslatedText("App Lock (Device Passcode or Biometric)"),
                    subtitle: const TranslatedText("Require authentication to open the app"),
                    value: isBiometricEnabled,
                    activeColor: const Color(0xFF1A73E8),
                    onChanged: (val) async {
                      try {
                        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
                        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
                        
                        if (!canAuthenticate) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: TranslatedText('Authentication not available on this device.')));
                          return;
                        }

                        AppSecurity.isAuthenticating = true;
                        final bool didAuthenticate = await auth.authenticate(
                          localizedReason: 'Please authenticate to toggle security setting',
                          biometricOnly: false,
                        );
                        AppSecurity.lastAuthenticateTime = DateTime.now();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          AppSecurity.isAuthenticating = false;
                        });

                        if (didAuthenticate) {
                          await prefs.setBool('${user.uid}_biometric_enabled', val);
                          setModalState(() => isBiometricEnabled = val);
                        }
                      } catch (e) {
                        AppSecurity.lastAuthenticateTime = DateTime.now();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          AppSecurity.isAuthenticating = false;
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: TranslatedText('Error during authentication: $e')));
                      }
                    },
                  ),
                  if (hasFaceId)
                    SwitchListTile(
                      secondary: const Icon(Icons.face_retouching_natural, color: Color(0xFF1A73E8)),
                      title: const TranslatedText("Face Unlock"),
                      subtitle: const TranslatedText("Require Face ID to open the app"),
                      value: isFaceUnlockEnabled,
                      activeColor: const Color(0xFF1A73E8),
                      onChanged: (val) async {
                        try {
                          AppSecurity.isAuthenticating = true;
                          final bool didAuthenticate = await auth.authenticate(
                            localizedReason: 'Verify Face ID to toggle Face Unlock',
                            biometricOnly: false,
                          );
                          AppSecurity.lastAuthenticateTime = DateTime.now();
                          Future.delayed(const Duration(milliseconds: 500), () {
                            AppSecurity.isAuthenticating = false;
                          });

                          if (didAuthenticate) {
                            await prefs.setBool('${user.uid}_face_unlock_enabled', val);
                            setModalState(() => isFaceUnlockEnabled = val);
                          }
                        } catch (e) {
                          AppSecurity.lastAuthenticateTime = DateTime.now();
                          Future.delayed(const Duration(milliseconds: 500), () {
                            AppSecurity.isAuthenticating = false;
                          });
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: TranslatedText('Error during Face ID toggle: $e')));
                        }
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                child: TranslatedText("Profile Photo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A73E8)),
                title: const TranslatedText("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A73E8)),
                title: const TranslatedText("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const TranslatedText("Remove Photo", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemovePhoto();
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
    final lang = Provider.of<LanguageProvider>(context);
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
                  user?.uid != null && user!.uid.isNotEmpty
                    ? StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                        builder: (context, snapshot) {
                          String userName = "WorkSync User";
                          bool notificationsEnabled = true;
                          String currentLanguage = "English";
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            userName = data['name'] ?? "WorkSync User";
                            notificationsEnabled = data['notificationsEnabled'] ?? true;
                            currentLanguage = data['language'] ?? "English";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(lang.translate("Account Settings")),
                              const SizedBox(height: 12),
                              _buildSettingsCard(context, [
                                _SettingsItem(
                                  icon: Icons.person_outline,
                                  label: lang.translate("Edit Profile"),
                                  onTap: () => _showEditProfileDialog(context, userName),
                                ),
                                _SettingsItem(
                                  icon: Icons.notifications_none_rounded,
                                  label: lang.translate("Notifications"),
                                  trailing: Switch(
                                    value: notificationsEnabled,
                                    onChanged: (val) async {
                                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                        'notificationsEnabled': val,
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(val ? "Notifications Enabled" : "Notifications Disabled"),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: val ? Colors.green : Colors.grey.shade800,
                                            duration: const Duration(seconds: 2),
                                          )
                                        );
                                      }
                                    },
                                    activeColor: const Color(0xFF1A73E8),
                                  ),
                                  onTap: () async {
                                    bool newValue = !notificationsEnabled;
                                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                      'notificationsEnabled': newValue,
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(newValue ? "Notifications Enabled" : "Notifications Disabled"),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: newValue ? Colors.green : Colors.grey.shade800,
                                          duration: const Duration(seconds: 2),
                                        )
                                      );
                                    }
                                  },
                                ),
                                _SettingsItem(
                                  icon: Icons.security_outlined,
                                  label: lang.translate("Security"),
                                  onTap: () => _showSecurityBottomSheet(),
                                ),
                              ]),
                            ],
                          );
                        }
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(lang.translate("Account Settings")),
                          const SizedBox(height: 12),
                          _buildSettingsCard(context, [
                            _SettingsItem(
                              icon: Icons.person_outline,
                              label: lang.translate("Edit Profile"),
                              onTap: () => _showEditProfileDialog(context, "WorkSync User"),
                            ),
                            _SettingsItem(
                              icon: Icons.notifications_none_rounded,
                              label: lang.translate("Notifications"),
                              trailing: Switch(
                                value: false,
                                onChanged: null,
                                activeColor: const Color(0xFF1A73E8),
                              ),
                              onTap: () => _showComingSoon(context, "Login to use notifications"),
                            ),
                            _SettingsItem(
                              icon: Icons.security_outlined,
                              label: lang.translate("Security"),
                              onTap: () => _showSecurityBottomSheet(),
                            ),
                          ]),
                        ],
                      ),
                  const SizedBox(height: 28),
                  _buildSectionTitle(lang.translate("Preferences")),
                  const SizedBox(height: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: user?.uid != null ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots() : const Stream.empty(),
                    builder: (context, snapshot) {
                      String currentLanguage = "English";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        currentLanguage = (snapshot.data!.data() as Map<String, dynamic>)['language'] ?? "English";
                      }
                      return Consumer<ThemeProvider>(
                        builder: (context, theme, _) => _buildSettingsCard(context, [
                          _SettingsItem(
                            icon: Icons.language_rounded,
                            label: "Language",
                            trailing: Text(currentLanguage, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            onTap: () => _showLanguagePicker(currentLanguage),
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
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle("More"),
                  const SizedBox(height: 12),
                  _buildSettingsCard(context, [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      label: "Help Center",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                    ),
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      label: "About WorkSync",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                  ]),
                   const SizedBox(height: 40),
                   _buildLogoutButton(context),
                   const SizedBox(height: 120),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: _showCoverPickerOptions,
          tooltip: "Change Background",
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: uid.isEmpty ? Container(color: const Color(0xFF1A73E8)) : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            String name = "WorkSync User";
            String? photoData;
            String? coverData;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['name'] ?? "WorkSync User";
              photoData = data['photoUrl'];
              coverData = data['coverUrl'];
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

            Widget coverBackground;
            if (coverData != null && coverData.startsWith("data:image")) {
              try {
                final String base64String = coverData.split(",")[1];
                coverBackground = Image.memory(
                  base64Decode(base64String),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              } catch (e) {
                coverBackground = Container(color: const Color(0xFF1A73E8));
              }
            } else if (coverData != null && coverData.startsWith("color:#")) {
              try {
                final String hexCode = coverData.substring(7);
                final int colorValue = int.parse(hexCode, radix: 16);
                coverBackground = Container(color: Color(colorValue | 0xFF000000));
              } catch (e) {
                coverBackground = Container(color: const Color(0xFF1A73E8));
              }
            } else {
              coverBackground = Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            }

            return Stack(
              children: [
                Positioned.fill(child: coverBackground),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                if (_isUploadingCover)
                   const Positioned.fill(
                     child: Center(
                       child: CircularProgressIndicator(color: Colors.white),
                     ),
                   ),
                Center(
                  child: Column(
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final db = Provider.of<DatabaseService?>(context);

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
          StreamBuilder<List<Project>>(
            stream: db?.projects,
            builder: (ctx, snap) => _buildStatItem("Projects", snap.hasData ? snap.data!.length.toString() : "0", Icons.folder_open_rounded, const Color(0xFF1A73E8)),
          ),
          _buildDivider(),
          StreamBuilder<List<Task>>(
            stream: db?.tasks,
            builder: (ctx, snap) => _buildStatItem("Tasks", snap.hasData ? snap.data!.length.toString() : "0", Icons.check_circle_outline_rounded, const Color(0xFF0F9D58)),
          ),
          _buildDivider(),
          StreamBuilder<List<Client>>(
            stream: db?.clients,
            builder: (ctx, snap) => _buildStatItem("Clients", snap.hasData ? snap.data!.length.toString() : "0", Icons.people_outline_rounded, const Color(0xFF7B2FF7)),
          ),
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const TranslatedText("Logout"),
              content: const TranslatedText("Are you sure you want to log out?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const TranslatedText("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Close dialog
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('biometric_enabled', false);
                    await prefs.setBool('face_unlock_enabled', false);
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB4437),
                    foregroundColor: Colors.white,
                  ),
                  child: const TranslatedText("Logout"),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const TranslatedText("Logout",
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
