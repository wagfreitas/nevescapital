import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          'POLÍTICA DE PRIVACIDADE - PagPag\n\n'
          'Última atualização: Fevereiro de 2026\n\n'
          '1. INTRODUÇÃO\n\n'
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. A PagPag está comprometida com a proteção da privacidade e dos dados pessoais de seus usuários. Esta Política de Privacidade descreve como coletamos, usamos, armazenamos e protegemos suas informações pessoais.\n\n'
          '2. DADOS COLETADOS\n\n'
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Coletamos dados como nome completo, CPF, telefone, email, endereço, dados bancários e informações de transações.\n\n'
          '3. FINALIDADE DO TRATAMENTO\n\n'
          'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Utilizamos seus dados para processar transações, verificar identidade e cumprir obrigações legais.\n\n'
          '4. COMPARTILHAMENTO DE DADOS\n\n'
          'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Seus dados podem ser compartilhados com processadores de pagamento, instituições financeiras e autoridades regulatórias quando exigido por lei.\n\n'
          '5. ARMAZENAMENTO E SEGURANÇA\n\n'
          'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit. Utilizamos criptografia de ponta a ponta, armazenamento seguro e práticas recomendadas de segurança da informação para proteger seus dados pessoais.\n\n'
          '6. DIREITOS DO TITULAR\n\n'
          'Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam. Conforme a LGPD (Lei Geral de Proteção de Dados), você tem direito a acessar, corrigir, excluir e portar seus dados pessoais, bem como revogar o consentimento a qualquer momento.\n\n'
          '7. COOKIES E TECNOLOGIAS DE RASTREAMENTO\n\n'
          'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.\n\n'
          '8. RETENÇÃO DE DADOS\n\n'
          'Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus. Seus dados serão retidos pelo período necessário para cumprir as finalidades descritas nesta política.\n\n'
          '9. ALTERAÇÕES NESTA POLÍTICA\n\n'
          'Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Reservamo-nos o direito de alterar esta política a qualquer momento, notificando os usuários sobre mudanças significativas.\n\n'
          '10. CONTATO DO ENCARREGADO (DPO)\n\n'
          'Para exercer seus direitos ou esclarecer dúvidas sobre o tratamento de dados pessoais, entre em contato com nosso Encarregado de Proteção de Dados pelo email: privacidade@pagpag.com.br\n',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
