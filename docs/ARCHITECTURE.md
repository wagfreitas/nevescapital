# Arquitetura do Projeto - Neves Capital

Este projeto segue os princípios da **Clean Architecture** para garantir uma estrutura organizada, testável e manutenível.

## Estrutura de Pastas

```
lib/
├── core/                           # Camada central (regras de negócio)
│   ├── constants/                  # Constantes da aplicação
│   ├── errors/                     # Definições de erros
│   ├── network/                    # Configurações de rede
│   ├── theme/                      # Tema da aplicação
│   └── utils/                      # Utilitários gerais
├── features/                       # Módulos da aplicação
│   ├── auth/                       # Módulo de autenticação
│   │   ├── data/                   # Camada de dados
│   │   │   ├── datasources/        # Fontes de dados (API, Local)
│   │   │   ├── models/             # Modelos de dados
│   │   │   └── repositories/       # Implementação dos repositórios
│   │   ├── domain/                 # Camada de domínio
│   │   │   ├── entities/           # Entidades de negócio
│   │   │   ├── repositories/       # Interfaces dos repositórios
│   │   │   └── usecases/           # Casos de uso
│   │   └── presentation/           # Camada de apresentação
│   │       ├── controllers/        # Controladores de estado
│   │       ├── screens/            # Telas
│   │       └── widgets/            # Widgets específicos
│   ├── home/                       # Módulo home
│   ├── investments/                # Módulo de investimentos
│   └── profile/                    # Módulo de perfil
├── shared/                         # Recursos compartilhados
│   ├── components/                 # Componentes reutilizáveis
│   ├── helpers/                    # Funções auxiliares
│   ├── models/                     # Modelos compartilhados
│   └── services/                   # Serviços compartilhados
└── main.dart                       # Ponto de entrada da aplicação
```

## Princípios da Clean Architecture

### 1. **Separação de Responsabilidades**
- Cada camada tem uma responsabilidade específica
- Dependências apontam para dentro (regras de negócio no centro)

### 2. **Inversão de Dependência**
- Interfaces definem contratos
- Implementações concretas são injetadas

### 3. **Testabilidade**
- Cada camada pode ser testada independentemente
- Mocks podem ser facilmente criados

## Camadas da Arquitetura

### **Domain Layer** (Regras de Negócio)
- **Entities**: Objetos de negócio puros
- **Repositories**: Interfaces para acesso a dados
- **Use Cases**: Lógica de negócio específica

### **Data Layer** (Acesso a Dados)
- **Data Sources**: APIs, banco de dados, cache
- **Models**: Representação dos dados
- **Repository Implementation**: Implementação das interfaces

### **Presentation Layer** (Interface do Usuário)
- **Screens**: Telas da aplicação
- **Widgets**: Componentes de UI
- **Controllers**: Gerenciamento de estado

## Benefícios

- ✅ **Manutenibilidade**: Código organizado e fácil de manter
- ✅ **Testabilidade**: Cada componente pode ser testado isoladamente
- ✅ **Escalabilidade**: Fácil adicionar novas funcionalidades
- ✅ **Reutilização**: Componentes podem ser reutilizados
- ✅ **Flexibilidade**: Mudanças em uma camada não afetam outras

## Próximos Passos

1. Implementar injeção de dependência
2. Adicionar testes unitários
3. Configurar roteamento
4. Implementar gerenciamento de estado global
5. Adicionar tratamento de erros global
