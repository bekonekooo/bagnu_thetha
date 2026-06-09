import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ProfileOnboardingPage extends StatefulWidget {
  const ProfileOnboardingPage({super.key});

  @override
  State<ProfileOnboardingPage> createState() => _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends State<ProfileOnboardingPage> {
  final PageController pageController = PageController();

  final birthDateController = TextEditingController();
  final cityController = TextEditingController();
  final intentionController = TextEditingController();

  DateTime? selectedBirthDate;

  int currentStep = 0;
  bool isLoading = false;

  String selectedExperienceLevel = 'Yeni başlıyorum';

  final List<String> experienceLevels = [
    'Yeni başlıyorum',
    'Biraz deneyimim var',
    'Daha önce eğitim/seans aldım',
  ];

  final List<String> interestOptions = [
    'ThetaHealing',
    'Meditasyon',
    'Bolluk',
    'İlişkiler',
    'Ruhsal Gelişim',
    'Aylık Rehberlik',
    'Eğitimler',
  ];

  final Set<String> selectedInterests = {};

  int get totalSteps => 5;

  double get progressValue => (currentStep + 1) / totalSteps;

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  String formatDateForSupabase(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$year-$month-$day';
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Doğum tarihini seç',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );

    if (pickedDate == null) return;

    setState(() {
      selectedBirthDate = pickedDate;
      birthDateController.text = formatDate(pickedDate);
    });
  }

  Future<void> nextStep() async {
    if (currentStep == totalSteps - 1) {
      await saveProfileOnboarding();
      return;
    }

    await pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> previousStep() async {
    if (currentStep == 0) return;

    await pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> saveProfileOnboarding() async {
    if (isLoading) return;

    final user = supabase.auth.currentUser;

    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await supabase.from('profiles').update({
        'birth_date': selectedBirthDate == null
            ? null
            : formatDateForSupabase(selectedBirthDate!),
        'city': cityController.text.trim().isEmpty
            ? null
            : cityController.text.trim(),
        'experience_level': selectedExperienceLevel,
        'interests': selectedInterests.toList(),
        'intention': intentionController.text.trim().isEmpty
            ? null
            : intentionController.text.trim(),
        'onboarding_completed': true,
      }).eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil bilgilerin kaydedildi.'),
        ),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil kaydetme hatası: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStepShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.deepPurple,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D2438),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6F6678),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  Widget buildBirthDateStep() {
    return buildStepShell(
      icon: Icons.cake_outlined,
      title: 'Doğum tarihini öğrenebilir miyiz?',
      subtitle:
          'Bu bilgi sana daha kişisel rehberlikler ve içerikler sunmamıza yardımcı olur.',
      child: CustomTextField(
        label: 'Doğum Tarihi',
        controller: birthDateController,
        prefixIcon: Icons.calendar_month_outlined,
        hintText: 'Seçmek için dokun',
        readOnly: true,
        onTap: pickBirthDate,
      ),
    );
  }

  Widget buildCityStep() {
    return buildStepShell(
      icon: Icons.location_city_outlined,
      title: 'Hangi şehirde yaşıyorsun?',
      subtitle:
          'Etkinlik, eğitim ve topluluk önerilerini daha uygun göstermek için kullanılır.',
      child: CustomTextField(
        label: 'Şehir',
        controller: cityController,
        prefixIcon: Icons.location_on_outlined,
        hintText: 'Örn: Antalya',
      ),
    );
  }

  Widget buildExperienceStep() {
    return buildStepShell(
      icon: Icons.auto_awesome_outlined,
      title: 'Bu yolculukta hangi seviyedesin?',
      subtitle:
          'Deneyim seviyene göre içerikleri daha doğru şekilde önerebiliriz.',
      child: Column(
        children: experienceLevels.map((level) {
          final isSelected = selectedExperienceLevel == level;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isLoading
                  ? null
                  : () {
                      setState(() {
                        selectedExperienceLevel = level;
                      });
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepPurple.withOpacity(0.10)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? Colors.deepPurple : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        level,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: const Color(0xFF2D2438),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildInterestsStep() {
    return buildStepShell(
      icon: Icons.favorite_border,
      title: 'Hangi alanlar ilgini çekiyor?',
      subtitle:
          'Birden fazla alan seçebilirsin. Bunları ana sayfa deneyimini kişiselleştirmek için kullanacağız.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: interestOptions.map((interest) {
          final isSelected = selectedInterests.contains(interest);

          return FilterChip(
            label: Text(interest),
            selected: isSelected,
            onSelected: isLoading
                ? null
                : (selected) {
                    setState(() {
                      if (selected) {
                        selectedInterests.add(interest);
                      } else {
                        selectedInterests.remove(interest);
                      }
                    });
                  },
            selectedColor: Colors.deepPurple.shade100,
            checkmarkColor: Colors.deepPurple,
            labelStyle: TextStyle(
              color: isSelected ? Colors.deepPurple.shade800 : Colors.black87,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildIntentionStep() {
    return buildStepShell(
      icon: Icons.edit_note_outlined,
      title: 'BagnuTheta’ya hangi niyetle katılıyorsun?',
      subtitle:
          'Kendini geliştirmek istediğin alanı veya beklentini kısaca yazabilirsin.',
      child: CustomTextField(
        label: 'Katılma amacın',
        controller: intentionController,
        prefixIcon: Icons.self_improvement_outlined,
        hintText: 'Örn: Kendimi tanımak ve içsel denge kurmak istiyorum.',
        maxLines: 5,
      ),
    );
  }

  Widget buildBottomNavigation() {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Geri'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isLastStep ? 'Profili Tamamla' : 'Devam Et',
              isLoading: isLoading,
              icon: isLastStep ? Icons.check_circle_outline : Icons.arrow_forward,
              onPressed: nextStep,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    birthDateController.dispose();
    cityController.dispose();
    intentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Seni Biraz Tanıyalım'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Adım ${currentStep + 1}/$totalSteps',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2438),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isLoading ? null : saveProfileOnboarding,
                      child: const Text('Atla'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: Colors.deepPurple.withOpacity(0.10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              children: [
                buildBirthDateStep(),
                buildCityStep(),
                buildExperienceStep(),
                buildInterestsStep(),
                buildIntentionStep(),
              ],
            ),
          ),
          buildBottomNavigation(),
        ],
      ),
    );
  }
}