import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import 'task_screen.dart';
import 'tasks_screen.dart';
import 'clients_screen.dart';
import 'payments_screen.dart';
import 'projects_screen.dart';
import 'schedule_screen.dart';
import 'team_screen.dart';
import 'reports_screen.dart';
import '../services/notification_service.dart';
import 'messages_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login again")),
      );
    }

    final String uid = currentUser.uid;
    final String userEmail = currentUser.email!.trim();

    final int hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: userEmail)
              .get(),
          builder: (context, userSnap) {
            String userName = "User";
            if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
              final data =
                  userSnap.data!.docs.first.data() as Map<String, dynamic>;
              userName = data['name'] ?? "User";
            }

            final String firstName = userName.split(' ').first;

            return RefreshIndicator(
              color: const Color(0xFF1A73E8),
              onRefresh: () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── DEADLINE NOTIFIER (hidden, fires push) ────────────
                    _DeadlineNotifier(uid: uid),

                    // ── HEADER ──────────────────────────────────────────────
                    _buildHeader(context, greeting, firstName, userName, uid),

                    const SizedBox(height: 24),

                    // ── TASK STATS ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSectionTitle(context, "Overview"),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTaskStats(context, uid),
                    ),

                    const SizedBox(height: 28),

                    // ── DEADLINES TODAY ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildDeadlinesToday(context, uid),
                    ),

                    const SizedBox(height: 28),

                    // ── CATEGORIES GRID ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSectionTitle(context, "Categories"),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildCategoriesGrid(context, uid),
                    ),

                    const SizedBox(height: 28),

                    // ── QUICK ACTIONS ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSectionTitle(context, "Quick Actions"),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActions(context),
                    ),

                    const SizedBox(height: 28),

                    // ── RECENT TASKS ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildRecentTasks(context, uid),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String greeting, String firstName,
      String fullName, String uid) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$greeting,",
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : "U",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Date + payment summary strip
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('hh:mm a • dd/MM/yyyy').format(DateTime.now()),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Pending payments badge
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .where('userId', isEqualTo: uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snap) {
                  final int pendingCount =
                      snap.hasData ? snap.data!.docs.length : 0;
                  if (pendingCount == 0) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          "$pendingCount pending payment${pendingCount > 1 ? 's' : ''}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION TITLE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TASK STATS — 4 cards row
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTaskStats(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        int total = 0, completed = 0, pending = 0, inProgress = 0;
        if (snap.hasData) {
          final docs = snap.data!.docs;
          total = docs.length;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            if (status == 'completed' || status == 'done') {
              completed++;
            } else if (status == 'in progress') {
              inProgress++;
            } else {
              pending++;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _miniStatCard(context, "Total", total.toString(),
                  Icons.assignment_outlined, const Color(0xFF1A73E8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStatCard(context, "Done", completed.toString(),
                  Icons.check_circle_outline, const Color(0xFF0F9D58)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStatCard(context, "Pending", pending.toString(),
                  Icons.hourglass_empty, const Color(0xFFF4B400)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStatCard(context, "Active", inProgress.toString(),
                  Icons.autorenew, const Color(0xFFDB4437)),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DEADLINES TODAY
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDeadlinesToday(BuildContext context, String uid) {
    final db = Provider.of<DatabaseService?>(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Deadlines Today"),
        const SizedBox(height: 12),
        StreamBuilder<List<Task>>(
          stream: db?.tasks ?? const Stream.empty(),
          builder: (context, snap) {
            if (snap.hasError) {
              debugPrint("Deadlines Error: ${snap.error}");
              return Text("Error: ${snap.error}");
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 50, child: Center(child: LinearProgressIndicator()));
            }
            
            final todayTasks = (snap.data ?? []).where((t) {
              return t.dueDate.year == now.year && 
                     t.dueDate.month == now.month && 
                     t.dueDate.day == now.day;
            }).toList();

            if (todayTasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color?.withOpacity(0.5) ?? 
                         Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sentiment_satisfied_alt_rounded, color: Color(0xFF0F9D58), size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Relax!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "No deadlines for you today.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: todayTasks.length,
                clipBehavior: Clip.none,
                itemBuilder: (context, index) {
                  final task = todayTasks[index];
                  return _deadlineCard(context, {
                    'title': task.title,
                    'priority': task.priority,
                    'status': task.status,
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _deadlineCard(BuildContext context, Map<String, dynamic> data) {
    final String title = data['title'] ?? "Untitled";
    final String priority = data['priority'] ?? "Low";
    final String status = data['status'] ?? "Pending";
    final bool isDone = status.toLowerCase() == 'completed' || status.toLowerCase() == 'done';

    Color priorityColor;
    switch (priority) {
      case 'High': priorityColor = const Color(0xFFDB4437); break;
      case 'Medium': priorityColor = const Color(0xFFF4B400); break;
      default: priorityColor = const Color(0xFF1A73E8);
    }

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: isDone ? Colors.green : priorityColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDone ? Colors.green : priorityColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDone ? "DONE" : priority.toUpperCase(),
                  style: TextStyle(
                    color: isDone ? Colors.green : priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey.withAlpha(100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.08 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CATEGORIES GRID
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoriesGrid(BuildContext context, String uid) {
    final categories = [
      _CategoryItem(
        label: "Payments",
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF7B2FF7),
        bgColor: const Color(0xFFF3E8FF),
        badge: _PaymentBadge(uid: uid),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentsScreen()),
        ),
      ),
      _CategoryItem(
        label: "Clients",
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0F9D58),
        bgColor: const Color(0xFFE6F4EA),
        badge: _ClientBadge(uid: uid),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientsScreen()),
        ),
      ),
      _CategoryItem(
        label: "Projects",
        icon: Icons.folder_special_rounded,
        color: const Color(0xFF1A73E8),
        bgColor: const Color(0xFFE8F0FE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectsScreen()),
        ),
      ),
      _CategoryItem(
        label: "Schedule",
        icon: Icons.event_note_rounded,
        color: const Color(0xFF00ACC1),
        bgColor: const Color(0xFFE0F7FA),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        ),
      ),
      _CategoryItem(
        label: "Team",
        icon: Icons.groups_rounded,
        color: const Color(0xFFF4B400),
        bgColor: const Color(0xFFFFFDE7),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeamScreen()),
        ),
      ),
      _CategoryItem(
        label: "Reports",
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFFDB4437),
        bgColor: const Color(0xFFFCE8E6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        ),
      ),
      _CategoryItem(
        label: "Invoices",
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF00897B),
        bgColor: const Color(0xFFE0F2F1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentsScreen()),
        ),
      ),
      _CategoryItem(
        label: "Messages",
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFFE91E8C),
        bgColor: const Color(0xFFFCE4EC),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessagesScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return GestureDetector(
          onTap: cat.onTap,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? cat.color.withAlpha((0.15 * 255).round())
                          : cat.bgColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: cat.color.withAlpha((0.15 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 26),
                  ),
                  if (cat.badge != null)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: cat.badge!,
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                cat.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha((0.8 * 255).round()),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature — coming soon!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A73E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickBtn(
            context: context,
            icon: Icons.add_task_rounded,
            label: "New Task",
            color: const Color(0xFF1A73E8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickBtn(
            context: context,
            icon: Icons.list_alt_rounded,
            label: "All Tasks",
            color: const Color(0xFF0F9D58),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TasksScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickBtn(
            context: context,
            icon: Icons.receipt_long_rounded,
            label: "Invoice",
            color: const Color(0xFF7B2FF7),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickBtn(
            context: context,
            icon: Icons.person_add_alt_1_rounded,
            label: "Add Client",
            color: const Color(0xFF00ACC1),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RECENT TASKS — live stream, last 5
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentTasks(BuildContext context, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, "Recent Tasks"),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TasksScreen()));
              },
              child: const Text(
                "See all →",
                style: TextStyle(
                  color: Color(0xFF1A73E8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return _emptyTasks(context);
            }
            return Column(
              children: snap.data!.docs.map((doc) {
                return _recentTaskCard(context,
                    doc.data() as Map<String, dynamic>);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyTasks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "No tasks yet",
            style: TextStyle(
                color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap \"New Task\" to get started",
            style:
                TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _recentTaskCard(BuildContext context, Map<String, dynamic> data) {
    final String title = data['title'] ?? "Untitled";
    final String description = data['description'] ?? "";
    final String priority = data['priority'] ?? "Low";
    final String status = data['status'] ?? "Pending";

    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = const Color(0xFFDB4437);
        break;
      case 'Medium':
        priorityColor = const Color(0xFFF4B400);
        break;
      default:
        priorityColor = const Color(0xFF1A73E8);
    }

    final bool isDone =
        status.toLowerCase() == 'completed' || status.toLowerCase() == 'done';

    String dueText = "";
    if (data['dueDate'] != null) {
      try {
        final DateTime due = (data['dueDate'] as dynamic).toDate();
        dueText = DateFormat('MMM d').format(due);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withAlpha((0.2 * 255).round())
                : Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFFE6F4EA)
                  : priorityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color:
                  isDone ? const Color(0xFF0F9D58) : priorityColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (dueText.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      dueText,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper models
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Widget? badge;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.badge,
  });
}

class _PaymentBadge extends StatelessWidget {
  final String uid;
  const _PaymentBadge({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final int count = snap.hasData ? snap.data!.docs.length : 0;
        if (count == 0) return const SizedBox();
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count > 9 ? "9+" : count.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _ClientBadge extends StatelessWidget {
  final String uid;
  const _ClientBadge({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clients')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final int count = snap.hasData ? snap.data!.docs.length : 0;
        if (count == 0) return const SizedBox();
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A), // Dark neutral color for count
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count > 9 ? "9+" : count.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DeadlineNotifier — invisible widget that fires a push notification once
// per app session when the user has tasks due today.
// ─────────────────────────────────────────────────────────────────────────────
class _DeadlineNotifier extends StatefulWidget {
  final String uid;
  const _DeadlineNotifier({required this.uid});

  @override
  State<_DeadlineNotifier> createState() => _DeadlineNotifierState();
}

class _DeadlineNotifierState extends State<_DeadlineNotifier> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService?>(context);
    if (db == null) return const SizedBox.shrink();

    return StreamBuilder<List<Task>>(
      stream: db.tasks,
      builder: (context, snap) {
        if (!_notified && snap.hasData) {
          final now = DateTime.now();
          final todayTitles = snap.data!
              .where((t) =>
                  t.dueDate.year == now.year &&
                  t.dueDate.month == now.month &&
                  t.dueDate.day == now.day &&
                  t.status.toLowerCase() != 'completed' &&
                  t.status.toLowerCase() != 'done')
              .map((t) => t.title)
              .toList();

          if (todayTitles.isNotEmpty) {
            _notified = true;
            // Fire after the frame so the widget tree is stable
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService().showDeadlinesToday(todayTitles);
            });
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}