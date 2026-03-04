import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../models/project.dart';
import '../models/client.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
        title: Text("Reports", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.tasks,
        builder: (context, taskSnap) {
          return StreamBuilder<List<Payment>>(
            stream: db.payments,
            builder: (context, paySnap) {
              return StreamBuilder<List<Project>>(
                stream: db.projects,
                builder: (context, projSnap) {
                  return StreamBuilder<List<Client>>(
                    stream: db.clients,
                    builder: (context, clientSnap) {
                      final tasks = taskSnap.data ?? [];
                      final payments = paySnap.data ?? [];
                      final projects = projSnap.data ?? [];
                      final clients = clientSnap.data ?? [];
                      return _buildReportBody(context, tasks, payments, projects, clients);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportBody(
    BuildContext context,
    List<Task> tasks,
    List<Payment> payments,
    List<Project> projects,
    List<Client> clients,
  ) {
    // Task stats
    final completedTasks = tasks.where((t) => t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'done').length;
    final pendingTasks = tasks.length - completedTasks;
    final taskCompletion = tasks.isEmpty ? 0.0 : completedTasks / tasks.length;

    // Payment stats
    final totalRevenue = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final pendingRevenue = payments.where((p) => p.status == 'pending').fold<double>(0, (sum, p) => sum + p.amount);
    final collectedRevenue = totalRevenue - pendingRevenue;

    // Project stats
    final activeProjects = projects.where((p) => p.status.toLowerCase() == 'active').length;
    final completedProjects = projects.where((p) => p.status.toLowerCase() == 'completed').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Overview cards
        _buildSectionHeader(context, "Overview"),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(context, "Total Tasks", tasks.length.toString(), Icons.task_alt_rounded, const Color(0xFF1A73E8)),
            _buildStatCard(context, "Clients", clients.length.toString(), Icons.people_alt_rounded, const Color(0xFF0F9D58)),
            _buildStatCard(context, "Projects", projects.length.toString(), Icons.folder_special_rounded, const Color(0xFFDB4437)),
            _buildStatCard(context, "Revenue", "\$${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet_rounded, const Color(0xFF7B2FF7)),
          ],
        ),

        const SizedBox(height: 28),

        // Task Completion
        _buildSectionHeader(context, "Task Performance"),
        const SizedBox(height: 12),
        _buildProgressCard(
          context,
          title: "Task Completion Rate",
          subtitle: "$completedTasks completed out of ${tasks.length}",
          progress: taskCompletion,
          color: const Color(0xFF1A73E8),
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildMiniBar(context, "Completed", completedTasks, tasks.length, const Color(0xFF0F9D58))),
            const SizedBox(width: 14),
            Expanded(child: _buildMiniBar(context, "Pending", pendingTasks, tasks.length, const Color(0xFFF4B400))),
          ],
        ),

        const SizedBox(height: 28),

        // Revenue breakdown
        _buildSectionHeader(context, "Financial Summary"),
        const SizedBox(height: 12),
        _buildRevenueCard(context, totalRevenue, collectedRevenue, pendingRevenue),

        const SizedBox(height: 28),

        // Projects breakdown
        _buildSectionHeader(context, "Project Status"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildProjectStatusCard(context, "Active", activeProjects, const Color(0xFF1A73E8), Icons.play_circle_fill_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _buildProjectStatusCard(context, "Completed", completedProjects, const Color(0xFF0F9D58), Icons.check_circle_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _buildProjectStatusCard(context, "On Hold", projects.length - activeProjects - completedProjects, Colors.orange, Icons.pause_circle_filled_rounded)),
          ],
        ),

        const SizedBox(height: 28),

        // Priority breakdown
        _buildSectionHeader(context, "Task Priority Breakdown"),
        const SizedBox(height: 12),
        _buildPriorityBreakdown(context, tasks),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, {required String title, required String subtitle, required double progress, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(BuildContext context, String label, int value, int total, Color color) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, double total, double collected, double pending) {
    final collectedRatio = total == 0 ? 0.0 : collected / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7B2FF7), Color(0xFFB76CF9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF7B2FF7).withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: collectedRatio,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _revenueChip("Collected", "\$${collected.toStringAsFixed(0)}", Colors.greenAccent)),
              const SizedBox(width: 12),
              Expanded(child: _revenueChip("Pending", "\$${pending.toStringAsFixed(0)}", Colors.orangeAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProjectStatusCard(BuildContext context, String status, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(count.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(status, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown(BuildContext context, List<Task> tasks) {
    final high = tasks.where((t) => t.priority == 'High').length;
    final medium = tasks.where((t) => t.priority == 'Medium').length;
    final low = tasks.length - high - medium;
    final total = tasks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _priorityRow(context, "High Priority", high, total, const Color(0xFFDB4437)),
          const SizedBox(height: 14),
          _priorityRow(context, "Medium Priority", medium, total, const Color(0xFFF4B400)),
          const SizedBox(height: 14),
          _priorityRow(context, "Low Priority", low, total, const Color(0xFF1A73E8)),
        ],
      ),
    );
  }

  Widget _priorityRow(BuildContext context, String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
