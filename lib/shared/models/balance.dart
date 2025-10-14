import 'package:json_annotation/json_annotation.dart';

part 'balance.g.dart';

/// Modelo de saldo da conta
@JsonSerializable()
class Balance {
  final double available;
  final double blocked;
  final double total;
  final String currency;
  final DateTime lastUpdated;

  const Balance({
    required this.available,
    required this.blocked,
    required this.total,
    this.currency = 'BRL',
    required this.lastUpdated,
  });

  factory Balance.fromJson(Map<String, dynamic> json) => _$BalanceFromJson(json);
  Map<String, dynamic> toJson() => _$BalanceToJson(this);

  Balance copyWith({
    double? available,
    double? blocked,
    double? total,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return Balance(
      available: available ?? this.available,
      blocked: blocked ?? this.blocked,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Retorna o saldo disponível formatado
  String get formattedAvailable {
    return 'R\$ ${available.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Retorna o saldo bloqueado formatado
  String get formattedBlocked {
    return 'R\$ ${blocked.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Retorna o saldo total formatado
  String get formattedTotal {
    return 'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Retorna se há saldo disponível
  bool get hasAvailableBalance => available > 0;

  /// Retorna se há saldo bloqueado
  bool get hasBlockedBalance => blocked > 0;

  /// Retorna se o saldo está zerado
  bool get isZero => total == 0;
}
