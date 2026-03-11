import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/translated_text.dart';

class HomeTab extends StatelessWidget {
  final List<Task> tasks;

  const HomeTab({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('My Tasks'),
      ),
      body: tasks.isEmpty
          ? const Center(child: TranslatedText('No tasks found. Add one!'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(task.description),
                    trailing: Chip(
                      label: Text(task.status),
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
