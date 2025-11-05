# Dockerfile para Cloud Run - NestJS + PostgreSQL

# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar package files
COPY package*.json ./
COPY tsconfig*.json ./
COPY nest-cli.json ./

# Instalar dependências
# Usando npm install em vez de npm ci para evitar problemas com lock file desatualizado
RUN npm install

# Copiar código fonte
COPY src ./src

# Build da aplicação
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar apenas dependências de produção
RUN npm install --only=production

# Copiar build da aplicação
COPY --from=builder /app/dist ./dist

# Criar usuário não-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001
USER nestjs

# Expor porta
EXPOSE 8080

# Variáveis de ambiente
ENV PORT=8080
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando para iniciar
CMD ["node", "dist/main"]
