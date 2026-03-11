import 'package:flutter/material.dart';
import '../widgets/translated_text.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const TranslatedText("Help Center", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Placeholder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search for help...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            TranslatedText("Frequently Asked Questions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // FAQs
            _buildFAQTile(
              context,
              question: "How do I reset my password?",
              answer: "Navigate to Profile > Security > Reset Password. We will email you a secure link to create a new password.",
            ),
            _buildFAQTile(
              context,
              question: "How do I change the app language?",
              answer: "Go to your Profile and tap on 'Language'. You can choose from various Indian and International languages to translate the entire app instantly.",
            ),
            _buildFAQTile(
              context,
              question: "How does Biometric App Lock work?",
              answer: "When enabled inside the Security settings, WorkSync will require your device's Face ID, Touch ID, or PIN every time you launch the app. If biometrics fail, you can always enter your account password to unlock securely.",
            ),
            _buildFAQTile(
              context,
              question: "How do I create a new task?",
              answer: "From the Dashboard, simply tap the 'New Task' quick action button, or head over to the Tasks tab and tap the Floating Action Button (+) located at the bottom right.",
            ),
            _buildFAQTile(
              context,
              question: "Can I manage multiple projects?",
              answer: "Yes! WorkSync allows you to create infinite projects and assign specific tasks to them easily.",
            ),

            const SizedBox(height: 40),
            
            // Contact Support
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A73E8).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const TranslatedText("Still need help?",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const TranslatedText("Our support team is available 24/7.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: TranslatedText("Redirecting to Support Channel..."))
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const TranslatedText("Contact Support", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(BuildContext context, {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        iconColor: const Color(0xFF1A73E8),
        collapsedIconColor: Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          question, 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          )
        ],
      ),
    );
  }
}
