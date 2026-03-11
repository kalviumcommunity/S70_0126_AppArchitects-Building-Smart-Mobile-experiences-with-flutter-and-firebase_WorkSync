import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';
import '../widgets/translated_text.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> signUpUser() async {

    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Basic Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText("Please fill all fields")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText("Password must be at least 6 characters")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      print("Starting signup process...");

      // Create user in Firebase Auth
      print("Calling FirebaseAuth.instance.createUserWithEmailAndPassword...");
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("FirebaseAuth success. UID: ${userCredential.user?.uid}");

      String uid = userCredential.user!.uid;

      // Store user data in Firestore using UID (Correct Structure)
      print("Calling FirebaseFirestore.instance.collection('users').doc(uid).set...");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        "name": name,
        "email": email,
        "createdAt": Timestamp.now(),
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Firestore connection timed out. Have you created the Firestore Database in your Firebase Console?");
      });
      print("Firestore set success.");

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText("Signup Successful. Please login."),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to Login
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException caught: ${e.code} - ${e.message}");
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup Failed")),
      );
    } on FirebaseException catch (e) {
      print("FirebaseException caught: ${e.code} - ${e.message}");
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText("Firebase Error: ${e.message}")),
      );
    } catch (e, stacktrace) {
      print("Generic Exception caught: $e");
      print("Stacktrace: $stacktrace");
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: TranslatedText("Error: ${e.toString()}")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                TranslatedText("Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 40),

                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUpUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const TranslatedText("Sign Up",
                      style: TextStyle(fontSize: 18),
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