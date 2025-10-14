# 🧪 Teste de Validação de CPF

## ✅ Correção Aplicada

### Problema:
A validação não estava sendo disparada quando o campo perdia o foco.

### Solução:
1. Adicionado `GlobalKey<FormFieldState>` para o campo
2. Modificado `_onFocusChanged()` para chamar `validate()` explicitamente
3. A validação agora é forçada quando o campo perde o foco

### Como testar:

#### 1. CPF Inválido - Todos os dígitos iguais:
```
Digite: 111.111.111-11
Clique fora do campo
Resultado esperado: ❌ "CPF inválido"
```

#### 2. CPF Inválido - Dígitos verificadores errados:
```
Digite: 123.456.789-00
Clique fora do campo
Resultado esperado: ❌ "CPF inválido"
```

#### 3. CPF Incompleto:
```
Digite: 123.456.789
Clique fora do campo
Resultado esperado: ❌ "CPF deve ter 11 dígitos"
```

#### 4. CPF Válido:
```
Digite: 111.444.777-35
Clique fora do campo
Resultado esperado: ✅ Sem erro
```

#### 5. CPF Válido:
```
Digite: 123.456.789-09
Clique fora do campo
Resultado esperado: ✅ Sem erro
```

### Fluxo de Validação:
```
1. Usuário digita CPF
   ↓ (apenas formatação automática)
2. Campo mostra: xxx.xxx.xxx-xx
   ↓ (sem validação ainda)
3. Usuário clica fora do campo
   ↓ (_focusNode.hasFocus = false)
4. _onFocusChanged() é chamado
   ↓ (_fieldKey.currentState?.validate())
5. _validateCpfOnFocusLost() é executado
   ↓ (_hasValidated = true)
6. CpfHelper.validateCpf() valida o CPF
   ↓
7. Se inválido: mostra erro
   Se válido: sem erro
```

### Código da Correção:
```dart
void _onFocusChanged() {
  if (!_focusNode.hasFocus) {
    // Campo perdeu o foco
    if (!_hasValidated) {
      _hasValidated = true;
    }
    
    widget.onFocusLost?.call();
    
    // Força a validação do campo específico
    if (mounted) {
      _fieldKey.currentState?.validate();  // ← Chama validação
    }
  }
}
```

### CPFs Válidos para Teste:
- `111.444.777-35` ✅
- `123.456.789-09` ✅
- `987.654.321-00` ✅
- `000.000.001-91` ✅

### CPFs Inválidos para Teste:
- `111.111.111-11` ❌ (todos iguais)
- `222.222.222-22` ❌ (todos iguais)
- `123.456.789-00` ❌ (dígitos verificadores errados)
- `123.456.789` ❌ (incompleto)
- `000.000.000-00` ❌ (todos zeros)

