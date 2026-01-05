import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/auth_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/features/auth/presentation/screens/personal_data_screen.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

/// Tela para alterar dados pessoais (Email, Telefone, Endereço)
/// Conforme wireframe fornecido
class EditPersonalDataScreen extends StatefulWidget {
  final AuthController authController;

  const EditPersonalDataScreen({
    super.key,
    required this.authController,
  });

  @override
  State<EditPersonalDataScreen> createState() => _EditPersonalDataScreenState();
}

class _EditPersonalDataScreenState extends State<EditPersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  Map<String, dynamic>? _userData;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Carregar dados do Firestore usando CPF (como no login)
  /// Os dados são guardados em _userData (variável de estado)
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      AppLogger.debug('Iniciando carregamento de dados do usuário...');

      // 1. Buscar CPF do SecureStorage (salvo após login)
      final cpf = await SecureStorageService.getLastCpf();
      
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      AppLogger.sensitive('CPF encontrado no SecureStorage', cpf);

      // 2. Buscar dados completos do Firestore usando CPF (como no login)
      AppLogger.debug('Buscando dados do Firestore usando CPF...');
      final userData = await FirestoreService.getUserByCpf(cpf);
      
      if (userData != null && userData['id'] != null) {
        // ✅ Encontrou dados - guardar em variável de estado
        setState(() {
          _userData = userData; // Guarda todos os dados (email, telefone, endereço)
          _userId = userData['id'] as String; // ID do documento Firestore
          
          // Preencher campos na tela
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        });
        
        AppLogger.info('Dados carregados e guardados em _userData');
        AppLogger.debug('Document ID presente: ${_userId != null}');
        AppLogger.debug('Dados carregados com sucesso');
      } else {
        throw Exception('Não foi possível carregar seus dados do banco de dados.');
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar dados', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// Navegar para edição de endereço
  Future<void> _navigateToAddressEdit() async {
    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: ID do usuário não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Buscar dados completos do endereço
    final addressData = _buildAddressData();

    // Navegar para a tela de endereço em modo de edição (pré-preenchida)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalDataScreen(
          loginData: {
            // Dados necessários para pré-preenchimento
            'email': _userData?['email'] ?? '',
            'password': '', // Não precisa
            'fullName': _userData?['full_name'] ?? '',
            'cpf': _userData?['cpf'] ?? '',
            'phone': _userData?['phone'] ?? '',
            // Endereço pré-preenchido
            ...addressData,
          },
          isEditMode: true, // Modo edição
          userId: _userId!,
        ),
      ),
    );

    // Se o usuário salvou o endereço, atualizar estado
    if (result == true && mounted) {
      await _loadUserData(); // Recarregar dados do Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endereço atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Construir texto de exibição do endereço
  String _buildAddressDisplayText() {
    if (_userData == null) return '';
    
    final street = _userData!['address']?['street'] ?? _userData!['street'] ?? _userData!['address'] ?? '';
    final number = _userData!['address']?['number'] ?? _userData!['number'] ?? '';
    final neighborhood = _userData!['address']?['neighborhood'] ?? _userData!['neighborhood'] ?? '';
    final city = _userData!['address']?['city'] ?? _userData!['city'] ?? '';
    
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (number.isNotEmpty) parts.add(number);
    if (neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

  /// Construir dados de endereço do estado atual
  Map<String, String> _buildAddressData() {
    return {
      'cep': _userData?['address']?['cep'] ?? _userData?['cep'] ?? '',
      'street': _userData?['address']?['street'] ?? _userData?['street'] ?? _userData?['address'] ?? '',
      'neighborhood': _userData?['address']?['neighborhood'] ?? _userData?['neighborhood'] ?? '',
      'city': _userData?['address']?['city'] ?? _userData?['city'] ?? '',
      'state': _userData?['address']?['state'] ?? _userData?['state'] ?? '',
      'number': _userData?['address']?['number'] ?? _userData?['number'] ?? '',
      'complement': _userData?['address']?['complement'] ?? _userData?['complement'] ?? '',
    };
  }

  /// Salvar alterações de email e telefone
  /// Fluxo conforme requisitos:
  /// 1. Buscar dados do usuário usando CPF (como no login)
  /// 2. Atualizar dados criptografados no Firestore
  /// 3. Se email mudou: atualizar email no Firebase Auth E deslogar usuário
  /// 4. Se email não mudou: atualizar apenas no Firestore
  /// 5. NÃO alterar o ID do usuário no Firebase
  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.debug('Iniciando atualização de dados...');
      
      // 1. Obter CPF do SecureStorage (necessário para buscar dados)
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }
      
      AppLogger.sensitive('CPF obtido', cpf);
      
      // 2. Buscar dados atuais do usuário usando CPF (como no login)
      AppLogger.debug('Buscando dados atuais do usuário usando CPF...');
      final userDataAtual = await FirestoreService.getUserByCpf(cpf);
      
      if (userDataAtual == null || userDataAtual['id'] == null) {
        throw Exception('Não foi possível encontrar seus dados. Tente novamente.');
      }
      
      final userIdFirestore = userDataAtual['id'] as String;
      final emailAtualFirestore = userDataAtual['email'] as String? ?? '';
      final telefoneAtualFirestore = userDataAtual['phone'] as String? ?? '';
      
      AppLogger.debug('Dados atuais carregados');
      AppLogger.debug('Document ID Firestore presente: ${userIdFirestore.isNotEmpty}');
      
      // 3. Obter valores dos campos editados
      final novoEmail = _emailController.text.trim();
      final novoTelefone = PhoneHelper.getPhoneNumbers(_phoneController.text);
      
      // 4. Verificar o que mudou
      final emailMudou = novoEmail != emailAtualFirestore && novoEmail.isNotEmpty;
      final telefoneMudou = novoTelefone != telefoneAtualFirestore && novoTelefone.isNotEmpty;
      
      AppLogger.debug('Verificando mudanças...');
      AppLogger.debug('Email mudou: $emailMudou');
      AppLogger.debug('Telefone mudou: $telefoneMudou');
      
      if (!emailMudou && !telefoneMudou) {
        // Se não houver alterações, apenas mostrar mensagem informativa e retornar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma alteração foi feita nos dados.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // CASO 1: Email NÃO mudou - Atualizar apenas telefone no Firestore
      if (!emailMudou && telefoneMudou) {
        AppLogger.debug('Email não mudou - Atualizando apenas telefone no Firestore');
        
        final success = await FirestoreService.updateUser(
          userId: userIdFirestore,
          phone: novoTelefone,
        );
        
        if (!success) {
          throw Exception('Erro ao atualizar telefone no servidor');
        }
        
        AppLogger.info('Telefone atualizado com sucesso no Firestore');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados atualizados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            await _loadUserData(); // Recarregar dados
          }
        }
        return;
      }
      
      // CASO 2: Email mudou - Atualizar no Firestore E no Firebase Auth, depois deslogar
      if (emailMudou) {
        AppLogger.debug('Email mudou - Iniciando atualização completa');
        
        // 2.1. Atualizar dados no Firestore (email criptografado + telefone se mudou)
        AppLogger.debug('Passo 1: Atualizando dados no Firestore');
        final successFirestore = await FirestoreService.updateUser(
          userId: userIdFirestore,
          email: novoEmail,
          phone: telefoneMudou ? novoTelefone : null,
        );
        
        if (!successFirestore) {
          throw Exception('Erro ao atualizar dados no Firestore');
        }
        
        AppLogger.info('Dados atualizados no Firestore');
        
        // 2.2. Atualizar email no Firebase Auth (NÃO altera o ID do usuário)
        AppLogger.debug('Passo 2: Atualizando email no Firebase Auth');
        bool firebaseUpdated = false;
        
        // Tentar atualizar diretamente primeiro (método mais rápido)
        try {
          await AuthService.updateEmail(novoEmail);
          AppLogger.info('Email atualizado no Firebase Auth via cliente (ID preservado)');
          firebaseUpdated = true;
        } catch (e) {
          AppLogger.warning('Erro ao atualizar email no Firebase Auth via cliente: $e');
          // Se falhar, continuar mesmo assim - o email já foi atualizado no Firestore
        }
        
        if (!firebaseUpdated) {
          AppLogger.warning('ATENÇÃO: Email atualizado no Firestore mas não no Firebase Auth');
          AppLogger.warning('O usuário precisará fazer login novamente');
        }
        
        // 2.3. Deslogar usuário para que ele faça login novamente com o novo email
        AppLogger.debug('Passo 3: Deslogando usuário para login com novo email');
        if (mounted) {
          // Mostrar mensagem informativa
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email atualizado! Você será deslogado para fazer login novamente.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Aguardar um pouco para o usuário ver a mensagem
          await Future.delayed(const Duration(seconds: 2));
          
          // Deslogar o usuário - isso vai fazer o AppWrapper mostrar automaticamente o OnboardingScreen
          await widget.authController.logout();
          
          // Voltar para o AppWrapper (que vai mostrar o OnboardingScreen automaticamente)
          if (mounted) {
            // Remover todas as rotas até chegar ao AppWrapper usando rootNavigator
            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
          }
        }
        return;
      }
    } catch (e) {
      AppLogger.error('Erro ao atualizar dados', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Dados Pessoais',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
            )
          : SafeArea(
              child: KeyboardDismissWrapper(
                child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            
                            // Título
                            const Text(
                              'Altere seus dados cadastrais:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Campo Email
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Email',
                              labelText: 'Email',
                              autofocus: true, // Focar automaticamente ao entrar na tela
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email é obrigatório';
                                }
                                if (!value.contains('@')) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Campo Telefone
                            PhoneInputField(
                              controller: _phoneController,
                              hintText: 'Digite seu telefone',
                              validator: PhoneHelper.validatePhone,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Campo Endereço (clicável)
                            GestureDetector(
                              onTap: _navigateToAddressEdit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[700]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[800],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF4ADE80),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Endereço',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _userData != null && 
                                            (_userData!['address'] != null || _userData!['street'] != null)
                                                ? _buildAddressDisplayText()
                                                : 'Clique para editar endereço',
                                            style: TextStyle(
                                              color: _userData != null && 
                                              (_userData!['address'] != null || _userData!['street'] != null)
                                                  ? Colors.white
                                                  : Colors.grey[500],
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Botão Confirmar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: const Color(0xFF122118),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF122118),
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'CONFIRMAR',
                                        style: TextStyle(
                                          fontSize: 18,
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
                ],
              ),
            ),
        ),
    );
  }
}

