import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/theme.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/comment_model.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';
import 'package:flutter_application_1/features/social/data/services/comment_service.dart';
import 'package:flutter_application_1/features/social/data/services/favorite_service.dart';
import 'package:flutter_application_1/features/social/data/services/rating_service.dart';
import 'package:flutter_application_1/features/social/data/services/reaction_service.dart';
import 'package:flutter_application_1/features/social/data/services/report_service.dart';
import 'package:flutter_application_1/features/trainings/data/models/training_model.dart';
import 'package:flutter_application_1/features/trainings/data/services/training_service.dart';

class TrainingDetailPage extends StatefulWidget {
  final TrainingModel training;
  final bool initiallyJoined;

  const TrainingDetailPage({
    super.key,
    required this.training,
    required this.initiallyJoined,
  });

  @override
  State<TrainingDetailPage> createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  final TrainingService trainingService = TrainingService();

  static const SocialTarget _target = SocialTarget.training;

  final FavoriteService _favoriteService = FavoriteService();
  final ReactionService _reactionService = ReactionService();
  final RatingService _ratingService = RatingService();
  final CommentService _commentService = CommentService();
  final ReportService _reportService = ReportService();

  late bool isJoined;
  bool isLoading = false;

  // Favorite
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  // Like
  bool _isLiked = false;
  bool _likeBusy = false;
  late int _likeCount;

  // Rating
  int? _myRating;
  bool _ratingBusy = false;
  late double _ratingAvg;
  late int _ratingCount;

  // Comments
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _commentsLoading = true;
  bool _commentsError = false;
  bool _commentSending = false;

  static const String pageBackground =
      'assets/images/backgrounds/home_bg_5.jpg';

  String get _id => widget.training.id;

  @override
  void initState() {
    super.initState();
    isJoined = widget.initiallyJoined;
    _likeCount = widget.training.likeCount;
    _ratingAvg = widget.training.ratingAvg;
    _ratingCount = widget.training.ratingCount;
    _loadSocialState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _friendlyError(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) return fallback;

    final looksFriendly =
        RegExp(r'[çğıöşüÇĞİÖŞÜ]').hasMatch(message) ||
            message.contains('giriş') ||
            message.contains('Puan') ||
            message.contains('Yorum') ||
            message.contains('bildirdin');

    return looksFriendly ? message : fallback;
  }

  Future<void> _loadSocialState() async {
    if (_id.isEmpty) {
      if (mounted) setState(() => _commentsLoading = false);
      return;
    }

    try {
      final favorite = await _favoriteService.isFavorite(_target, _id);
      if (mounted) setState(() => _isFavorite = favorite);
    } catch (_) {}

    try {
      final liked = await _reactionService.isLiked(_target, _id);
      if (mounted) setState(() => _isLiked = liked);
    } catch (_) {}

    try {
      final rating = await _ratingService.fetchMyRating(_target, _id);
      if (mounted) setState(() => _myRating = rating);
    } catch (_) {}

    await _loadComments();
  }

  Future<void> _loadComments() async {
    if (_id.isEmpty) return;

    if (mounted) {
      setState(() {
        _commentsLoading = true;
        _commentsError = false;
      });
    }

    try {
      final comments = await _commentService.fetchComments(_target, _id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _commentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _commentsLoading = false;
        _commentsError = true;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_id.isEmpty || _favoriteBusy) return;

    final previous = _isFavorite;
    setState(() {
      _isFavorite = !previous;
      _favoriteBusy = true;
    });

    try {
      if (previous) {
        await _favoriteService.removeFavorite(_target, _id);
      } else {
        await _favoriteService.addFavorite(_target, _id);
      }
      if (!mounted) return;
      setState(() => _favoriteBusy = false);
      showMessage(previous ? 'Favorilerden çıkarıldı.' : 'Favorilere eklendi.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFavorite = previous;
        _favoriteBusy = false;
      });
      showMessage(_friendlyError(e, 'Favori işlemi yapılamadı.'));
    }
  }

