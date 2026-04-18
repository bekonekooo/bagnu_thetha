import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/session_service.dart';
import '../../data/models/session_model.dart';
import '../../utils/session_utils.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final sessionService = SessionService();

  late Future<List<SessionModel>> sessionsFuture;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  void loadSessions() {
    sessionsFuture = loadSessionsData();
  }

  Future<List<SessionModel>> loadSessionsData() async {
    await sessionService.markPastSessionsAsCompleted();
    return sessionService.fetchMySessions();
  }

  Future<void> refreshSessions() async {
    setState(() {
      loadSessions();
    });
    await sessionsFuture;
  }

  Future<void> cancelSession(String sessionId) async {
    try {
      await sessionService.cancelSession(sessionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seans iptal edildi')),
      );

      setState(() {
        loadSessions();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İptal sırasında hata oluştu: $e')),
      );
    }
  }

  Future<void> showCancelDialog(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seansı iptal et'),
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

    if (confirmed == true) {
      await cancelSession(sessionId);
    }
  }

DateTime? safeParseDate(String date) {
  try {
    return DateTime.parse(date);
  } catch (_) {
    return null;
  }
}

String formatDate(String date) {
  final parsedDate = safeParseDate(date);
  if (parsedDate == null) return date;

  return DateFormat('d MMMM yyyy', 'tr_TR').format(parsedDate);
}

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime? combineDateAndTime(String date, String time) {
  final parsedDate = safeParseDate(date);
  if (parsedDate == null) return null;

  final cleanDate = normalizeDate(parsedDate);

  final parts = time.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);

  if (hour == null || minute == null) return null;

  return DateTime(
    cleanDate.year,
    cleanDate.month,
    cleanDate.day,
    hour,
    minute,
  );
}

bool isPastSession(SessionModel session) {
  final sessionDateTime = combineDateAndTime(
    session.sessionDate,
    session.sessionTime,
  );

  if (sessionDateTime == null) return false;

  return sessionDateTime.isBefore(DateTime.now());
}

String getRealStatus(SessionModel session) {
  if (session.status == 'cancelled') return 'cancelled';
  if (session.status == 'completed') return 'completed';

  if (isPastSession(session)) {
    return 'completed';
  }

  return 'upcoming';
}


  Color getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'Yaklaşan';
      case 'cancelled':
        return 'İptal Edildi';
      case 'completed':
        return 'Tamamlandı';
      default:
        return status;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'upcoming':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  List<SessionModel> filterSessionsByStatus(
    List<SessionModel> sessions,
    String status,
  ) {
 return sessions.where((session) {
  final realStatus = SessionUtils.resolveStatus(session);
  return realStatus == status;
}).toList();
  }

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.deepPurple.shade50,
              child: Icon(
                icon,
                size: 32,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            getStatusText(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSessionCard(SessionModel session) {
    final realStatus = getRealStatus(session);
    final isUpcoming = realStatus == 'upcoming';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: const Icon(
                    Icons.person,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.teacherName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      buildStatusBadge(realStatus),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tarih: ${formatDate(session.sessionDate)}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Saat: ${session.sessionTime}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  if (session.notes != null &&
                      session.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Not: ${session.notes}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showCancelDialog(session.id),
                  icon: const Icon(Icons.close),
                  label: const Text('Seansı İptal Et'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSessionList(
    List<SessionModel> sessions, {
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
  }) {
    if (sessions.isEmpty) {
      return buildEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: refreshSessions,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return buildSessionCard(session);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seanslarım'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Yaklaşan'),
              Tab(text: 'Tamamlandı'),
              Tab(text: 'İptal'),
            ],
          ),
        ),
        body: FutureBuilder<List<SessionModel>>(
          future: sessionsFuture,
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

            final upcomingSessions =
                filterSessionsByStatus(sessions, 'upcoming');
            final completedSessions =
                filterSessionsByStatus(sessions, 'completed');
            final cancelledSessions =
                filterSessionsByStatus(sessions, 'cancelled');

            return TabBarView(
              children: [
                buildSessionList(
                  upcomingSessions,
                  emptyTitle: 'Yaklaşan seansın yok',
                  emptySubtitle:
                      'Yeni bir öğretmen seçip seans oluşturduğunda burada görünecek.',
                  emptyIcon: Icons.calendar_month_outlined,
                ),
                buildSessionList(
                  completedSessions,
                  emptyTitle: 'Tamamlanmış seans yok',
                  emptySubtitle: 'Geçmiş seansların burada listelenecek.',
                  emptyIcon: Icons.check_circle_outline,
                ),
                buildSessionList(
                  cancelledSessions,
                  emptyTitle: 'İptal edilen seans yok',
                  emptySubtitle: 'İptal ettiğin seanslar burada görünecek.',
                  emptyIcon: Icons.cancel_outlined,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}