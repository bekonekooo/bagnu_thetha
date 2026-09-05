import 'package:flutter/services.dart';

class FirstWordCapitalizationFormatter extends TextInputFormatter {
  const FirstWordCapitalizationFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    var firstLetterIndex = 0;
    while (firstLetterIndex < text.length &&
        text[firstLetterIndex].trim().isEmpty) {
      firstLetterIndex++;
    }

    if (firstLetterIndex >= text.length) return newValue;

    final firstLetter = text[firstLetterIndex];
    final capitalizedLetter = _capitalizeTurkishLetter(firstLetter);

    if (firstLetter == capitalizedLetter) return newValue;

    final capitalizedText = text.replaceRange(
      firstLetterIndex,
      firstLetterIndex + 1,
      capitalizedLetter,
    );

    return newValue.copyWith(
      text: capitalizedText,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }

  String _capitalizeTurkishLetter(String letter) {
    const turkishUppercase = <String, String>{
      'i': 'İ',
      'ı': 'I',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ç': 'Ç',
      'ö': 'Ö',
      'ü': 'Ü',
    };

    return turkishUppercase[letter] ?? letter.toUpperCase();
  }
}