  Future<void> _toggleLike() async {
    if (_id.isEmpty || _likeBusy) return;

    final previousLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !previousLiked;
      _likeCount = previousLiked
          ? (previousCount > 0 ? previousCount - 1 : 0)
          : previousCount + 1;
      _likeBusy = true;
    });

    try {
      if (previousLiked) {
        await _reactionService.unlike(_target, _id);
      } else {
        await _reactionService.like(_target, _id);
      }
      if (!mounted) return;
      setState(() => _likeBusy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = previousLiked;
        _likeCount = previousCount;
        _likeBusy = false;
      });
      showMessage(_friendlyError(e, 'Beğeni işlemi yapılamadı.'));
    }
  }

  Future<void> _setRating(int score) async {
    if (_id.isEmpty || _ratingBusy) return;

    final previousRating = _myRating;
    setState(() {
      _myRating = score;
      _ratingBusy = true;
    });

    try {
      await _ratingService.setRating(_target, _id, score);
      if (!mounted) return;
      setState(() => _ratingBusy = false);
      showMessage('Puanın kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myRating = previousRating;
        _ratingBusy = false;
      });
      showMessage(_friendlyError(e, 'Puan kaydedilemedi.'));
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _commentSending || _id.isEmpty) return;

    setState(() => _commentSending = true);

    try {
      final comment = await _commentService.addComment(_target, _id, text);
      if (!mounted) return;
      setState(() {
        _comments = [comment, ..._comments];
        _commentSending = false;
        _commentController.clear();
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _commentSending = false);
      showMessage(_friendlyError(e, 'Yorum gönderilemedi.'));
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu sil'),
        content: const Text('Bu yorumu silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _commentService.deleteComment(comment.id);
      if (!mounted) return;
      setState(() {
        _comments = _comments.where((c) => c.id != comment.id).toList();
      });
      showMessage('Yorum silindi.');
    } catch (e) {
      if (!mounted) return;
      showMessage(_friendlyError(e, 'Yorum silinemedi.'));
    }
  }

  Future<void> _reportContent({
    required SocialTarget type,
    required String targetId,
  }) async {
    if (targetId.isEmpty) return;

    final reasons = <String, String>{
      'inappropriate': 'Uygunsuz içerik',
      'spam': 'Spam',
      'harassment': 'Taciz',
      'other': 'Diğer',
    };

    String? selectedReason;
    final detailsController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Şikayet nedeni',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.entries.map(
                    (entry) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.primaryPurple,
                      title: Text(
                        entry.value,
                        style: const TextStyle(color: AppTheme.textDark),
                      ),
                      value: entry.key,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setSheetState(() => selectedReason = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Detay (isteğe bağlı)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedReason == null
                          ? null
                          : () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Gönder'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submitted == true && selectedReason != null) {
      try {
        await _reportService.submitReport(
          type: type,
          targetId: targetId,
          reason: selectedReason!,
          details: detailsController.text,
        );
        showMessage('Şikayetin alındı. Teşekkürler.');
      } catch (e) {
        showMessage(_friendlyError(e, 'Şikayet gönderilemedi.'));
      }
    }

    detailsController.dispose();
  }

  Future<void> joinOrLeaveTraining() async {
    if (widget.training.isCompleted) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isJoined) {
        await trainingService.leaveTraining(widget.training.id);

        if (!mounted) return;

        setState(() {
          isJoined = false;
          isLoading = false;
        });

        showMessage('Katılımın iptal edildi.');
      } else {
        await trainingService.joinTraining(widget.training.id);

        if (!mounted) return;

        setState(() {
          isJoined = true;
          isLoading = false;
        });

        showMessage('Eğitime katıldın.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(_friendlyError(e, 'İşlem yapılamadı.'));
    }
  }

  Widget buildBackgroundBody({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            pageBackground,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFEEF3EA),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.05),
                  Colors.black.withOpacity(0.22),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildImageFallback() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          color: Color(0xFF536B4E),
          size: 58,
        ),
      ),
    );
  }

  Widget buildCoverImage() {
    final training = widget.training;

    if (training.imageUrl.trim().isEmpty) {
      return buildImageFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: CachedNetworkImage(
        imageUrl: training.imageUrl,
        width: double.infinity,
        height: 230,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        placeholder: (context, url) => buildImageFallback(),
        errorWidget: (context, url, error) {
          return buildImageFallback();
        },
      ),
    );
  }

  Widget buildTag(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF536B4E),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF536B4E),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F3A32),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }

  Widget buildTeacherInfo() {
    final training = widget.training;

    if (training.teacherName.trim().isEmpty) {
      return const Text(
        'Eğitmen bilgisi belirtilmemiş.',
        style: TextStyle(
          color: Color(0xFF606A61),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFEEF3EA),
          backgroundImage: training.teacherImageUrl.isNotEmpty
              ? NetworkImage(training.teacherImageUrl)
              : null,
          child: training.teacherImageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  color: Color(0xFF536B4E),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                training.teacherName,
                style: const TextStyle(
                  color: Color(0xFF2F3A32),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              if (training.teacherSpecialty.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  training.teacherSpecialty,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSessionsList() {
    final training = widget.training;

    if (training.sessions.isEmpty) {
      return const Text(
        'Eğitim günleri henüz belirtilmemiş.',
        style: TextStyle(
          color: Color(0xFF606A61),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: training.sessions.map((session) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3EA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Color(0xFF536B4E),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${session.formattedDate} / ${session.formattedTimeRange}',
                  style: const TextStyle(
                    color: Color(0xFF2F3A32),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildJoinButton() {
    final training = widget.training;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed:
              training.isCompleted || isLoading ? null : joinOrLeaveTraining,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  training.isCompleted
                      ? Icons.lock_outline
                      : isJoined
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                ),
          label: Text(
            training.isCompleted
                ? 'Eğitim Bitmiş'
                : isLoading
                    ? 'İşleniyor...'
                    : isJoined
                        ? 'Katıldın - İptal Et'
                        : 'Eğitime Katıl',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isJoined ? Colors.grey.shade700 : const Color(0xFF536B4E),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBar() {
    final avgText = _ratingCount > 0
        ? '${_ratingAvg.toStringAsFixed(1)} ($_ratingCount)'
        : 'Henüz puan yok';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _id.isEmpty || _likeBusy ? null : _toggleLike,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked
                          ? Colors.redAccent
                          : const Color(0xFF536B4E),
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_likeCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.star, color: AppTheme.gold, size: 20),
            const SizedBox(width: 4),
            Text(
              avgText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF606A61),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Divider(color: Colors.grey.shade300, height: 18),
        Text(
          _myRating == null ? 'Bu eğitimi puanla' : 'Puanın: $_myRating',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2F3A32),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            final filled = _myRating != null && value <= _myRating!;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed:
                  _id.isEmpty || _ratingBusy ? null : () => _setRating(value),
              icon: Icon(
                filled ? Icons.star : Icons.star_border,
                color: AppTheme.gold,
                size: 30,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Yorumunu yaz...',
                  isDense: true,
                ),
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _commentSending ? null : _sendComment,
              icon: _commentSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.send,
                      color: Color(0xFF536B4E),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCommentsList(),
      ],
    );
  }

  Widget _buildCommentsList() {
    if (_commentsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_commentsError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text(
              'Yorumlar yüklenemedi.',
              style: TextStyle(color: Color(0xFF606A61)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadComments,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'İlk yorumu sen yaz',
            style: TextStyle(color: Color(0xFF606A61)),
          ),
        ),
      );
    }

    return Column(
      children: _comments
          .map(
            (comment) => _CommentTile(
              comment: comment,
              onDelete: () => _deleteComment(comment),
              onReport: () => _reportContent(
                type: SocialTarget.comment,
                targetId: comment.id,
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.training;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Eğitim Detayı',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
            onPressed: _id.isEmpty || _favoriteBusy ? null : _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : null,
            ),
          ),
          IconButton(
            tooltip: 'Şikayet et',
            onPressed: _id.isEmpty
                ? null
                : () => _reportContent(type: _target, targetId: _id),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      bottomNavigationBar: buildJoinButton(),
      body: buildBackgroundBody(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              buildCoverImage(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.72),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        buildTag(
                          training.statusLabel,
                          icon: Icons.timeline,
                        ),
                        buildTag(
                          training.formattedPrice,
                          icon: Icons.payments_outlined,
                        ),
                        buildTag(
                          training.formattedLocationType,
                          icon: training.locationType == 'online'
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                        ),
                        if (training.category.trim().isNotEmpty)
                          buildTag(
                            training.category,
                            icon: Icons.category_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      training.title,
                      style: const TextStyle(
                        color: Color(0xFF2F3A32),
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'İlk gün: ${training.firstDateText}',
                      style: const TextStyle(
                        color: Color(0xFF536B4E),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              buildInfoCard(
                title: 'Eğitmen',
                child: buildTeacherInfo(),
              ),
              buildInfoCard(
                title: 'Eğitim Açıklaması',
                child: Text(
                  training.description.trim().isEmpty
                      ? 'Açıklama belirtilmemiş.'
                      : training.description,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              buildInfoCard(
                title: 'Gün ve Saatler',
                child: buildSessionsList(),
              ),
              buildInfoCard(
                title: 'Konum / Bağlantı',
                child: Text(
                  training.locationText.trim().isEmpty
                      ? 'Konum bilgisi belirtilmemiş.'
                      : training.locationText,
                  style: const TextStyle(
                    color: Color(0xFF606A61),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (training.capacity != null)
                buildInfoCard(
                  title: 'Kontenjan',
                  child: Text(
                    '${training.capacity} kişi',
                    style: const TextStyle(
                      color: Color(0xFF606A61),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              buildInfoCard(
                title: 'Etkileşim',
                child: _buildSocialBar(),
              ),
              buildInfoCard(
                title: 'Yorumlar',
                child: _buildCommentsSection(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const _CommentTile({
    required this.comment,
    required this.onDelete,
    required this.onReport,
  });

  bool get _isMine {
    final user = supabase.auth.currentUser;
    return user != null && user.id == comment.userId;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = comment.authorImageUrl != null &&
        comment.authorImageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEEF3EA),
            backgroundImage:
                hasImage ? NetworkImage(comment.authorImageUrl!) : null,
            child: hasImage
                ? null
                : const Icon(
                    Icons.person,
                    size: 18,
                    color: Color(0xFF536B4E),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F3A32),
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF606A61),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: Color(0xFF2F3A32),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 18,
              color: Color(0xFF606A61),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              } else if (value == 'report') {
                onReport();
              }
            },
            itemBuilder: (context) => [
              if (_isMine)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Sil'),
                ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Şikayet et'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}