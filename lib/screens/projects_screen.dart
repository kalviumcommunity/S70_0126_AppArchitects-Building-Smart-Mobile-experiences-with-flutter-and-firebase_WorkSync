import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/project.dart';
import '../models/app_notification.dart';
import '../widgets/translated_text.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService?>(context);

    if (db == null) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                if (project.userId == db.uid)
                  TextButton.icon(
                    onPressed: () => _showInviteDialog(context, db, project),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const TranslatedText("Invite", style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
            if (project.collaborators.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  TranslatedText("${project.collaborators.length} collaborator${project.collaborators.length > 1 ? 's' : ''}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, DatabaseService db, Project project) {
    final emailCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const TranslatedText("Invite Collaborator"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TranslatedText("Enter their email to work together on this project.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  labelStyle: const TextStyle(color: Color(0xFF1A73E8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: Colors.grey.withAlpha(10),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const TranslatedText("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (emailCtrl.text.isEmpty) return;
                
                setState(() => isLoading = true);
                
                try {
                  final userDoc = await db.getUserByEmail(emailCtrl.text);
                  if (userDoc == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: TranslatedText("User not found"), backgroundColor: Colors.red),
                      );
                    }
                    setState(() => isLoading = false);
                    return;
                  }
                  
                  if (userDoc.id == db.uid) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: TranslatedText("You cannot invite yourself")),
                      );
                    }
                    setState(() => isLoading = false);
                    return;
                  }

                  final collaborators = List<String>.from(project.collaborators);
                  if (collaborators.contains(userDoc.id)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: TranslatedText("User already a collaborator")),
                      );
                    }
                    Navigator.pop(ctx);
                    return;
                  }

                  final invite = AppNotification(
                    id: '',
                    recipientId: userDoc.id,
                    senderId: db.uid,
                    senderName: FirebaseAuth.instance.currentUser?.displayName ?? "Someone",
                    type: 'invite',
                    title: 'Project Invitation',
                    body: 'invites you to collaborate on project "${project.name}"',
                    status: 'pending',
                    projectId: project.id,
                    createdAt: DateTime.now(),
                  );

                  await db.sendNotification(invite);
                  
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: TranslatedText("Invitation sent successfully!"),
                        backgroundColor: Color(0xFF0F9D58),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: TranslatedText("Something went wrong"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58), // Green for positive action
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const TranslatedText("Send Invite", style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const TranslatedText("Delete Project?"),
        content: TranslatedText("Are you sure you want to delete \"${project.name}\"? This action cannot be undone."),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const TranslatedText("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              db.deleteProject(project.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: TranslatedText("Project deleted"), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB4437), // Red for delete
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const TranslatedText("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
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
