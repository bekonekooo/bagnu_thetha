import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/session_model.dart';
import '../../data/services/session_service.dart';

class TeacherSessionsPage extends StatefulWidget {
  const TeacherSessionsPage({super.key});

  @override
  State<TeacherSessionsPage> createState() => _TeacherSessionsPageState();
}

class _TeacherSessionsPageState extends State<TeacherSessionsPage>
    with SingleTickerProviderStateMixin {
  final SessionService sessionService = SessionService();

  late TabController tabController;
  late Future<List<SessionModel>> sessionsFuture;

  RealtimeChannel? realtimeChannel;
  String? teacherId;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    initTeacherSessions();
  }

  Future<void> initTeacherSessions() async {
    sessionsFuture = sessionService.fetchTeacherSessions();

    try {
      final id = await sessionService.fetchMyTeacherId();

      if (!mounted) return;

      teacherId = id;

      realtimeChannel = sessionService.subscribeToTeacherSessions(
        teacherId: id,
        onChange: () {
          if (!mounted) return;

          setState(() {
            sessionsFuture = sessionService.fetchTeacherSessions();
          });
        },
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      setState(() {});
    }
  }

  Future<void> refreshSessions() async {
    setState(() {
      sessionsFuture = sessionService.fetchTeacherSessions();
    });
  }

  List<SessionModel> filterSessions(
    List<SessionModel> sessions,
    String status,
  ) {
    return sessions.where((session) => session.status == status).toList();
  }

  Future<void> cancelSession(SessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seansı İptal Et'),
          content: const Text('Bu seansı iptal etmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('İptal Et'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await sessionService.cancelTeacherSession(session.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seans iptal edildi')),
      );

      refreshSessions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seans iptal edilemedi: $e')),
      );
    }
  }

  Widget buildSessionCard(SessionModel session) {
    final isUpcoming = session.status == 'upcoming';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${session.sessionDate} - ${session.sessionTime}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
Text(
  'Öğrenci: ${session.studentName ?? 'Bilinmiyor'}',
  style: const TextStyle(fontSize: 14),
),
            const SizedBox(height: 8),
            Text(
              'Durum: ${session.status}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isUpcoming ? Colors.green : Colors.grey,
              ),
            ),
            if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Öğrenci Notu:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(session.notes!),
            ],
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => cancelSession(session),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Seansı İptal Et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSessionList(List<SessionModel> sessions) {
    if (sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: refreshSessions,
        child: ListView(
          children: const [
            SizedBox(height: 220),
            Center(
              child: Text('Bu sekmede seans bulunmuyor.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          return buildSessionCard(sessions[index]);
        },
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();

    if (realtimeChannel != null) {
      sessionService.removeChannel(realtimeChannel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seanslarım'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Yaklaşan'),
            Tab(text: 'Tamamlanan'),
            Tab(text: 'İptal'),
          ],
        ),
      ),
      body: FutureBuilder<List<SessionModel>>(
        future: sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Seanslar yüklenemedi:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final sessions = snapshot.data ?? [];

          final upcomingSessions = filterSessions(sessions, 'upcoming');
          final completedSessions = filterSessions(sessions, 'completed');
          final cancelledSessions = filterSessions(sessions, 'cancelled');

          return TabBarView(
            controller: tabController,
            children: [
              buildSessionList(upcomingSessions),
              buildSessionList(completedSessions),
              buildSessionList(cancelledSessions),
            ],
          );
        },
      ),
    );
  }
}