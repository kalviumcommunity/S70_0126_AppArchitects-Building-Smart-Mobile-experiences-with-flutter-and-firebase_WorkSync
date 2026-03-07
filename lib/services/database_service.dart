import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../models/payment.dart';
import '../models/team_member.dart';

// Firestore access layer: root collections (clients, tasks, payments, projects)
class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final _db = FirebaseFirestore.instance;

  // Clients
  Stream<List<Client>> get clients {
    return _db
        .collection('clients')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((d) => Client.fromMap(d.data(), d.id))
          .toList();
    });
  }

  Future<void> addClient(Client c) {
    return _db.collection('clients').add(c.toMap());
  }

  Future<void> updateClient(Client c) {
    return _db.collection('clients').doc(c.id).update(c.toMap());
  }

  Future<void> deleteClient(String id) {
    return _db.collection('clients').doc(id).delete();
  }

  // Tasks
  Stream<List<Task>> get tasks {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((d) => Task.fromMap(d.data(), d.id))
          .toList();
    });
  }

  Future<void> addTask(Task t) {
    return _db.collection('tasks').add(t.toMap());
  }

  Future<void> updateTask(Task t) {
    return _db.collection('tasks').doc(t.id).update(t.toMap());
  }

  Future<void> deleteTask(String id) {
    return _db.collection('tasks').doc(id).delete();
  }

  // Projects
  Stream<List<Project>> get projects {
    return _db
        .collection('projects')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Project.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addProject(Project p) {
    return _db.collection('projects').add(p.toMap());
  }

  Future<void> updateProject(Project p) {
    return _db.collection('projects').doc(p.id).update(p.toMap());
  }

  Future<void> deleteProject(String id) {
    return _db.collection('projects').doc(id).delete();
  }

  // Payments
  Stream<List<Payment>> get payments {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Payment.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addPayment(Payment p) {
    return _db.collection('payments').add(p.toMap());
  }

  Future<void> updatePayment(Payment p) {
    return _db.collection('payments').doc(p.id).update(p.toMap());
  }

  Future<void> deletePayment(String id) {
    return _db.collection('payments').doc(id).delete();
  }

  // Team Members
  Stream<List<TeamMember>> get teamMembers {
    return _db
        .collection('team_members')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((d) => TeamMember.fromMap(d.data(), d.id))
          .toList();
    });
  }

  Future<void> addTeamMember(TeamMember m) {
    return _db.collection('team_members').add(m.toMap());
  }

  Future<void> updateTeamMember(TeamMember m) {
    return _db.collection('team_members').doc(m.id).update(m.toMap());
  }

  Future<void> deleteTeamMember(String id) {
    return _db.collection('team_members').doc(id).delete();
  }

  // User Profile
  Future<void> updateUserPhoto(String base64Image) {
    return _db.collection('users').doc(uid).set({
      'photoUrl': base64Image,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserCover(String coverData) {
    return _db.collection('users').doc(uid).set({
      'coverUrl': coverData,
    }, SetOptions(merge: true));
  }
}
