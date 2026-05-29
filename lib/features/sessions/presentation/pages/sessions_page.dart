import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  static const String sessionsBackground =
      'assets/images/backgrounds/home_bg_2.jpg';

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

  void openVideoCall(SessionModel session) {
    context.push(
      '/video-call',
      extra: {
        'session': session,
        'participantName': 'Öğrenci',
      },
    );
  }

  String getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'Yaklaşan';
      case 'in_progress':
        return 'Ders Başladı';
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
        return const Color(0xFF4F7A52);
      case 'in_progress':
        return const Color(0xFF6D5FA8);
      case 'cancelled':
        return const Color(0xFFC85C5C);
      case 'completed':
        return const Color(0xFF4E7896);
      default:
        return const Color(0xFF6B736A);
    }
  }

  Color getStatusBackgroundColor(String status) {
    switch (status) {
      case 'upcoming':
        return const Color(0xFFEAF3E8);
      case 'in_progress':
        return const Color(0xFFEDEAF7);
      case 'cancelled':
        return const Color(0xFFF9EAEA);
      case 'completed':
        return const Color(0xFFEAF2F7);
      default:
        return const Color(0xFFF1F2EF);
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'upcoming':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_circle_outline;
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
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
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
              fontWeight: FontWeight.w800,
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
          color: const Color(0xFF536B4E),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2F3A32),
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF606A61),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildVideoCallBox(SessionModel session) {
    final canJoin = SessionUtils.canJoinVideoSession(session);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: canJoin
            ? const Color(0xFFEDEAF7).withOpacity(0.95)
            : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canJoin
              ? const Color(0xFF6D5FA8).withOpacity(0.25)
              : Colors.white.withOpacity(0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_call,
                color: canJoin
                    ? const Color(0xFF6D5FA8)
                    : const Color(0xFF7A8178),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  SessionUtils.getVideoJoinMessage(session),
                  style: TextStyle(
                    color: canJoin
                        ? const Color(0xFF6D5FA8)
                        : const Color(0xFF6B736A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canJoin
                  ? () {
                      openVideoCall(session);
                    }
                  : null,
              icon: const Icon(Icons.videocam),
              label: const Text('Görüntülü Derse Katıl'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D5FA8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSessionCard(SessionModel session) {
    final realStatus = SessionUtils.resolveStatus(session);
    final isActiveOrUpcoming =
        realStatus == 'upcoming' || realStatus == 'in_progress';

    final statusColor = getStatusColor(realStatus);
    final statusBackgroundColor = getStatusBackgroundColor(realStatus);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusBackgroundColor.withOpacity(0.90),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.88),
                    child: Icon(
                      getStatusIcon(realStatus),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.teacherName.isEmpty
                          ? 'Öğretmen'
                          : session.teacherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    _SoftInfoBox(
                      text:
                          'Bu seans iptal edildi. Aynı saat uygunsa tekrar randevu oluşturabilirsin.',
                      color: const Color(0xFFC85C5C),
                      backgroundColor: const Color(0xFFF9EAEA),
                    ),
                  ],
                  if (realStatus == 'completed') ...[
                    const SizedBox(height: 14),
                    _SoftInfoBox(
                      text: 'Bu seans tamamlandı olarak görünüyor.',
                      color: const Color(0xFF4E7896),
                      backgroundColor: const Color(0xFFEAF2F7),
                    ),
                  ],
                  if (isActiveOrUpcoming) ...[
                    const SizedBox(height: 16),
                    buildVideoCallBox(session),
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
                          isCancelling
                              ? 'İptal ediliyor...'
                              : 'Seansı İptal Et',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC85C5C),
                          side: const BorderSide(
                            color: Color(0xFFC85C5C),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
            height: MediaQuery.of(context).size.height * 0.62,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.76),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.70),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            const Color(0xFFEEF3EA).withOpacity(0.95),
                        child: Icon(
                          icon,
                          size: 38,
                          color: const Color(0xFF536B4E),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F3A32),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF606A61),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.70),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 54,
                        color: Color(0xFFC85C5C),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Seanslar yüklenemedi',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F3A32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF606A61),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: refreshSessions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF536B4E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF536B4E),
      ),
    );
  }

  Widget buildBackgroundBody({
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            sessionsBackground,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.16),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.16),
                  Colors.white.withOpacity(0.04),
                  Colors.black.withOpacity(0.18),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionModel>>(
      future: sessionsFuture,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        final upcomingSessions = filterSessionsByStatus(sessions, 'upcoming');
        final inProgressSessions =
            filterSessionsByStatus(sessions, 'in_progress');
        final completedSessions = filterSessionsByStatus(sessions, 'completed');
        final cancelledSessions = filterSessionsByStatus(sessions, 'cancelled');

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text(
                'Seanslarım',
                style: TextStyle(
                  color: Color(0xFF2F3A32),
                  fontWeight: FontWeight.w900,
                ),
              ),
              backgroundColor: Colors.white.withOpacity(0.18),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xFF2F3A32),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.62),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    labelColor: const Color(0xFF2F3A32),
                    unselectedLabelColor: const Color(0xFF6B736A),
                    indicator: BoxDecoration(
                      color: const Color(0xFFEEF3EA).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD7E1D0),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: [
                      buildTabLabel(
                        title: 'Yaklaşan',
                        count: upcomingSessions.length,
                      ),
                      buildTabLabel(
                        title: 'Ders Başladı',
                        count: inProgressSessions.length,
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
              ),
            ),
            body: buildBackgroundBody(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight +
                        MediaQuery.of(context).padding.top +
                        62,
                  ),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? buildLoadingState()
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
                                  inProgressSessions,
                                  emptyTitle: 'Başlamış ders yok',
                                  emptySubtitle:
                                      'Ders saati başladığında aktif derslerin burada görünecek.',
                                  emptyIcon: Icons.play_circle_outline,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SoftInfoBox extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;

  const _SoftInfoBox({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}