/// Entidade de investimento no domínio
class Investment {
  final String id;
  final String name;
  final String description;
  final double value;
  final double expectedReturn;
  final double riskLevel;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  const Investment({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.expectedReturn,
    required this.riskLevel,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Investment && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'Investment(id: $id, name: $name, value: $value)';
  }
}
