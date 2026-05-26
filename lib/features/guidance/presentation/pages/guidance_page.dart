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

  @override
  Widget build(BuildContext context) {
    final remainingCount = maxAllowedCount - usedCount;
    final safeRemainingCount = remainingCount < 0 ? 0 : remainingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Rehberlik'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
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
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: '1. Rehberlik türünü seç',
                    subtitle: 'Hangi alanda analiz almak istediğini seç.',
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
                        icon: guidanceTypeIcons[type] ?? Icons.auto_awesome,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            selectedType = type;
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
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
                    icon: Icons.cake,
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
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _SectionTitle(
                    title: '3. Ek detay',
                    subtitle:
                        'Yapay zekanın özellikle odaklanmasını istediğin konuyu yazabilirsin.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: extraInfoController,
                    minLines: 3,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Ek detay',
                      hintText:
                          'İlişki, kariyer, ruhsal yolculuk, aile, para veya merak ettiğin başka bir konu...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
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
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (resultText != null) ...[
                    const SizedBox(height: 24),
                    _ResultCard(result: resultText!),
                  ],
                ],
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
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.deepPurple.shade50,
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kişisel rehberliğini oluştur',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'İsim, doğum tarihi ve seçtiğin analiz türüne göre yapay zekaya özel bir istek gönderilecek.',
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.35,
                    color: Colors.grey.shade700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Colors.deepPurple,
        ),
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.deepPurple,
            width: 1.5,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isSubscribed
              ? [
                  Colors.deepPurple.shade400,
                  Colors.indigo.shade700,
                ]
              : [
                  Colors.grey.shade700,
                  Colors.grey.shade900,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSubscribed ? Icons.workspace_premium : Icons.lock_clock,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 14),
          Text(
            isSubscribed ? 'Premium rehberlik aktif' : 'Ücretsiz rehberlik',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSubscribed
                ? 'Plan: $subscriptionPlan • Her 7 günde 1 hak'
                : 'Her 30 günde 1 ücretsiz hak',
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Kalan hak: $remainingCount / $maxAllowedCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu dönem: Son $periodText içinde $usedCount kullanım',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  isSelected ? Colors.deepPurple : Colors.grey.shade100,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.deepPurple,
              ),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.deepPurple,
            size: 30,
          ),
          const SizedBox(height: 12),
          const Text(
            'Rehberlik Sonucu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Not: Bu yorum kişisel farkındalık ve eğlence amaçlıdır; kesin gelecek tahmini değildir.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}