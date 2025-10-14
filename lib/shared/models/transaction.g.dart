// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      status: $enumDecode(_$TransactionStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      recipientName: json['recipientName'] as String?,
      recipientDocument: json['recipientDocument'] as String?,
      qrCode: json['qrCode'] as String?,
      barcode: json['barcode'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'recipientName': instance.recipientName,
      'recipientDocument': instance.recipientDocument,
      'qrCode': instance.qrCode,
      'barcode': instance.barcode,
      'metadata': instance.metadata,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.payment: 'payment',
  TransactionType.transfer: 'transfer',
  TransactionType.deposit: 'deposit',
  TransactionType.withdrawal: 'withdrawal',
  TransactionType.pix: 'pix',
  TransactionType.boleto: 'boleto',
  TransactionType.card: 'card',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.completed: 'completed',
  TransactionStatus.failed: 'failed',
  TransactionStatus.cancelled: 'cancelled',
};
