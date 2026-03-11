import 'dart:ui';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/language_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const DashboardScreen(),
    const TasksScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBody: true, // Needed for blur effect on bottom app bar to show underlying content
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: lang.translate('Dashboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.check_circle_outline),
                selectedIcon: const Icon(Icons.check_circle),
                label: lang.translate('Tasks'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: lang.translate('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
