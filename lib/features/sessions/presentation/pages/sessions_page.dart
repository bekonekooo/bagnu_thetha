import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/sessions/data/mock_sessions.dart';
import '../widgets/session_card.dart';
import '../widgets/session_empty_state.dart';
import '../widgets/session_section_title.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  void goToTeachers(BuildContext context) {
    context.go('/teachers');
  }

  @override
  Widget build(BuildContext context) {
    final hasSessions = mockSessions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seanslarım'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SessionSectionTitle(
              title: 'Seanslarım',
              subtitle: 'Yaklaşan ve geçmiş seanslarını burada takip edebilirsin.',
            ),
            const SizedBox(height: 24),
            if (!hasSessions)
              SessionEmptyState(
                onFindTeacher: () => goToTeachers(context),
              )
            else
              ...mockSessions.map(
                (session) => SessionCard(
                  teacherName: session['teacherName'],
                  specialty: session['specialty'],
                  date: session['date'],
                  time: session['time'],
                  status: session['status'],
                ),
              ),
          ],
        ),
      ),
    );
  }
}