import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Tela para alterar dados da loja (Nome e Ramo)
/// Conforme wireframe fornecido
class EditStoreDataScreen extends StatefulWidget {
  final AuthController authController;

  const EditStoreDataScreen({
    super.key,
    required this.authController,
  });

  @override
  State<EditStoreDataScreen> createState() => _EditStoreDataScreenState();
}

class _EditStoreDataScreenState extends State<EditStoreDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _userId;
  String? _selectedBusinessType;

  // Lista de ramos de atividade (mesma do payment_step1_screen)
  final List<Map<String, String>> _businessTypes = [
    {'value': 'varejo', 'label': 'Varejo'},
    {'value': 'atacado', 'label': 'Atacado'},
    {'value': 'servicos', 'label': 'Serviços'},
    {'value': 'restaurante', 'label': 'Restaurante'},
    {'value': 'farmacia', 'label': 'Farmácia'},
    {'value': 'posto', 'label': 'Posto de Combustível'},
    {'value': 'outros', 'label': 'Outros'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  /// Carregar dados da loja do PostgreSQL
  Future<void> _loadStoreData() async {
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

      // 2. Buscar dados da loja
      final storeData = await DatabaseService.getStoreData(_userId!);
      
      if (storeData != null) {
        setState(() {
          _storeNameController.text = storeData['store_name'] ?? '';
          _selectedBusinessType = storeData['business_type'];
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar dados da loja', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
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

  /// Salvar dados da loja
  Future<void> _saveStoreData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBusinessType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o ramo de atividade'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await DatabaseService.saveStoreData(
        userId: _userId!,
        storeName: _storeNameController.text.trim(),
        businessType: _selectedBusinessType!,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados da loja salvos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Altere seus dados cadastrais:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      
                      // Nome da loja (read-only conforme wireframe)
                      TextFormField(
                        controller: _storeNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nome da Loja escolhido anteriormente',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome da loja é obrigatório';
                          }
                          if (value.trim().length < 3) {
                            return 'Nome deve ter pelo menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      
                      // Ramo de atividade (dropdown)
                      DropdownButtonFormField<String>(
                        value: _selectedBusinessType,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nome do Ramo escolhido',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                        ),
                        dropdownColor: const Color(0xFF1a2d21),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: _businessTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(
                              type['label']!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBusinessType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione o ramo de atividade';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40.0),
                      
                      // Botão CONFIRMAR
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveStoreData,
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
      ),
    );
  }
}

