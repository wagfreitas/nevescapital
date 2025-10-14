// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Balance _$BalanceFromJson(Map<String, dynamic> json) => Balance(
      available: (json['available'] as num).toDouble(),
      blocked: (json['blocked'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'BRL',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$BalanceToJson(Balance instance) => <String, dynamic>{
      'available': instance.available,
      'blocked': instance.blocked,
      'total': instance.total,
      'currency': instance.currency,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
