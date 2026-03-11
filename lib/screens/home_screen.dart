import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'clients_screen.dart';
import 'tasks_screen.dart';
import '../widgets/translated_text.dart';

// Home with bottom navigation: Dashboard, Clients, Tasks
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  static final _pages = <Widget>[
    const DashboardScreen(),
    const ClientsScreen(),
    const TasksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('WorkSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clients'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), label: 'Tasks'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
