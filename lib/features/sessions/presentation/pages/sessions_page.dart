import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/session_model.dart';
import '../../data/services/session_service.dart';
import '../../utils/session_utils.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final sessionService = SessionService();

  late Future<List<SessionModel>> sessionsFuture;
  bool isCancelling = false;

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
    if (isCancelling) return;

    setState(() {
      isCancelling = true;
    });

    try {
      await sessionService.cancelSession(sessionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seans başarıyla iptal edildi'),
        ),
      );

      setState(() {
        loadSessions();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İptal sırasında hata oluştu: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isCancelling = false;
      });
    }
  }

  Future<void> showCancelDialog(SessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seansı iptal et'),
          content: Text(
            '${formatDate(session.sessionDate)} saat ${session.sessionTime} için olan seansını iptal etmek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.close),
              label: const Text('İptal Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await cancelSession(session.id);
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

  Color getStatusBackgroundColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.green.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      case 'completed':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
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

  Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSessionCard(SessionModel session) {
    final realStatus = SessionUtils.resolveStatus(session);
    final isUpcoming = realStatus == 'upcoming';

    final statusColor = getStatusColor(realStatus);
    final statusBackgroundColor = getStatusBackgroundColor(realStatus);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black12,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.teacherName.isEmpty
                        ? 'Öğretmen'
                        : session.teacherName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                buildStatusBadge(realStatus),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Tarih',
                  value: formatDate(session.sessionDate),
                ),
                const SizedBox(height: 12),
                buildInfoRow(
                  icon: Icons.access_time,
                  title: 'Saat',
                  value: session.sessionTime,
                ),
                if (session.notes != null &&
                    session.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  buildInfoRow(
                    icon: Icons.notes_outlined,
                    title: 'Not',
                    value: session.notes!,
                  ),
                ],
                if (realStatus == 'cancelled') ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Bu seans iptal edildi. Aynı saat uygunsa tekrar randevu oluşturabilirsin.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (realStatus == 'completed') ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Bu seans tamamlandı olarak görünüyor.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isUpcoming) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isCancelling
                          ? null
                          : () {
                              showCancelDialog(session);
                            },
                      icon: isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.close),
                      label: Text(
                        isCancelling ? 'İptal ediliyor...' : 'Seansı İptal Et',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return RefreshIndicator(
      onRefresh: refreshSessions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Icon(
                      icon,
                      size: 38,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
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
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return buildSessionCard(session);
        },
      ),
    );
  }

  Widget buildErrorState(Object? error) {
    return RefreshIndicator(
      onRefresh: refreshSessions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 54,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seanslar yüklenemedi',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: refreshSessions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabLabel({
    required String title,
    required int count,
  }) {
    return Tab(
      child: FittedBox(
        child: Text('$title ($count)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionModel>>(
      future: sessionsFuture,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        final upcomingSessions = filterSessionsByStatus(sessions, 'upcoming');
        final completedSessions = filterSessionsByStatus(sessions, 'completed');
        final cancelledSessions = filterSessionsByStatus(sessions, 'cancelled');

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Seanslarım'),
              bottom: TabBar(
                tabs: [
                  buildTabLabel(
                    title: 'Yaklaşan',
                    count: upcomingSessions.length,
                  ),
                  buildTabLabel(
                    title: 'Tamamlandı',
                    count: completedSessions.length,
                  ),
                  buildTabLabel(
                    title: 'İptal',
                    count: cancelledSessions.length,
                  ),
                ],
              ),
            ),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : snapshot.hasError
                    ? buildErrorState(snapshot.error)
                    : TabBarView(
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
                            emptySubtitle:
                                'Geçmiş seansların burada listelenecek.',
                            emptyIcon: Icons.check_circle_outline,
                          ),
                          buildSessionList(
                            cancelledSessions,
                            emptyTitle: 'İptal edilen seans yok',
                            emptySubtitle:
                                'İptal edilen seansların burada görünecek.',
                            emptyIcon: Icons.cancel_outlined,
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }
}