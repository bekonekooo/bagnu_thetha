import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/app/theme.dart';
import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/social/data/models/comment_model.dart';
import 'package:flutter_application_1/features/social/data/models/social_target.dart';
import 'package:flutter_application_1/features/social/data/services/comment_service.dart';
import 'package:flutter_application_1/features/social/data/services/favorite_service.dart';
import 'package:flutter_application_1/features/social/data/services/rating_service.dart';
import 'package:flutter_application_1/features/social/data/services/reaction_service.dart';
import 'package:flutter_application_1/features/social/data/services/report_service.dart';

class TeacherDetailPage extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherDetailPage({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  static const SocialTarget _target = SocialTarget.teacher;

  final FavoriteService _favoriteService = FavoriteService();
  final ReactionService _reactionService = ReactionService();
  final RatingService _ratingService = RatingService();
  final CommentService _commentService = CommentService();
  final ReportService _reportService = ReportService();

  late final String _id;

  // Favorite
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  // Like
  bool _isLiked = false;
  bool _likeBusy = false;
  int _likeCount = 0;

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

  @override
  void initState() {
    super.initState();
    _id = widget.teacher['id']?.toString() ?? '';
    _likeCount = _parseInt(widget.teacher['like_count']);
    _ratingAvg = _parseDouble(widget.teacher['rating_avg']);
    _ratingCount = _parseInt(widget.teacher['rating_count']);
    _loadSocialState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double parseDouble(dynamic value) => _parseDouble(value);

  String formatPrice({
    required double price,
    required String currency,
  }) {
    if (price <= 0) {
      return 'Ücret belirtilmemiş';
    }

    final cleanPrice =
        price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);

    if (currency.toLowerCase() == 'try') {
      return '₺$cleanPrice';
    }

    return '$cleanPrice ${currency.toUpperCase()}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadSocialState() async {
    if (_id.isEmpty) {
      if (mounted) {
        setState(() => _commentsLoading = false);
      }
      return;
    }

    // Favorite + like + rating (best effort, do not block UI on failure).
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
      _showMessage(previous ? 'Favorilerden çıkarıldı.' : 'Favorilere eklendi.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFavorite = previous;
        _favoriteBusy = false;
      });
      _showMessage(_friendlyError(e, 'Favori işlemi yapılamadı.'));
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
      _showMessage(_friendlyError(e, 'Beğeni işlemi yapılamadı.'));
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
      _showMessage('Puanın kaydedildi.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myRating = previousRating;
        _ratingBusy = false;
      });
      _showMessage(_friendlyError(e, 'Puan kaydedilemedi.'));
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
      _showMessage(_friendlyError(e, 'Yorum gönderilemedi.'));
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
      _showMessage('Yorum silindi.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e, 'Yorum silinemedi.'));
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
        _showMessage('Şikayetin alındı. Teşekkürler.');
      } catch (e) {
        _showMessage(_friendlyError(e, 'Şikayet gönderilemedi.'));
      }
    }

    detailsController.dispose();
  }

  String _friendlyError(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) return fallback;

    // Show service-provided Turkish messages, hide raw/technical errors.
    final looksFriendly =
        RegExp(r'[çğıöşüÇĞİÖŞÜ]').hasMatch(message) ||
            message.contains('giriş') ||
            message.contains('Puan') ||
            message.contains('Yorum') ||
            message.contains('bildirdin');

    return looksFriendly ? message : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final id = _id;
    final name = widget.teacher['name']?.toString() ?? '';
    final specialty = widget.teacher['specialty']?.toString() ?? '';
    final experience = widget.teacher['experience']?.toString() ?? '';
    final rating = widget.teacher['rating']?.toString() ?? '0';
    final bio = widget.teacher['bio']?.toString() ?? '';
    final category = widget.teacher['category']?.toString() ?? '';
    final imageUrl = widget.teacher['image_url']?.toString() ?? '';
    final isActive = widget.teacher['is_active'] == true;

    final sessionPrice = parseDouble(widget.teacher['session_price']);
    final currency = widget.teacher['currency']?.toString() ?? 'try';
    final formattedPrice = formatPrice(
      price: sessionPrice,
      currency: currency,
    );

    final hasImage = imageUrl.trim().isNotEmpty;
    final canBook = isActive && id.isNotEmpty && sessionPrice > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen Detayı'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryPurple,
                    AppTheme.darkPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                    child: hasImage
                        ? null
                        : const Icon(
                            Icons.person,
                            size: 48,
                            color: AppTheme.primaryPurple,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.isEmpty ? 'Öğretmen' : name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialty.isEmpty ? 'Uzmanlık bilgisi yok' : specialty,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _HeaderBadge(
                        icon: Icons.category_outlined,
                        text: category.isEmpty ? 'Kategori' : category,
                      ),
                      _HeaderBadge(
                        icon: Icons.workspace_premium_outlined,
                        text: experience.isEmpty ? 'Deneyim' : experience,
                      ),
                      _HeaderBadge(
                        icon: Icons.star,
                        text: rating,
                        iconColor: AppTheme.gold,
                      ),
                      _HeaderBadge(
                        icon: Icons.payments_outlined,
                        text: formattedPrice,
                        iconColor: Colors.greenAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSocialBar(),

            const SizedBox(height: 16),

            _buildPriceCard(
              price: formattedPrice,
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.category_outlined,
              title: 'Kategori',
              value: category.isEmpty ? 'Belirtilmemiş' : category,
            ),
            _buildInfoCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Deneyim',
              value: experience.isEmpty ? 'Belirtilmemiş' : experience,
            ),
            _buildInfoCard(
              icon: Icons.star_outline,
              title: 'Puan',
              value: rating,
            ),
            _buildInfoCard(
              icon: Icons.menu_book_outlined,
              title: 'Hakkında',
              value: bio.isEmpty
                  ? 'Bu öğretmen hakkında henüz açıklama eklenmemiş.'
                  : bio,
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Bu öğretmen şu anda seans kabul ediyor.'
                          : 'Bu öğretmen şu anda aktif değil.',
                      style: TextStyle(
                        color: isActive ? Colors.green.shade800 : Colors.red,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isActive && sessionPrice <= 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bu öğretmen için seans ücreti henüz belirlenmemiş. Randevu alınamaz.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canBook
                    ? () {
                        context.push(
                          '/booking',
                          extra: {
                            'teacherId': id,
                            'teacherName': name,
                            'sessionPrice': sessionPrice,
                            'currency': currency,
                          },
                        );
                      }
                    : null,
                icon: const Icon(Icons.calendar_month),
                label: Text('Randevu Al - $formattedPrice'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildCommentsSection(),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Öğretmenlere Dön'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBar() {
    final avgText = _ratingCount > 0
        ? '${_ratingAvg.toStringAsFixed(1)} ($_ratingCount)'
        : 'Henüz puan yok';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _id.isEmpty || _likeBusy ? null : _toggleLike,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? Colors.redAccent
                            : AppTheme.textSoft,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_likeCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    avgText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 22),
          Text(
            _myRating == null ? 'Bu öğretmeni puanla' : 'Puanın: $_myRating',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
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
                onPressed: _id.isEmpty || _ratingBusy
                    ? null
                    : () => _setRating(value),
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: AppTheme.gold,
                  size: 30,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yorumlar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
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
                        color: AppTheme.primaryPurple,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCommentsList(),
        ],
      ),
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
              style: TextStyle(color: AppTheme.textSoft),
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
            style: TextStyle(color: AppTheme.textSoft),
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

  Widget _buildPriceCard({
    required String price,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.payments_outlined,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seans Ücreti',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ödeme bir sonraki adımda alınacak.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.softPurple,
            child: Icon(
              icon,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            backgroundColor: AppTheme.softPurple,
            backgroundImage: hasImage
                ? NetworkImage(comment.authorImageUrl!)
                : null,
            child: hasImage
                ? null
                : const Icon(
                    Icons.person,
                    size: 18,
                    color: AppTheme.primaryPurple,
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
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: AppTheme.textDark,
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
              color: AppTheme.textSoft,
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

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _HeaderBadge({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
