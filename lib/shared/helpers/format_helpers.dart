import 'package:intl/intl.dart';

/// Classe com helpers para formatação de dados
class FormatHelpers {
  /// Formata valor monetário em reais
  static String currency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
  
  /// Formata percentual
  static String percentage(double value) {
    final formatter = NumberFormat.percentPattern('pt_BR');
    return formatter.format(value / 100);
  }
  
  /// Formata data
  static String date(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }
  
  /// Formata data e hora
  static String dateTime(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }
  
  /// Formata data relativa (ex: "há 2 dias")
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'há ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'agora';
    }
  }
  
  /// Formata número com separadores de milhares
  static String number(double value) {
    final formatter = NumberFormat('#,##0.00', 'pt_BR');
    return formatter.format(value);
  }
  
  /// Formata CPF
  static String cpf(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCpf.length != 11) return cpf;
    
    return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9)}';
  }
  
  /// Formata CNPJ
  static String cnpj(String cnpj) {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCnpj.length != 14) return cnpj;
    
    return '${cleanCnpj.substring(0, 2)}.${cleanCnpj.substring(2, 5)}.${cleanCnpj.substring(5, 8)}/${cleanCnpj.substring(8, 12)}-${cleanCnpj.substring(12)}';
  }
  
  /// Formata telefone
  static String phone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length == 11) {
      return '(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 7)}-${cleanPhone.substring(7)}';
    } else if (cleanPhone.length == 10) {
      return '(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 6)}-${cleanPhone.substring(6)}';
    }
    
    return phone;
  }
  
  /// Formata CEP
  static String cep(String cep) {
    final cleanCep = cep.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCep.length != 8) return cep;
    
    return '${cleanCep.substring(0, 5)}-${cleanCep.substring(5)}';
  }
}
