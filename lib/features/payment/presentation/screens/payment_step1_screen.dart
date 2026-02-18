import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import '../helpers/payment_step_helper.dart';
import 'payment_step2_screen.dart';

/// Tela 1: Inserir nome do estabelecimento e ramo de atuação
/// Só aparece se o usuário ainda não tiver estabelecimento e ramo definidos
class PaymentStep1Screen extends StatefulWidget {
  const PaymentStep1Screen({super.key});

  @override
  State<PaymentStep1Screen> createState() => _PaymentStep1ScreenState();
}

class _PaymentStep1ScreenState extends State<PaymentStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeEstabelecimentoController = TextEditingController();
  String? _ramoAtuacao;
  bool _isLoading = true;
  bool _shouldShowScreen = false;

  // Lista de ramos de atividade (igual à tela Dados da Loja)
  final List<Map<String, String>> _businessTypes = [
    {'value': 'alimentos_bebidas_vr', 'label': 'Alimentos e Bebidas (Aceita VR)'},
    {'value': 'acougues_peixarias_va', 'label': 'Açougues e Peixarias (Aceita VA)'},
    {'value': 'beleza_cuidados', 'label': 'Beleza e Cuidados Pessoais'},
    {'value': 'construcao_reparos', 'label': 'Construção e Reparos'},
    {'value': 'lazer_eventos', 'label': 'Lazer e Eventos'},
    {'value': 'moda_acessorios', 'label': 'Moda e Acessórios'},
    {'value': 'petshop_veterinario', 'label': 'Petshop e Veterinário'},
    {'value': 'saude_bem_estar', 'label': 'Saúde e Bem-Estar'},
    {'value': 'servicos_gerais', 'label': 'Serviços Gerais'},
    {'value': 'tecnologia_informatica', 'label': 'Tecnologia e Informática'},
    {'value': 'transporte_entregas', 'label': 'Transporte e Entregas'},
    {'value': 'outros_produtos_servicos', 'label': 'Outros Produtos e Serviços'},
  ];

  @override
  void initState() {
    super.initState();
    _checkIfShouldShowScreen();
  }

  @override
  void dispose() {
    _nomeEstabelecimentoController.dispose();
    super.dispose();
  }

  /// Verificar se o usuário já tem estabelecimento e ramo definidos
  Future<void> _checkIfShouldShowScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar CPF do SecureStorage
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        AppLogger.warning('CPF não encontrado - mostrando tela de estabelecimento');
        setState(() {
          _shouldShowScreen = true;
          _isLoading = false;
        });
        return;
      }

      // Buscar dados do usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      
      if (userData == null) {
        AppLogger.warning('Usuário não encontrado - mostrando tela de estabelecimento');
        setState(() {
          _shouldShowScreen = true;
          _isLoading = false;
        });
        return;
      }

      // Verificar se já tem estabelecimento e ramo
      final storeName = userData['storeName'] as String?;
      final businessType = userData['businessType'] as String?;

      final hasStoreData = storeName != null && 
                          storeName.isNotEmpty && 
                          businessType != null && 
                          businessType.isNotEmpty;

      AppLogger.debug('Dados da loja encontrados: storeName=${storeName != null}, businessType=${businessType != null}');

      if (hasStoreData) {
        // Usuário já tem estabelecimento e ramo - pular para step 2
        AppLogger.info('Usuário já tem estabelecimento e ramo - pulando para step 2');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentStep2Screen(
                nomeEstabelecimento: storeName,
                ramoAtuacao: businessType,
              ),
            ),
          );
        }
      } else {
        // Usuário não tem estabelecimento e ramo - mostrar tela
        AppLogger.info('Usuário não tem estabelecimento e ramo - mostrando tela');
        setState(() {
          _shouldShowScreen = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar dados do estabelecimento', e);
      // Em caso de erro, mostrar a tela para o usuário preencher
      setState(() {
        _shouldShowScreen = true;
        _isLoading = false;
      });
    }
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      // Salvar dados do estabelecimento no Firestore antes de continuar
      _saveStoreDataAndContinue();
    }
  }

  /// Salvar dados do estabelecimento e continuar para próxima tela
  Future<void> _saveStoreDataAndContinue() async {
    try {
      // Buscar CPF e userId
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      final userId = userData['id'] as String;

      // Salvar dados do estabelecimento
      final success = await FirestoreService.updateUser(
        userId: userId,
        storeName: _nomeEstabelecimentoController.text.trim(),
        businessType: _ramoAtuacao ?? '',
      );

      if (!success) {
        throw Exception('Erro ao salvar dados do estabelecimento');
      }

      AppLogger.info('Dados do estabelecimento salvos com sucesso');

      // Continuar para próxima tela
      // Marcar como primeira venda para que a numeração dos passos seja correta (2/5)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStep2Screen(
              nomeEstabelecimento: _nomeEstabelecimentoController.text.trim(),
              ramoAtuacao: _ramoAtuacao ?? '',
              isFirstSale: true, // Indica que é a primeira venda
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar dados do estabelecimento', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto verifica se deve mostrar a tela
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    // Se não deve mostrar a tela, não renderizar nada (já foi redirecionado)
    if (!_shouldShowScreen) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  const Center(
                    child: Text(
                      'Dados da Loja',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Indicador de progresso (abaixo do título)
                  // Esta tela só aparece se o usuário não tem conta, então sempre é passo 1 de 5
                  PaymentStepHelper.buildProgressIndicator(1, 5),
                  const SizedBox(height: 32),

                  // Campo de nome do estabelecimento
                  TextFormField(
                    controller: _nomeEstabelecimentoController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome do Estabelecimento',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: AppTheme.inputEditableBackgroundColor,
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
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do estabelecimento';
                      }
                      if (value.length < 3) {
                        return 'Nome deve ter pelo menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo de ramo de atuação (dropdown) - igual à tela Dados da Loja
                  DropdownButtonFormField<String>(
                    initialValue: _ramoAtuacao,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Ramos de Atuação',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: AppTheme.inputEditableBackgroundColor,
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
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
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
                        _ramoAtuacao = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecione o ramo de atuação';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Botão Avançar
                  CustomButton(
                    text: 'Avançar',
                    onPressed: _continuar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
