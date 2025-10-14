import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

/// Tipos de transação
enum TransactionType {
  @JsonValue('payment')
  payment,
  @JsonValue('transfer')
  transfer,
  @JsonValue('deposit')
  deposit,
  @JsonValue('withdrawal')
  withdrawal,
  @JsonValue('pix')
  pix,
  @JsonValue('boleto')
  boleto,
  @JsonValue('card')
  card,
}

/// Status da transação
enum TransactionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// Modelo de transação
@JsonSerializable()
class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? recipientName;
  final String? recipientDocument;
  final String? qrCode;
  final String? barcode;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.recipientName,
    this.recipientDocument,
    this.qrCode,
    this.barcode,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? recipientName,
    String? recipientDocument,
    String? qrCode,
    String? barcode,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      recipientName: recipientName ?? this.recipientName,
      recipientDocument: recipientDocument ?? this.recipientDocument,
      qrCode: qrCode ?? this.qrCode,
      barcode: barcode ?? this.barcode,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Retorna se a transação foi bem-sucedida
  bool get isSuccessful => status == TransactionStatus.completed;

  /// Retorna se a transação está pendente
  bool get isPending => status == TransactionStatus.pending;

  /// Retorna se a transação falhou
  bool get isFailed => status == TransactionStatus.failed;

  /// Retorna se a transação foi cancelada
  bool get isCancelled => status == TransactionStatus.cancelled;

  /// Retorna o valor formatado como moeda
  String get formattedAmount {
    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Retorna a data formatada
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Retorna a hora formatada
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
