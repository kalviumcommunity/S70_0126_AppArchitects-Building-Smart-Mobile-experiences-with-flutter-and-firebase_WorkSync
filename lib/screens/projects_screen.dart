import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/project.dart';
import '../widgets/translated_text.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService?>(context);

    if (db == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText("Projects",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Project>>(
        stream: db.projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context, db!);
          }

          final projects = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return _buildProjectCard(context, db!, projects[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProjectDialog(context, db!, null),
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const TranslatedText("New Project", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, DatabaseService db, Project project) {
    Color statusColor;
    switch (project.status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF0F9D58);
        break;
      case 'on hold':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = const Color(0xFF1A73E8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withAlpha((0.2 * 255).round())
                : Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showProjectDialog(context, db, project),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        project.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                      onPressed: () => _confirmDelete(context, db, project),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description ?? "No description",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()), 
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round())),
                const SizedBox(width: 6),
                TranslatedText("Created: ${DateFormat('MMM dd, yyyy').format(project.createdAt)}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()), 
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DatabaseService db) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          TranslatedText("No projects found",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showProjectDialog(context, db, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const TranslatedText("Create Your First Project"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService db, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText("Delete Project?"),
        content: TranslatedText("Are you sure you want to delete \"${project.name}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const TranslatedText("Cancel")),
          TextButton(
            onPressed: () {
              db.deleteProject(project.id);
              Navigator.pop(ctx);
            },
            child: const TranslatedText("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProjectDialog(BuildContext context, DatabaseService db, Project? project) {
    final nameCtrl = TextEditingController(text: project?.name ?? '');
    final descCtrl = TextEditingController(text: project?.description ?? '');
    String status = project?.status ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(project == null ? 'Add Project' : 'Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  controller: nameCtrl,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                  controller: descCtrl,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['active', 'completed', 'on hold'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => status = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const TranslatedText('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final p = Project(
                  id: project?.id ?? '',
                  userId: db.uid,
                  name: nameCtrl.text,
                  description: descCtrl.text.isEmpty ? null : descCtrl.text,
                  status: status,
                  createdAt: project?.createdAt ?? DateTime.now(),
                );
                if (project == null) {
                  await db.addProject(p);
                } else {
                  await db.updateProject(p);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: Text(project == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
