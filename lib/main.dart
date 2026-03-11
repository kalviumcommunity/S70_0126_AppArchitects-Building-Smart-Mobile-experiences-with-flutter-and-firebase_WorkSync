import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/theme_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import 'services/language_provider.dart';
import 'utils/app_security.dart';
import 'widgets/translated_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications
  await NotificationService().init();

  // Force Sign Out on Startup
  await FirebaseAuth.instance.signOut();

  runApp(const WorkSyncApp());
}

class WorkSyncApp extends StatelessWidget {
  const WorkSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        // Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),

        // Language Provider
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),

        // Firebase Auth State
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),

        // Database Service Provider
        ProxyProvider<User?, DatabaseService?>(
          update: (_, user, __) {
            if (user == null) return null;
            return DatabaseService(uid: user.uid);
          },
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'WorkSync',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1A73E8),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F3F8),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A73E8),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),

        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isChecking = true;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check if we are coming from the background (paused state)
    bool comingFromPaused = _lastLifecycleState == AppLifecycleState.paused;
    _lastLifecycleState = state;
    
    if (state == AppLifecycleState.resumed) {
      if (AppSecurity.pauseLifecycleLock) {
        return;
      }
      if (AppSecurity.isAuthenticating) {
        return;
      }
      
      if (!comingFromPaused) {
        // App was only 'inactive' (e.g. pulled down control center, or a Face ID overlap).
        // It didn't actually go into the background, so we don't lock it.
        return;
      }

      if (_isAuthenticated) {
        // App actually opened from background, trigger biometric lock if enabled
        _verifyBiometricOnResume();
      }
    }
  }

  Future<void> _verifyBiometricOnResume() async {
    if (AppSecurity.isAuthenticating) return;
    if (AppSecurity.lastAuthenticateTime != null && 
        DateTime.now().difference(AppSecurity.lastAuthenticateTime!).inSeconds < 2) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isBiometricEnabled = prefs.getBool('${user.uid}_biometric_enabled') ?? false;
    bool isFaceUnlockEnabled = prefs.getBool('${user.uid}_face_unlock_enabled') ?? false;
    
    if (isBiometricEnabled || isFaceUnlockEnabled) {
      setState(() {
        _isAuthenticated = false;
        _isChecking = true;
      });
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }

    if (AppSecurity.isAuthenticating) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isBiometricEnabled = prefs.getBool('${user.uid}_biometric_enabled') ?? false;
    bool isFaceUnlockEnabled = prefs.getBool('${user.uid}_face_unlock_enabled') ?? false;

    if (isBiometricEnabled || isFaceUnlockEnabled) {
      final LocalAuthentication auth = LocalAuthentication();
      try {
        AppSecurity.isAuthenticating = true;
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to access WorkSync',
          biometricOnly: false,
        );
        
        AppSecurity.lastAuthenticateTime = DateTime.now();
        Future.delayed(const Duration(seconds: 1), () {
          AppSecurity.isAuthenticating = false;
        });
        
        if (didAuthenticate) {
          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _isChecking = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isChecking = false;
            });
          }
        }
      } catch (e) {
        AppSecurity.lastAuthenticateTime = DateTime.now();
        Future.delayed(const Duration(seconds: 1), () {
          AppSecurity.isAuthenticating = false;
        });
        if (mounted) {
          setState(() {
            _isChecking = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isAuthenticated) {
      return const MainNavigation();
    }
    
    // Fallback Password UI
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const TranslatedText("App Locked"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 80, color: Color(0xFF1A73E8)),
              const SizedBox(height: 24),
              const TranslatedText("Authentication Required",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TranslatedText("Biometric authentication was cancelled or failed. Please enter your password to unlock WorkSync.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _verifyPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isVerifyingPassword
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const TranslatedText("Unlock WorkSync", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _checkAuth,
                child: const TranslatedText("Try Biometrics Again", style: TextStyle(color: Color(0xFF1A73E8))),
              )
            ],
          ),
        ),
      ),
    );
  }

  final TextEditingController _passwordController = TextEditingController();
  bool _isVerifyingPassword = false;

  Future<void> _verifyPassword() async {
    if (_passwordController.text.trim().isEmpty) return;
    
    setState(() => _isVerifyingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isVerifyingPassword = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText("Incorrect password. Please try again."),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }
}