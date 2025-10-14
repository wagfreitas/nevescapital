/// Entidade de usuário no domínio
class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name)';
  }
}
