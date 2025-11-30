import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Tela para alterar chaves PIX cadastradas
/// Conforme wireframe fornecido
class EditPixKeysScreen extends StatefulWidget {
  const EditPixKeysScreen({super.key});

  @override
  State<EditPixKeysScreen> createState() => _EditPixKeysScreenState();
}

class _EditPixKeysScreenState extends State<EditPixKeysScreen> {
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _userId;
  List<Map<String, dynamic>> _pixKeys = [];
  final TextEditingController _newPixKeyController = TextEditingController();
  bool _showAddKeyField = false;

  @override
  void initState() {
    super.initState();
    _loadPixKeys();
  }

  @override
  void dispose() {
    _newPixKeyController.dispose();
    super.dispose();
  }

  /// Carregar chaves PIX do PostgreSQL
  Future<void> _loadPixKeys() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 1. Buscar CPF e userId
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      final userData = await DatabaseService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      _userId = userData['id'] as String;

      // 2. Buscar chaves PIX
      final pixKeys = await DatabaseService.getPixKeys(_userId!);
      
      setState(() {
        _pixKeys = pixKeys;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar chaves PIX', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar chaves: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  /// Adicionar nova chave PIX
  Future<void> _addPixKey() async {
    final pixKey = _newPixKeyController.text.trim();
    
    if (pixKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite a chave PIX'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await DatabaseService.addPixKey(
        userId: _userId!,
        pixKey: pixKey,
      );

      if (!mounted) return;

      if (success) {
        _newPixKeyController.clear();
        setState(() {
          _showAddKeyField = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chave PIX adicionada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPixKeys(); // Recarregar lista
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Remover chave PIX
  Future<void> _removePixKey(String keyId) async {
    // Confirmar remoção
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2d21),
        title: const Text('Remover chave PIX?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tem certeza que deseja remover esta chave PIX?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await DatabaseService.removePixKey(
        userId: _userId!,
        keyId: keyId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chave PIX removida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPixKeys(); // Recarregar lista
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Formatar chave PIX para exibição
  String _formatPixKey(Map<String, dynamic> key) {
    if (key['pix_key_formatted'] != null) {
      return key['pix_key_formatted'] as String;
    }
    return key['pix_key'] as String;
  }

  /// Obter label do tipo de chave
  String _getKeyTypeLabel(String? type) {
    switch (type) {
      case 'CPF':
        return 'CPF';
      case 'EMAIL':
        return 'Email';
      case 'PHONE':
        return 'Telefone';
      case 'RANDOM':
        return 'Chave Aleatória';
      default:
        return 'PIX';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Voltar para Vendas',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Altere as chaves pix cadastradas:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    
                    // Lista de chaves PIX existentes
                    if (_pixKeys.isNotEmpty) ...[
                      ...List.generate(_pixKeys.length, (index) {
                        final key = _pixKeys[index];
                        final isPrimary = key['is_primary'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              // Mostrar opções (editar/remover)
                              _showKeyOptions(key);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPrimary 
                                      ? const Color(0xFF22C55E) 
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: isPrimary ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chave PIX ${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatPixKey(key),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (isPrimary) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Principal',
                                              style: TextStyle(
                                                color: Color(0xFF22C55E),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12.0),
                    ],
                    
                    // Campo para adicionar nova chave (se mostrar)
                    if (_showAddKeyField) ...[
                      TextField(
                        controller: _newPixKeyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Digite a nova chave PIX',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check, color: Color(0xFF22C55E)),
                            onPressed: _isLoading ? null : _addPixKey,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addPixKey(),
                      ),
                      const SizedBox(height: 12.0),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAddKeyField = false;
                            _newPixKeyController.clear();
                          });
                        },
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ],
                    
                    // Botão para adicionar chave PIX
                    if (!_showAddKeyField && _pixKeys.length < 5) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAddKeyField = true;
                            });
                          },
                          icon: const Icon(Icons.add, color: Color(0xFF22C55E)),
                          label: const Text(
                            'Adicionar chave pix',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF22C55E), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ],
                    
                    if (_pixKeys.length >= 5)
                      Text(
                        'Limite máximo de 5 chaves PIX atingido',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    
                    const SizedBox(height: 40.0),
                    
                    // Botão CONFIRMAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: const Color(0xFF122118),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF122118)),
                                ),
                              )
                            : const Text(
                                'CONFIRMAR',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Mostrar opções para uma chave PIX
  void _showKeyOptions(Map<String, dynamic> key) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a2d21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatPixKey(key),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo: ${_getKeyTypeLabel(key['key_type'])}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            if (key['is_primary'] != true)
              ListTile(
                leading: const Icon(Icons.star, color: Color(0xFF22C55E)),
                title: const Text(
                  'Definir como principal',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar definir como principal
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidade em desenvolvimento'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Remover chave',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _removePixKey(key['id'] as String);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

