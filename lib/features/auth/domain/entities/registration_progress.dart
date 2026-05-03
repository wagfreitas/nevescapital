/// Entidade para rastrear o progresso do cadastro do usuário
///
/// Permite retomar o cadastro de onde o usuário parou caso ele abandone o processo
class RegistrationProgress {
  final String cpf;
  final String
      currentStep; // 'phone', 'otp', 'email', 'personal1', 'address', 'personal2', 'selfie', 'document', 'completed'
  final RegistrationStatus status; // 'in_progress', 'abandoned', 'completed'
  final DateTime lastUpdated;

  // Dados já coletados (parciais)
  final String? phone;
  final String? email;
  final String? fullName;
  final DateTime? birthDate;
  final String? motherName;
  final bool? isPep;
  final String? occupation;
  final String? incomeRange;
  final String? selfiePath;
  final String? documentFrontPath;
  final String? documentBackPath;
  final String? documentType; // 'RG', 'CNH', 'RNE'
  // Dados de endereço
  final String? cep;
  final String? street; // logradouro
  final String? number;
  final String? complement;
  final String? neighborhood; // bairro
  final String? city; // cidade
  final String? state; // UF

  RegistrationProgress({
    required this.cpf,
    required this.currentStep,
    required this.status,
    required this.lastUpdated,
    this.phone,
    this.email,
    this.fullName,
    this.birthDate,
    this.motherName,
    this.isPep,
    this.occupation,
    this.incomeRange,
    this.selfiePath,
    this.documentFrontPath,
    this.documentBackPath,
    this.documentType,
    this.cep,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
  });

  /// Converte de Map (Firestore) para entidade
  factory RegistrationProgress.fromMap(Map<String, dynamic> map) {
    return RegistrationProgress(
      cpf: map['cpf'] as String,
      currentStep: map['currentStep'] as String,
      status: RegistrationStatus.values.firstWhere(
        (e) => e.toString() == 'RegistrationStatus.${map['status']}',
        orElse: () => RegistrationStatus.inProgress,
      ),
      lastUpdated: (map['lastUpdated'] as DateTime?) ?? DateTime.now(),
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      fullName: map['fullName'] as String?,
      birthDate: map['birthDate'] as DateTime?,
      motherName: map['motherName'] as String?,
      isPep: map['isPep'] as bool?,
      occupation: map['occupation'] as String?,
      incomeRange: map['incomeRange'] as String?,
      selfiePath: map['selfiePath'] as String?,
      documentFrontPath: map['documentFrontPath'] as String?,
      documentBackPath: map['documentBackPath'] as String?,
      documentType: map['documentType'] as String?,
      cep: map['cep'] as String?,
      street: map['street'] as String?,
      number: map['number'] as String?,
      complement: map['complement'] as String?,
      neighborhood: map['neighborhood'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
    );
  }

  /// Converte entidade para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'cpf': cpf,
      'currentStep': currentStep,
      'status': status.toString().split('.').last,
      'lastUpdated': lastUpdated,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (fullName != null) 'fullName': fullName,
      if (birthDate != null) 'birthDate': birthDate,
      if (motherName != null) 'motherName': motherName,
      if (isPep != null) 'isPep': isPep,
      if (occupation != null) 'occupation': occupation,
      if (incomeRange != null) 'incomeRange': incomeRange,
      if (selfiePath != null) 'selfiePath': selfiePath,
      if (documentFrontPath != null) 'documentFrontPath': documentFrontPath,
      if (documentBackPath != null) 'documentBackPath': documentBackPath,
      if (documentType != null) 'documentType': documentType,
      if (cep != null) 'cep': cep,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
    };
  }

  /// Converte entidade para JSON (armazenamento local)
  /// DateTime são convertidos para String ISO 8601
  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'currentStep': currentStep,
      'status': status.toString().split('.').last,
      'lastUpdated': lastUpdated.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (fullName != null) 'fullName': fullName,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      if (motherName != null) 'motherName': motherName,
      if (isPep != null) 'isPep': isPep,
      if (occupation != null) 'occupation': occupation,
      if (incomeRange != null) 'incomeRange': incomeRange,
      if (selfiePath != null) 'selfiePath': selfiePath,
      if (documentFrontPath != null) 'documentFrontPath': documentFrontPath,
      if (documentBackPath != null) 'documentBackPath': documentBackPath,
      if (documentType != null) 'documentType': documentType,
      if (cep != null) 'cep': cep,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
    };
  }

  /// Converte de JSON (armazenamento local) para entidade
  /// Strings ISO 8601 são convertidas para DateTime
  factory RegistrationProgress.fromJson(Map<String, dynamic> json) {
    return RegistrationProgress(
      cpf: json['cpf'] as String,
      currentStep: json['currentStep'] as String,
      status: RegistrationStatus.values.firstWhere(
        (e) => e.toString() == 'RegistrationStatus.${json['status']}',
        orElse: () => RegistrationStatus.inProgress,
      ),
      lastUpdated: json['lastUpdated'] is String
          ? DateTime.parse(json['lastUpdated'] as String)
          : json['lastUpdated'] as DateTime,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] is String
              ? DateTime.parse(json['birthDate'] as String)
              : json['birthDate'] as DateTime)
          : null,
      motherName: json['motherName'] as String?,
      isPep: json['isPep'] as bool?,
      occupation: json['occupation'] as String?,
      incomeRange: json['incomeRange'] as String?,
      selfiePath: json['selfiePath'] as String?,
      documentFrontPath: json['documentFrontPath'] as String?,
      documentBackPath: json['documentBackPath'] as String?,
      documentType: json['documentType'] as String?,
      cep: json['cep'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }

  /// Cria cópia com campos atualizados
  RegistrationProgress copyWith({
    String? currentStep,
    RegistrationStatus? status,
    DateTime? lastUpdated,
    String? phone,
    String? email,
    String? fullName,
    DateTime? birthDate,
    String? motherName,
    bool? isPep,
    String? occupation,
    String? incomeRange,
    String? selfiePath,
    String? documentFrontPath,
    String? documentBackPath,
    String? documentType,
    String? cep,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
  }) {
    return RegistrationProgress(
      cpf: cpf,
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      motherName: motherName ?? this.motherName,
      isPep: isPep ?? this.isPep,
      occupation: occupation ?? this.occupation,
      incomeRange: incomeRange ?? this.incomeRange,
      selfiePath: selfiePath ?? this.selfiePath,
      documentFrontPath: documentFrontPath ?? this.documentFrontPath,
      documentBackPath: documentBackPath ?? this.documentBackPath,
      documentType: documentType ?? this.documentType,
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  /// Verifica se o cadastro está completo
  bool get isComplete =>
      currentStep == 'completed' && status == RegistrationStatus.completed;

  /// Verifica se foi abandonado há mais de 30 dias
  bool get isStale => DateTime.now().difference(lastUpdated).inDays > 30;

  static const List<String> _stepOrder = [
    'phone', 'otp', 'email', 'personal1', 'address', 'personal2',
    'selfie', 'document', 'completed',
  ];

  /// Retorna o step mais avançado entre [a] e [b].
  static String furthestStep(String a, String b) {
    final ia = _stepOrder.indexOf(a);
    final ib = _stepOrder.indexOf(b);
    return (ia >= ib) ? a : b;
  }
}

/// Status do cadastro
enum RegistrationStatus {
  inProgress, // Cadastro em andamento
  abandoned, // Usuário saiu sem completar
  completed, // Cadastro finalizado
}
