import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _myDisplayName = '';

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadMyName();
  }

  Future<void> _loadMyName() async {
    if (_uid.isEmpty) return;
    final doc = await _db.collection('users').doc(_uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _myDisplayName = (doc.data()?['name'] as String?) ?? 
            (_auth.currentUser?.email?.split('@').first ?? 'Me');
      });
    }
  }

  String get _myName => _myDisplayName.isNotEmpty 
      ? _myDisplayName 
      : (_auth.currentUser?.email?.split('@').first ?? 'Me');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Messages", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showNewConversationDialog(),
            tooltip: "New Message",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('conversations')
            .where('participantIds', arrayContains: _uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _buildEmptyState();
          }
          final conversations = snap.data!.docs
              .map((d) => Conversation.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()
            ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 80, endIndent: 20, color: Colors.grey.withAlpha(30)),
            itemBuilder: (context, index) => _buildConversationTile(conversations[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewConversationDialog,
        backgroundColor: const Color(0xFFE91E8C),
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationTile(Conversation convo) {
    final otherId = convo.participantIds.firstWhere((id) => id != _uid, orElse: () => '');
    final timeStr = _formatTime(convo.lastMessageTime);
    final colors = [
      const Color(0xFF1A73E8), const Color(0xFF0F9D58), const Color(0xFFDB4437),
      const Color(0xFFF4B400), const Color(0xFF7B2FF7), const Color(0xFFE91E8C),
    ];

    // Always look up the real name from Firestore using the other user's UID
    return FutureBuilder<DocumentSnapshot>(
      future: _db.collection('users').doc(otherId).get(),
      builder: (context, userSnap) {
        String otherName = convo.participantNames[otherId] ?? 'Unknown';
        if (userSnap.hasData && userSnap.data!.exists) {
          final data = userSnap.data!.data() as Map<String, dynamic>;
          otherName = (data['name'] as String?) ?? otherName;
        }
        final initials = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
        final avatarColor = colors[otherName.codeUnitAt(0) % colors.length];

        // Show unread indicator if the last message was sent by the OTHER person
        final bool hasUnread = convo.lastSenderId.isNotEmpty &&
            convo.lastSenderId != _uid &&
            convo.lastMessage.isNotEmpty;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(initials, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              if (hasUnread)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E8C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            otherName,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            convo.lastMessage.isEmpty ? "Start a conversation" : convo.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread 
                  ? Theme.of(context).colorScheme.onSurface.withAlpha(200) 
                  : Colors.grey.shade500,
              fontSize: 13,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: hasUnread ? const Color(0xFFE91E8C) : Colors.grey,
                  fontSize: 11,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E8C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text("New", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: convo.id,
                otherUserId: otherId,
                otherUserName: otherName,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.withAlpha(50)),
          const SizedBox(height: 16),
          Text("No messages yet", style: TextStyle(color: Colors.grey.withAlpha(150), fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Start a conversation", style: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewConversationDialog,
            icon: const Icon(Icons.edit_outlined),
            label: const Text("New Message"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("New Message"),
        content: TextField(
          controller: emailCtrl,
          decoration: InputDecoration(
            labelText: "Recipient's email",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E8C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim().toLowerCase();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              await _startConversationWithEmail(email);
            },
            child: const Text("Start Chat"),
          ),
        ],
      ),
    );
  }

  Future<void> _startConversationWithEmail(String email) async {
    // Look up the user by email
    final userSnap = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();

    if (!mounted) return;

    if (userSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No user found with email: $email"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final otherUser = userSnap.docs.first;
    final otherId = otherUser.id;
    final otherData = otherUser.data();
    final otherName = otherData['name'] ?? email.split('@').first;

    if (otherId == _uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself!"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Check if a conversation already exists
    final existing = await _db.collection('conversations')
        .where('participantIds', arrayContains: _uid)
        .get();

    String? existingId;
    for (final doc in existing.docs) {
      final ids = List<String>.from(doc['participantIds'] ?? []);
      if (ids.contains(otherId)) {
        existingId = doc.id;
        break;
      }
    }

    if (existingId != null) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: existingId!, otherUserId: otherId, otherUserName: otherName),
      ));
      return;
    }

    // Create new conversation
    final convo = Conversation(
      participantIds: [_uid, otherId],
      participantNames: {_uid: _myName, otherId: otherName},
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );
    final ref = await _db.collection('conversations').add(convo.toMap());

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(conversationId: ref.id, otherUserId: otherId, otherUserName: otherName),
    ));
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('HH:mm').format(dt);
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEE').format(dt);
    }
    return DateFormat('dd/MM').format(dt);
  }
}
