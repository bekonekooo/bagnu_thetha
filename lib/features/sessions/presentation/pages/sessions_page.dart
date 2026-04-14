import 'package:flutter/material.dart';
import '../../data/services/session_service.dart';
import '../../data/models/session_model.dart';

class SessionsPage extends StatelessWidget {
  SessionsPage({super.key});

  final sessionService = SessionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seanslarım'),
      ),
      body: FutureBuilder<List<SessionModel>>(
        future: sessionService.fetchMySessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const Center(
              child: Text('Henüz bir seansınız yok'),
            );
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(session.teacherName),
                  subtitle: Text(
                    '${session.sessionDate} - ${session.sessionTime}\nDurum: ${session.status}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}