const https = require('https');

// Configuração
const API_BASE_URL = 'https://southamerica-east1-pag-pag-prod.cloudfunctions.net/api';
const API_KEY = 'test-api-key'; // Substituir pela chave real
const CPF_TESTE = '227.439.101-78'; // CPF que você está tentando usar

// Função para fazer requisição
function testEndpoint(endpoint, data = null) {
  return new Promise((resolve, reject) => {
    const url = `${API_BASE_URL}${endpoint}`;
    console.log(`🔍 Testando: ${url}`);
    
    const options = {
      method: data ? 'POST' : 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
      },
    };

    const req = https.request(url, options, (res) => {
      let body = '';
      
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        console.log(`📥 Status: ${res.statusCode}`);
        console.log(`📄 Response:`, body);
        
        try {
          const jsonResponse = JSON.parse(body);
          resolve({ status: res.statusCode, data: jsonResponse });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', (error) => {
      console.log(`❌ Erro:`, error.message);
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Testar endpoints
async function testLoginFlow() {
  console.log('🚀 Iniciando teste do fluxo de login por CPF\n');
  
  try {
    // 1. Testar busca por CPF
    console.log('1️⃣ Testando busca por CPF...');
    const cpfResult = await testEndpoint(`/users/cpf/${CPF_TESTE}`);
    
    if (cpfResult.status === 200) {
      console.log('✅ Usuário encontrado no PostgreSQL!');
      console.log('📧 Email encontrado:', cpfResult.data.email);
      
      // 2. Testar verificação de senha
      console.log('\n2️⃣ Testando verificação de senha...');
      const passwordResult = await testEndpoint('/users/verify-password', {
        cpf: CPF_TESTE,
        password: 'Teste123!'
      });
      
      console.log('🔐 Resultado da verificação de senha:', passwordResult);
      
    } else if (cpfResult.status === 404) {
      console.log('❌ Usuário NÃO encontrado no PostgreSQL');
      console.log('💡 Possíveis causas:');
      console.log('   - Usuário não foi cadastrado no PostgreSQL');
      console.log('   - CPF está incorreto');
      console.log('   - Problema na criptografia/descriptografia');
      console.log('   - Banco de dados não está acessível');
      
      // Testar se o endpoint está funcionando
      console.log('\n🔧 Testando se o backend está online...');
      await testEndpoint('/health');
      
    } else {
      console.log(`❌ Erro inesperado: ${cpfResult.status}`);
      console.log('📄 Resposta:', cpfResult.data);
    }
    
  } catch (error) {
    console.log('💥 Erro durante o teste:', error.message);
  }
}

// Executar teste
testLoginFlow();

