/// Modelo para respostas da API
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int? statusCode;
  
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
  });
  
  /// Cria uma resposta de sucesso
  factory ApiResponse.success({
    required T data,
    String message = 'Sucesso',
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }
  
  /// Cria uma resposta de erro
  factory ApiResponse.error({
    required String message,
    String? error,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode,
    );
  }
  
  /// Cria a partir de JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      statusCode: json['status_code'] as int?,
    );
  }
  
  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
      'status_code': statusCode,
    };
  }
  
  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, error: $error, statusCode: $statusCode)';
  }
}
