import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import 'task_screen.dart';
import '../widgets/translated_text.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();

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
        title: TranslatedText("Schedule",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _buildTaskList(db),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final List<DateTime> dates = List.generate(14, (index) => now.add(Duration(days: index - 2)));

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year && 
                            date.month == _selectedDate.month && 
                            date.day == _selectedDate.day;
          final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1A73E8) 
                    : Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF1A73E8).withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white.withAlpha(200) : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF1A73E8),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList(DatabaseService db) {
    return StreamBuilder<List<Task>>(
      stream: db.tasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = (snapshot.data ?? []).where((task) {
          return task.dueDate.year == _selectedDate.year && 
                 task.dueDate.month == _selectedDate.month && 
                 task.dueDate.day == _selectedDate.day;
        }).toList();

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildTimelineItem(tasks[index], db);
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(Task task, DatabaseService db) {
    Color priorityColor;
    switch (task.priority) {
      case 'High': priorityColor = const Color(0xFFDB4437); break;
      case 'Medium': priorityColor = const Color(0xFFF4B400); break;
      default: priorityColor = const Color(0xFF1A73E8);
    }

    final bool isDone = task.status.toLowerCase() == 'completed' || task.status.toLowerCase() == 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                DateFormat('HH:mm').format(task.dueDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.withAlpha(40),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => TaskScreen(task: task))
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border(left: BorderSide(color: isDone ? Colors.green : priorityColor, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDone ? Colors.green : priorityColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDone ? "DONE" : task.priority.toUpperCase(),
                            style: TextStyle(
                              color: isDone ? Colors.green : priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 80, color: Colors.grey.withAlpha(50)),
          const SizedBox(height: 16),
          TranslatedText("Nothing scheduled",
            style: TextStyle(color: Colors.grey.withAlpha(150), fontSize: 18, fontWeight: FontWeight.w500),
          ),
          TranslatedText("Take some rest or add a task",
            style: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
