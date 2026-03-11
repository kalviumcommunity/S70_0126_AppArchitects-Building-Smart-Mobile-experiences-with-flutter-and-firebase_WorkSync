import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/client.dart';
import '../widgets/translated_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

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
        title: TranslatedText("My Clients",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Client>>(
        stream: db.clients,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context, db);
          }
          final clients = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: clients.length,
            itemBuilder: (_, i) {
              final c = clients[i];
              return _buildClientCard(context, db, c);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientDialog(context, db, null),
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const TranslatedText("New Client", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, DatabaseService db, Client c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
          child: Text(
            c.name.isNotEmpty ? c.name[0].toUpperCase() : "?",
            style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          c.name,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          (c.email ?? '').isEmpty ? (c.notes ?? 'No details provided') : c.email!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()), 
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
          onPressed: () => _confirmDelete(context, db, c),
        ),
        onTap: () => _showClientDialog(context, db, c),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DatabaseService db) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          TranslatedText("No clients yet",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showClientDialog(context, db, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const TranslatedText("Add Your First Client"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService db, Client c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const TranslatedText("Delete Client?"),
        content: TranslatedText("Are you sure you want to delete ${c.name}? This will remove all their associated data."),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const TranslatedText("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              db.deleteClient(c.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: TranslatedText("Client ${c.name} deleted"), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB4437),
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

  void _showClientDialog(BuildContext context, DatabaseService db, Client? client) {
    final nameCtrl = TextEditingController(text: client?.name ?? '');
    final emailCtrl = TextEditingController(text: client?.email ?? '');
    final notesCtrl = TextEditingController(text: client?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(client == null ? 'Add Client' : 'Edit Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                controller: nameCtrl,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                controller: emailCtrl,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note_add_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                controller: notesCtrl,
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
              final c = Client(
                id: client?.id ?? '',
                userId: db.uid,
                name: nameCtrl.text,
                email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
                notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
              );
              if (client == null) {
                if (c.email != null && c.email!.isNotEmpty) {
                  final targetUser = await db.getUserByEmail(c.email!);
                  if (targetUser != null && targetUser.id != db.uid) {
                    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(db.uid).get();
                    final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';
                    
                    final notif = AppNotification(
                      id: '',
                      recipientId: targetUser.id,
                      senderId: db.uid,
                      senderName: currentUserName,
                      type: 'client_invite',
                      title: 'Client Invitation',
                      body: 'invited you to be their client.',
                      status: 'pending',
                      createdAt: DateTime.now(),
                    );
                    await db.sendNotification(notif);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: TranslatedText('Client invitation sent to ${targetUser['name'] ?? c.name}!'), backgroundColor: const Color(0xFF0F9D58)),
                      );
                      Navigator.pop(ctx);
                    }
                    return;
                  }
                }
                
                db.addClient(c);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: TranslatedText("Client added successfully!"), backgroundColor: Color(0xFF0F9D58)),
                  );
                }
              } else {
                db.updateClient(c);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: TranslatedText("Client updated successfully!"), backgroundColor: Color(0xFF0F9D58)),
                  );
                }
              }
              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: Text(client == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}
