import 'package:flutter/services.dart';

/// Máscara `dd/mm/aaaa` com validação progressiva para só aceitar dígitos
/// que podem formar uma data válida (incl. 29/02 em ano bissexto ao completar).
class BrazilDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    var take = 0;
    for (var i = 0; i < digits.length && i < 8; i++) {
      final partial = digits.substring(0, i + 1);
      if (!_canAppendDigit(partial)) {
        break;
      }
      take = i + 1;
    }

    if (take == 0) {
      return oldValue;
    }

    final d = digits.substring(0, take);
    final formatted = _withSlashes(d);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _withSlashes(String d) {
    if (d.length <= 2) return d;
    if (d.length <= 4) {
      return '${d.substring(0, 2)}/${d.substring(2)}';
    }
    return '${d.substring(0, 2)}/${d.substring(2, 4)}/${d.substring(4)}';
  }

  /// `partial` = apenas dígitos, 1 a 8 caracteres (ddmmyyyy).
  static bool _canAppendDigit(String partial) {
    final len = partial.length;
    if (len == 0) return true;

    // Dia
    if (len >= 1) {
      final c0 = partial[0];
      if (c0.compareTo('0') < 0 || c0.compareTo('3') > 0) return false;
    }
    if (len >= 2) {
      final day = int.tryParse(partial.substring(0, 2));
      if (day == null || day < 1 || day > 31) return false;
    }

    // Mês
    if (len >= 3) {
      final c2 = partial[2];
      if (c2 != '0' && c2 != '1') return false;
    }
    if (len >= 4) {
      final month = int.tryParse(partial.substring(2, 4));
      if (month == null || month < 1 || month > 12) return false;
    }

    // Ano (1900–2100), progressivo
    if (len >= 5) {
      final c4 = partial[4];
      if (c4 != '1' && c4 != '2') return false;
    }
    if (len >= 6) {
      final c4 = partial[4];
      final c5 = partial[5];
      if (c4 == '1' && c5 != '9') return false;
      if (c4 == '2' && c5 != '0' && c5 != '1') return false;
    }
    if (len >= 7) {
      final y3 = partial.substring(4, 7);
      final okPrefix = RegExp(
        r'^(19[0-9]|20[0-9]|210)$',
      ).hasMatch(y3);
      if (!okPrefix) return false;
    }
    if (len >= 8) {
      final year = int.tryParse(partial.substring(4, 8));
      if (year == null || year < 1900 || year > 2100) return false;
      final day = int.parse(partial.substring(0, 2));
      final month = int.parse(partial.substring(2, 4));
      try {
        final dt = DateTime(year, month, day);
        if (dt.year != year || dt.month != month || dt.day != day) {
          return false;
        }
      } catch (_) {
        return false;
      }
    }

    return true;
  }
}

/// Parse `dd/mm/aaaa` com validação de calendário (29/02, etc.).
DateTime? parseBrazilDate(String dateStr) {
  try {
    final parts = dateStr.split('/');
    if (parts.length != 3) return null;
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    final d = DateTime(year, month, day);
    if (d.year != year || d.month != month || d.day != day) {
      return null;
    }
    return d;
  } catch (_) {
    return null;
  }
}
