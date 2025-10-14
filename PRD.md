# Product Requirements Document (PRD)
## Neves Capital - Design System

### 📋 **Visão Geral**

Este documento define as diretrizes e padrões para o Design System da aplicação Neves Capital, garantindo consistência visual, funcional e de desenvolvimento em todo o projeto.

---

## 🎨 **Design System**

### **1. Componentes Base**

#### **1.1 CustomButton**
- **Localização**: `lib/shared/components/custom_button.dart`
- **Uso**: Botões padronizados em toda a aplicação
- **Propriedades**:
  - `text`: Texto do botão
  - `onPressed`: Callback de ação
  - `isLoading`: Estado de carregamento
  - `isOutlined`: Estilo outlined
  - `backgroundColor`: Cor de fundo
  - `textColor`: Cor do texto
  - `width/height`: Dimensões
  - `icon`: Ícone opcional

#### **1.2 CustomTextField**
- **Localização**: `lib/shared/components/custom_text_field.dart`
- **Uso**: Campos de texto padronizados
- **Propriedades**:
  - `label`: Label do campo
  - `controller`: Controller do campo
  - `validator`: Função de validação
  - `keyboardType`: Tipo de teclado
  - `obscureText`: Texto oculto
  - `prefixIcon/suffixIcon`: Ícones
  - `maxLines`: Número de linhas
  - `enabled`: Habilitado/desabilitado

#### **1.3 CustomCard**
- **Localização**: `lib/shared/components/custom_card.dart`
- **Uso**: Cards e containers padronizados
- **Tipos**:
  - `CustomCard`: Card genérico
  - `InvestmentCard`: Card específico para investimentos

#### **1.4 CustomCarousel**
- **Localização**: `lib/shared/components/custom_carousel.dart`
- **Uso**: Carrosséis e sliders
- **Propriedades**:
  - `children`: Lista de widgets
  - `height/width`: Dimensões
  - `autoPlay`: Reprodução automática
  - `showIndicators`: Mostrar indicadores
  - `onPageChanged`: Callback de mudança

#### **1.5 CustomLoading**
- **Localização**: `lib/shared/components/custom_loading.dart`
- **Uso**: Estados de carregamento
- **Tipos**:
  - `CustomLoading`: Loading simples
  - `LoadingOverlay`: Overlay de loading
  - `SkeletonLoading`: Loading esqueleto
  - `SkeletonList`: Lista de skeleton

#### **1.6 CustomModal**
- **Localização**: `lib/shared/components/custom_modal.dart`
- **Uso**: Modais e diálogos
- **Tipos**:
  - `CustomModal`: Modal genérico
  - `ConfirmationModal`: Modal de confirmação
  - `InfoModal`: Modal de informações
  - `CustomBottomSheet`: Bottom sheet

---

## 🎯 **Diretrizes de Uso**

### **2.1 Quando Criar um Componente**

**✅ CRIE um componente quando:**
- O elemento será **reutilizado** em 2+ lugares
- Precisar de **comportamento específico** recorrente
- Quiser **padronizar** visual/UX
- Tiver **lógica complexa** que pode ser abstraída
- Precisar de **validação** específica

**❌ NÃO CRIE quando:**
- For uso **único** e específico
- O componente nativo do Flutter já atender
- For **muito simples** (ex: Container com padding)

### **2.2 Estrutura de Componentes**

```dart
// ✅ Estrutura recomendada
class CustomComponent extends StatelessWidget {
  // 1. Propriedades obrigatórias primeiro
  final String requiredProp;
  
  // 2. Propriedades opcionais
  final String? optionalProp;
  final VoidCallback? onPressed;
  
  // 3. Propriedades com valores padrão
  final bool isEnabled;
  final Color? backgroundColor;
  
  const CustomComponent({
    super.key,
    required this.requiredProp,
    this.optionalProp,
    this.onPressed,
    this.isEnabled = true,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    // Implementação
  }
}
```

### **2.3 Nomenclatura**

- **Componentes**: `Custom[Nome]` (ex: `CustomButton`)
- **Arquivos**: `custom_[nome].dart` (ex: `custom_button.dart`)
- **Propriedades**: `camelCase` (ex: `isLoading`)
- **Constantes**: `UPPER_SNAKE_CASE` (ex: `DEFAULT_HEIGHT`)

---

## 🎨 **Paleta de Cores**

### **3.1 Cores Primárias**
```dart
// Verde Neves Capital
static const Color primaryColor = Color(0xFF2E7D32);
static const Color secondaryColor = Color(0xFF4CAF50);
static const Color accentColor = Color(0xFF8BC34A);
static const Color neonGreen = Color(0xFF38e07b);
```

### **3.2 Cores de Fundo**
```dart
static const Color backgroundColor = Color(0xFF122118);
static const Color surfaceColor = Color(0xFFFFFFFF);
static const Color cardColor = Color(0xFFFFFFFF);
```

