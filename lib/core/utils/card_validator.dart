/// Utilitário para validação de número de cartão de crédito.
class CardValidator {
  CardValidator._();

  /// Valida o número do cartão usando o algoritmo de Luhn (mod 10).
  ///
  /// O algoritmo funciona assim:
  /// 1. Da direita para a esquerda, dobra cada segundo dígito
  /// 2. Se o dobro for > 9, subtrai 9
  /// 3. Soma todos os dígitos
  /// 4. Se o total for divisível por 10, o número é válido
  ///
  /// Aceita o número com ou sem espaços/hífens.
  /// Retorna `true` se o número for válido.
  static bool isValidLuhn(String cardNumber) {
    // Remove espaços e hífens
    final digits = cardNumber.replaceAll(RegExp(r'[\s\-]'), '');

    // Deve conter apenas dígitos
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;

    // Mínimo de 13 dígitos (alguns cartões), máximo 19
    if (digits.length < 13 || digits.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    // Percorre da direita para a esquerda
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}
