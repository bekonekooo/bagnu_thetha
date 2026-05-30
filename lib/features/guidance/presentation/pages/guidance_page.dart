import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/core/services/supabase_service.dart';
import 'package:flutter_application_1/features/guidance/data/services/guidance_service.dart';

class GuidancePage extends StatefulWidget {
  const GuidancePage({super.key});

  @override
  State<GuidancePage> createState() => _GuidancePageState();
}

class _GuidancePageState extends State<GuidancePage> {
  final GuidanceService guidanceService = GuidanceService();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController extraInfoController = TextEditingController();

  String selectedType = 'chinese_zodiac';
  DateTime? selectedBirthDate;
  TimeOfDay? selectedBirthTime;

  bool isLoading = true;
  bool isSubmitting = false;

  bool isSubscribed = false;
  String subscriptionPlan = 'free';

  int usedCount = 0;
  int maxAllowedCount = 1;
  String periodText = '30 gün';

  String? resultText;

  static const String guidanceBackground =
      'assets/images/backgrounds/home_bg_5.jpg';

  final Map<String, String> guidanceTypeLabels = {
    'chinese_zodiac': 'Çin Burcu',
    'astrology': 'Astroloji',
    'numerology': 'Numeroloji',
  };

  final Map<String, IconData> guidanceTypeIcons = {
    'chinese_zodiac': Icons.pets,
    'astrology': Icons.auto_awesome,
    'numerology': Icons.calculate,
  };

  @override
  void initState() {
    super.initState();
    loadUsageInfo();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    extraInfoController.dispose();
    super.dispose();
  }

  Future<void> loadUsageInfo() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final profile = await supabase
          .from('profiles')
          .select(
            'is_subscribed, subscription_plan, subscription_ends_at',
          )
          .eq('id', user.id)
          .single();

      final profileSubscribed = profile['is_subscribed'] == true;
      final endsAtValue = profile['subscription_ends_at'];

      bool activeSubscription = profileSubscribed;

      if (profileSubscribed && endsAtValue != null) {
        final endsAt = DateTime.tryParse(endsAtValue.toString());

        if (endsAt == null || endsAt.isBefore(DateTime.now())) {
          activeSubscription = false;
        }
      }

      final limitDate = activeSubscription
          ? DateTime.now().subtract(const Duration(days: 7))
          : DateTime.now().subtract(const Duration(days: 30));

      final requests = await supabase
          .from('guidance_requests')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', limitDate.toIso8601String());

      if (!mounted) return;