### **3.3 Cores de Texto**
```dart
static const Color textPrimary = Color(0xFF212121);
static const Color textSecondary = Color(0xFF757575);
static const Color textHint = Color(0xFFBDBDBD);
```

---

## 📐 **Espaçamentos e Dimensões**

### **4.1 Espaçamentos Padrão**
```dart
// Padding/Margin
const EdgeInsets paddingXS = EdgeInsets.all(4);
const EdgeInsets paddingSM = EdgeInsets.all(8);
const EdgeInsets paddingMD = EdgeInsets.all(16);
const EdgeInsets paddingLG = EdgeInsets.all(24);
const EdgeInsets paddingXL = EdgeInsets.all(32);

// Spacing entre elementos
const double spacingXS = 4;
const double spacingSM = 8;
const double spacingMD = 16;
const double spacingLG = 24;
const double spacingXL = 32;
```

### **4.2 Border Radius**
```dart
const double radiusSM = 4;
const double radiusMD = 8;
const double radiusLG = 12;
const double radiusXL = 16;
const double radiusRound = 25;
```

---

## 🔧 **Validações**

### **5.1 Validators Helper**
- **Localização**: `lib/shared/helpers/validators.dart`
- **Uso**: Validações padronizadas para formulários

```dart
// Exemplos de uso
validator: Validators.email,
validator: Validators.password,
validator: Validators.required,
validator: Validators.minLength(6),
validator: Validators.phone,
```

---

## 📱 **Responsividade**

### **6.1 Breakpoints**
```dart
// Mobile
const double mobileBreakpoint = 600;

// Tablet
const double tabletBreakpoint = 900;

// Desktop
const double desktopBreakpoint = 1200;
```

### **6.2 Layout Responsivo**
- Use `ConstrainedBox` para limitar largura máxima
- Implemente `SingleChildScrollView` para scroll
- Considere `MediaQuery` para adaptações

---

## 🚀 **Implementação**

### **7.1 Fluxo de Criação de Componentes**

1. **Identificar necessidade** de reutilização
2. **Criar componente** em `lib/shared/components/`
3. **Documentar** propriedades e uso
4. **Testar** em diferentes contextos
5. **Refatorar** telas existentes para usar o componente
6. **Atualizar** este PRD

### **7.2 Checklist de Componente**

- [ ] Nome descritivo e consistente
- [ ] Propriedades bem documentadas
- [ ] Valores padrão apropriados
- [ ] Suporte a temas (claro/escuro)
- [ ] Responsivo
- [ ] Acessível
- [ ] Testado

---

## 📚 **Exemplos de Uso**

### **8.1 Tela de Login (Refatorada)**
```dart
// ✅ Usando Design System
CustomTextField(
  label: 'E-mail',
  controller: _emailController,
  validator: Validators.email,
  keyboardType: TextInputType.emailAddress,
)

CustomButton(
  text: 'Entrar',
  onPressed: _handleLogin,
  isLoading: _isLoading,
  width: double.infinity,
)
```

### **8.2 Lista de Investimentos**
```dart
// ✅ Usando componentes do Design System
ListView.builder(
  itemBuilder: (context, index) {
    return InvestmentCard(
      title: investment.name,
      subtitle: investment.category,
      value: FormatHelpers.currency(investment.value),
      change: '${investment.return}%',
      isPositive: investment.return > 0,
      onTap: () => _navigateToDetails(investment),
    );
  },
)
```

---

## 🔄 **Manutenção**

### **9.1 Atualizações**
- **Componentes**: Atualize em `lib/shared/components/`
- **Documentação**: Mantenha este PRD atualizado
- **Refatoração**: Migre telas antigas para novos componentes

### **9.2 Versionamento**
- Use **semantic versioning** para mudanças
- **Breaking changes**: Documente e comunique
- **Deprecation**: Mantenha compatibilidade temporária

---

## 📋 **Checklist de Desenvolvimento**

### **10.1 Antes de Implementar**
- [ ] Verificar se componente já existe
- [ ] Analisar reutilização (mín. 2 lugares)
- [ ] Definir propriedades necessárias
- [ ] Considerar responsividade

### **10.2 Durante Implementação**
- [ ] Seguir padrões de nomenclatura
- [ ] Implementar validações
- [ ] Adicionar documentação
- [ ] Testar em diferentes contextos

### **10.3 Após Implementação**
- [ ] Refatorar telas existentes
- [ ] Atualizar documentação
- [ ] Validar consistência visual
- [ ] Testar acessibilidade

---

## 🎯 **Objetivos do Design System**

1. **Consistência**: Visual e funcional uniforme
2. **Produtividade**: Desenvolvimento mais rápido
3. **Manutenibilidade**: Mudanças centralizadas
4. **Qualidade**: Componentes testados e validados
5. **Escalabilidade**: Fácil adição de novos componentes
6. **Experiência**: UX consistente para o usuário

---

**Última atualização**: Dezembro 2024  
**Versão**: 1.0.0  
**Mantenedor**: Equipe de Desenvolvimento Neves Capital
