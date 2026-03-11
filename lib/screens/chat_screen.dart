import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../widgets/translated_text.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _myName => _auth.currentUser?.email?.split('@').first ?? 'Me';

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();

    final msg = Message(
      senderId: _uid,
      senderName: _myName,
      receiverId: widget.otherUserId,
      conversationId: widget.conversationId,
      text: text,
      timestamp: DateTime.now(),
    );

    // Add message to sub-collection
    await _db
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add(msg.toMap());

    // Update conversation's last message
    await _db.collection('conversations').doc(widget.conversationId).update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(msg.timestamp),
      'lastSenderId': _uid,
    });

    _scrollToBottom();
  }

  Future<void> _markMessagesAsRead(List<Message> messages) async {
    // Find messages sent by the other user that are not yet marked as read
    final unreadDocs = messages.where((m) => m.senderId != _uid && !m.isRead).toList();
    if (unreadDocs.isEmpty) return;

    final batch = _db.batch();
    for (final msg in unreadDocs) {
      final ref = _db
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(msg.id);
      batch.update(ref, {'isRead': true});
    }

    // Also clear the conversation's unread indicator if we were the last receiver
    final convoRef = _db.collection('conversations').doc(widget.conversationId);
    batch.update(convoRef, {'lastSenderId': ''});

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?';
    final colors = [
      const Color(0xFF1A73E8), const Color(0xFF0F9D58), const Color(0xFFDB4437),
      const Color(0xFFF4B400), const Color(0xFF7B2FF7), const Color(0xFFE91E8C),
    ];
    final avatarColor = widget.otherUserName.isNotEmpty
        ? colors[widget.otherUserName.codeUnitAt(0) % colors.length]
        : colors[0];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColor.withOpacity(0.15),
              child: Text(initials, style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                  const TranslatedText("Online", style: TextStyle(color: Colors.green, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = (snap.data?.docs ?? [])
                    .map((d) => Message.fromMap(d.data() as Map<String, dynamic>, d.id))
                    .toList();

                _markMessagesAsRead(messages);
                _scrollToBottom();

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand_rounded, size: 50, color: Colors.amber.withAlpha(180)),
                        const SizedBox(height: 12),
                        TranslatedText("Say hi to ${widget.otherUserName}!", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _uid;
                    final showDate = index == 0 ||
                        !_isSameDay(messages[index - 1].timestamp, msg.timestamp);

                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(msg.timestamp),
                        _buildMessageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(dt, now)) {
      label = 'Today';
    } else if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, y').format(dt);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.withAlpha(40))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey.withAlpha(40))),
      ]),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE91E8C) : (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(msg.timestamp),
                  style: TextStyle(color: isMe ? Colors.white60 : Colors.grey, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 14,
                    color: msg.isRead ? Colors.blue.shade300 : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Type a message…",
                    hintStyle: TextStyle(color: Colors.grey.withAlpha(120)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
