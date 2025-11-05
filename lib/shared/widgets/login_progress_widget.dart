import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';

/// Widget para mostrar progresso granular do login
class LoginProgressWidget extends StatelessWidget {
  final LoginProgress progress;
  final String? errorMessage;

  const LoginProgressWidget({
    Key? key,
    required this.progress,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicador de progresso
        _buildProgressIndicator(),
        const SizedBox(height: 16),
        
        // Mensagem de status
        _buildStatusMessage(),
        
        // Mensagem de erro se houver
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 200,
      height: 4,
      child: LinearProgressIndicator(
        value: _getProgressValue(),
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          _getProgressColor(),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Text(
      _getStatusMessage(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[300],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getProgressValue() {
    switch (progress) {
      case LoginProgress.idle:
        return 0.0;
      case LoginProgress.searchingUser:
        return 0.3;
      case LoginProgress.authenticating:
        return 0.7;
      case LoginProgress.success:
        return 1.0;
      case LoginProgress.error:
        return 0.0;
    }
  }

  Color _getProgressColor() {
    switch (progress) {
      case LoginProgress.idle:
        return Colors.grey;
      case LoginProgress.searchingUser:
        return Colors.blue;
      case LoginProgress.authenticating:
        return Colors.orange;
      case LoginProgress.success:
        return Colors.green;
      case LoginProgress.error:
        return Colors.red;
    }
  }

  String _getStatusMessage() {
    switch (progress) {
      case LoginProgress.idle:
        return 'Pronto para fazer login';
      case LoginProgress.searchingUser:
        return 'Buscando usuário...';
      case LoginProgress.authenticating:
        return 'Autenticando...';
      case LoginProgress.success:
        return 'Login realizado com sucesso!';
      case LoginProgress.error:
        return 'Erro no login';
    }
  }
}
