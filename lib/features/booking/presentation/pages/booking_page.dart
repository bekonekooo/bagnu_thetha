import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../sessions/data/services/session_service.dart';
import '../../data/services/availability_service.dart';

import '../widgets/booking_info_card.dart';
import '../widgets/booking_date_picker.dart';
import '../widgets/booking_time_selector.dart';
import '../widgets/booking_notes_field.dart';
import '../widgets/booking_submit_button.dart';

class BookingPage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final double sessionPrice;
  final String currency;

  const BookingPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.sessionPrice,
    required this.currency,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  String? selectedTime;

  bool isLoading = false;
  bool isLoadingTimes = false;

  final sessionService = SessionService();
  final availabilityService = AvailabilityService();
  final notesController = TextEditingController();

  List<String> availableTimes = [];
  RealtimeChannel? _sessionChannel;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  @override
  void dispose() {
    if (_sessionChannel != null) {
      sessionService.removeChannel(_sessionChannel!);
    }

    notesController.dispose();
    super.dispose();
  }

  String get formattedPrice {
    if (widget.sessionPrice <= 0) {
      return 'Ücret belirtilmemiş';
    }

    final cleanPrice = widget.sessionPrice % 1 == 0
        ? widget.sessionPrice.toInt().toString()
        : widget.sessionPrice.toStringAsFixed(2);

    if (widget.currency.toLowerCase() == 'try') {
      return '₺$cleanPrice';
    }

    return '$cleanPrice ${widget.currency.toUpperCase()}';
  }

  void _setupRealtime() {
    _sessionChannel = sessionService.subscribeToTeacherSessions(
      teacherId: widget.teacherId,
      onChange: () async {
        if (selectedDate == null) return;

        final previousSelectedTime = selectedTime;

        await fetchAvailableTimes(
          selectedDate!,
          showLoading: false,
          showErrorSnackBar: false,
        );

        if (!mounted) return;

        if (previousSelectedTime != null &&
            !availableTimes.contains(previousSelectedTime)) {
          setState(() {
            if (selectedTime == previousSelectedTime) {
              selectedTime = null;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Seçtiğin saat başka biri tarafından alındı. Lütfen yeni bir saat seç.',
              ),
            ),
          );
        }
      },
    );
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? combineDateAndTime(DateTime? date, String? time) {
    if (date == null || time == null) return null;

    final cleanDate = normalizeDate(date);

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

  bool isSlotInPast(DateTime date, String time) {
    final slotDateTime = combineDateAndTime(date, time);
    if (slotDateTime == null) return true;

    return slotDateTime.isBefore(DateTime.now());
  }

  String get formattedDate {
    if (selectedDate == null) {
      return 'Tarih seçilmedi';
    }

    final day = selectedDate!.day.toString().padLeft(2, '0');
    final month = selectedDate!.month.toString().padLeft(2, '0');
    final year = selectedDate!.year.toString();

    return '$day.$month.$year';
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      helpText: 'Seans tarihi seç',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
      selectedTime = null;
      availableTimes = [];
    });

    await fetchAvailableTimes(pickedDate);
  }

  Future<void> fetchAvailableTimes(
    DateTime date, {
    bool showLoading = true,
    bool showErrorSnackBar = true,
  }) async {
    if (showLoading) {
      setState(() {
        isLoadingTimes = true;
        availableTimes = [];
      });
    }

    try {
      final availabilityList =
          await availabilityService.fetchTeacherAvailability(
        teacherId: widget.teacherId,
        weekday: date.weekday,
      );

      final bookedTimes = await sessionService.fetchBookedTimes(
        teacherId: widget.teacherId,
        sessionDate: date,
      );

      final allAvailableTimes =
          availabilityList.map((item) => item.timeSlot).toList();

      final filteredTimes = allAvailableTimes
          .where((time) => !bookedTimes.contains(time))
          .toList();

      if (!mounted) return;

      setState(() {
        availableTimes = filteredTimes;

        if (selectedTime != null && !availableTimes.contains(selectedTime)) {
          selectedTime = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (showErrorSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saatler yüklenemedi: $e')),
        );
      }
    } finally {
      if (!mounted) return;

      if (showLoading) {
        setState(() {
          isLoadingTimes = false;
        });
      }
    }
  }

  Future<void> confirmBooking() async {
    if (isLoading) return;

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce tarih ve saat seç.'),
        ),
      );
      return;
    }

    if (widget.sessionPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu öğretmen için seans ücreti belirlenmemiş.'),
        ),
      );
      return;
    }

    final bookingDateTime = combineDateAndTime(selectedDate, selectedTime);

    if (bookingDateTime == null || bookingDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçmiş bir saat için seans oluşturamazsın.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await fetchAvailableTimes(
        selectedDate!,
        showLoading: false,
        showErrorSnackBar: false,
      );

      if (!mounted) return;

      if (selectedTime == null || !availableTimes.contains(selectedTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu saat az önce doldu. Lütfen başka bir saat seç.',
            ),
          ),
        );
        return;
      }

      final cleanNotes = notesController.text.trim();

      // PART 51'de bu noktaya Stripe ödeme eklenecek.
      // Şimdilik eski sistem bozulmasın diye seans direkt oluşturuluyor.
      await sessionService.createSession(
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        sessionDate: selectedDate!,
        sessionTime: selectedTime!,
        notes: cleanNotes.isEmpty ? null : cleanNotes,
      );

      if (!mounted) return;

      context.go(
        '/booking-success',
        extra: {
          'teacherName': widget.teacherName,
          'sessionDate': formattedDate,
          'sessionTime': selectedTime!,
          'notes': cleanNotes.isEmpty ? null : cleanNotes,
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seans oluşturulamadı: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildSectionTitle(String title, String subtitle) {
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
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget buildPaymentSummaryCard() {
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
                  'Ödenecek Tutar',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Stripe ödeme sistemi bir sonraki partta bağlanacak.',
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
            formattedPrice,
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

  @override
  Widget build(BuildContext context) {
    final canSubmit = selectedDate != null && selectedTime != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seans Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookingInfoCard(
              teacherName: widget.teacherName,
            ),

            const SizedBox(height: 16),

            buildPaymentSummaryCard(),

            const SizedBox(height: 26),

            buildSectionTitle(
              'Tarih seç',
              'Öğretmenin uygun olduğu günlerden bir tarih seç.',
            ),
            const SizedBox(height: 12),
            BookingDatePicker(
              formattedDate: formattedDate,
              onTap: pickDate,
            ),

            const SizedBox(height: 26),

            buildSectionTitle(
              'Saat seç',
              selectedDate == null
                  ? 'Saatleri görebilmek için önce tarih seçmelisin.'
                  : 'Müsait saatlerden birini seç.',
            ),
            const SizedBox(height: 12),
            BookingTimeSelector(
              selectedDate: selectedDate,
              selectedTime: selectedTime,
              isLoadingTimes: isLoadingTimes,
              availableTimes: availableTimes,
              isSlotInPast: isSlotInPast,
              onTimeSelected: (time) {
                setState(() {
                  selectedTime = time;
                });
              },
            ),

            const SizedBox(height: 26),

            BookingNotesField(
              controller: notesController,
            ),

            const SizedBox(height: 32),

            BookingSubmitButton(
              isLoading: isLoading,
              isEnabled: canSubmit,
              onPressed: confirmBooking,
            ),
          ],
        ),
      ),
    );
  }
}