      setState(() {
        isSubscribed = activeSubscription;
        subscriptionPlan = profile['subscription_plan']?.toString() ?? 'free';
        usedCount = requests.length;
        maxAllowedCount = 1;
        periodText = activeSubscription ? '7 gün' : '30 gün';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanım bilgisi alınamadı: $e'),
        ),
      );
    }
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Doğum tarihini seç',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );

    if (pickedDate == null) return;

    setState(() {
      selectedBirthDate = pickedDate;
    });
  }

  Future<void> pickBirthTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedBirthTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Doğum saatini seç',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );

    if (pickedTime == null) return;

    setState(() {
      selectedBirthTime = pickedTime;
    });
  }

  String formatBirthDateForDb(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String? formatBirthTimeForDb(TimeOfDay? time) {
    if (time == null) return null;

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  String formatBirthDateForUi(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String formatBirthTimeForUi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> submitGuidanceRequest() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için giriş yapmalısın.'),
        ),
      );
      return;
    }

    final fullName = fullNameController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen analiz yapılacak kişinin ismini yaz.'),
        ),
      );
      return;
    }

    if (selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen doğum tarihini seç.'),
        ),
      );
      return;
    }

    if (usedCount >= maxAllowedCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSubscribed
                ? 'Haftalık rehberlik hakkını kullandın.'
                : 'Aylık rehberlik hakkını kullandın.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
      resultText = null;
    });

    try {
      final response = await guidanceService.createGuidanceRequest(
        fullName: fullName,
        guidanceType: selectedType,
        birthDate: formatBirthDateForDb(selectedBirthDate!),
        birthTime: formatBirthTimeForDb(selectedBirthTime),
        extraInfo: extraInfoController.text.trim().isEmpty
            ? null
            : extraInfoController.text.trim(),
      );

      final aiResult = response['result']?.toString();

      if (aiResult == null || aiResult.trim().isEmpty) {
        throw Exception('AI sonucu boş döndü.');
      }

      if (!mounted) return;

      setState(() {
        resultText = aiResult;
        usedCount = usedCount + 1;
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rehberlik başarıyla oluşturuldu.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rehberlik oluşturulamadı: $e'),
        ),
      );
    }
  }

  Widget buildBackgroundBody({
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            guidanceBackground,
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
                  Colors.black.withOpacity(0.20),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget buildExtraInfoField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextField(
        controller: extraInfoController,
        minLines: 3,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: const Color(0xFF536B4E),
        decoration: InputDecoration(
          labelText: 'Ek detay',
          hintText:
              'İlişki, kariyer, ruhsal yolculuk, aile, para veya merak ettiğin başka bir konu...',
          alignLabelWithHint: true,
          labelStyle: const TextStyle(
            color: Color(0xFF667064),
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9AA09A),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(
              color: Color(0xFF536B4E),
              width: 1.4,
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : submitGuidanceRequest,
        icon: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          isSubmitting
              ? 'Yapay zeka hazırlanıyor...'
              : 'Rehberliğimi Oluştur',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF536B4E),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  String _subtitleForType(String type) {
    switch (type) {
      case 'chinese_zodiac':
        return 'Doğum yılına göre Çin burcu yorumunu al.';
      case 'astrology':
        return 'Doğum tarihi ve saatine göre astrolojik analiz al.';
      case 'numerology':
        return 'İsim ve doğum tarihinden numeroloji yorumunu oluştur.';
      default:
        return 'Kişisel analizini oluştur.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingCount = maxAllowedCount - usedCount;
    final safeRemainingCount = remainingCount < 0 ? 0 : remainingCount;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Aylık Rehberlik',
          style: TextStyle(
            color: Color(0xFF2F3A32),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2F3A32),
      ),
      body: buildBackgroundBody(
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF536B4E),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeroInfoCard(),
                      const SizedBox(height: 16),
                      _SubscriptionInfoCard(
                        isSubscribed: isSubscribed,
                        subscriptionPlan: subscriptionPlan,
                        usedCount: usedCount,
                        maxAllowedCount: maxAllowedCount,
                        remainingCount: safeRemainingCount,
                        periodText: periodText,
                      ),
                      const SizedBox(height: 22),

                      const _SectionTitle(
                        title: '1. Rehberlik türünü seç',
                        subtitle:
                            'Hangi alanda analiz almak istediğini seç.',
                      ),
                      const SizedBox(height: 12),

                      ...guidanceTypeLabels.entries.map((entry) {
                        final type = entry.key;
                        final label = entry.value;
                        final isSelected = selectedType == type;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GuidanceTypeCard(
                            title: label,
                            subtitle: _subtitleForType(type),
                            icon:
                                guidanceTypeIcons[type] ?? Icons.auto_awesome,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                selectedType = type;
                              });
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 10),

                      const _SectionTitle(
                        title: '2. Kişi bilgileri',
                        subtitle:
                            'Analiz kendi adına ya da başka biri adına yapılabilir.',
                      ),
                      const SizedBox(height: 12),

                      _TextInputCard(
                        controller: fullNameController,
                        icon: Icons.badge_outlined,
                        label: 'Analiz yapılacak kişinin adı soyadı',
                        hintText: 'Örn: Ayşe Yılmaz',
                      ),
                      const SizedBox(height: 12),

                      _PickerTile(
                        icon: Icons.cake_outlined,
                        title: 'Doğum tarihi',
                        value: selectedBirthDate == null
                            ? 'Zorunlu'
                            : formatBirthDateForUi(selectedBirthDate!),
                        onTap: pickBirthDate,
                      ),
                      const SizedBox(height: 12),

                      _PickerTile(
                        icon: Icons.access_time,
                        title: 'Doğum saati',
                        value: selectedBirthTime == null
                            ? 'Opsiyonel'
                            : formatBirthTimeForUi(selectedBirthTime!),
                        onTap: pickBirthTime,
                      ),

                      if (selectedBirthTime != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedBirthTime = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Saati kaldır'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF536B4E),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      const _SectionTitle(
                        title: '3. Ek detay',
                        subtitle:
                            'Yapay zekanın özellikle odaklanmasını istediğin konuyu yazabilirsin.',
                      ),
                      const SizedBox(height: 12),

                      buildExtraInfoField(),

                      const SizedBox(height: 24),

                      buildSubmitButton(),

                      if (resultText != null) ...[
                        const SizedBox(height: 24),
                        _ResultCard(result: resultText!),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF536B4E),
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişisel rehberliğini oluştur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'İsim, doğum tarihi ve seçtiğin analiz türüne göre yapay zekaya özel bir istek gönderilecek.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF606A61),
                    fontWeight: FontWeight.w500,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EA).withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD7E1D0),
              ),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: Color(0xFF536B4E),
              size: 27,
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F3A32),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF606A61),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _TextInputCard extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hintText;

  const _TextInputCard({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: const Color(0xFF536B4E),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF536B4E),
        ),
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: Color(0xFF667064),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9AA09A),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.76),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.70),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.70),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(
            color: Color(0xFF536B4E),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _SubscriptionInfoCard extends StatelessWidget {
  final bool isSubscribed;
  final String subscriptionPlan;
  final int usedCount;
  final int maxAllowedCount;
  final int remainingCount;
  final String periodText;

  const _SubscriptionInfoCard({
    required this.isSubscribed,
    required this.subscriptionPlan,
    required this.usedCount,
    required this.maxAllowedCount,
    required this.remainingCount,
    required this.periodText,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor =
        isSubscribed ? const Color(0xFF536B4E) : const Color(0xFF6B736A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isSubscribed
                    ? const Color(0xFFEAF3E8)
                    : const Color(0xFFF1F2EF),
                child: Icon(
                  isSubscribed ? Icons.workspace_premium : Icons.lock_clock,
                  color: mainColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSubscribed
                      ? 'Premium rehberlik aktif'
                      : 'Ücretsiz rehberlik',
                  style: const TextStyle(
                    color: Color(0xFF2F3A32),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSubscribed
                ? 'Plan: $subscriptionPlan • Her 7 günde 1 hak'
                : 'Her 30 günde 1 ücretsiz hak',
            style: const TextStyle(
              color: Color(0xFF606A61),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: maxAllowedCount <= 0
                  ? 0
                  : (usedCount / maxAllowedCount).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.75),
              color: mainColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kalan hak: $remainingCount / $maxAllowedCount',
            style: TextStyle(
              color: mainColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu dönem: Son $periodText içinde $usedCount kullanım',
            style: const TextStyle(
              color: Color(0xFF606A61),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GuidanceTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = const Color(0xFF536B4E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? selectedColor.withOpacity(0.50)
                  : Colors.white.withOpacity(0.70),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEEF3EA).withOpacity(0.95)
                      : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD7E1D0)
                        : Colors.white.withOpacity(0.70),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? selectedColor : const Color(0xFF6B736A),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF606A61),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF536B4E),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != 'Zorunlu' && value != 'Opsiyonel';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasValue
                  ? const Color(0xFF536B4E).withOpacity(0.35)
                  : Colors.white.withOpacity(0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: hasValue
                    ? const Color(0xFF536B4E)
                    : const Color(0xFF6B736A),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F3A32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF606A61),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF536B4E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String result;

  const _ResultCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.74),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFF536B4E),
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Rehberlik Sonucu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F3A32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result,
            style: const TextStyle(
              fontSize: 14.8,
              height: 1.5,
              color: Color(0xFF2F3A32),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Not: Bu yorum kişisel farkındalık ve eğlence amaçlıdır; kesin gelecek tahmini değildir.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF606A61),
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}