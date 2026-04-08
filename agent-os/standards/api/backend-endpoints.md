# Backend Endpoints (NestJS)

Backend lives in `functions/src/` and runs on Railway. NestJS framework with modular structure.

## Module Structure

```
functions/src/
  app.module.ts                    # Root module
  main.ts                          # Bootstrap
  health.controller.ts             # Health check
  common/guards/api-key.guard.ts   # API key guard
  auth/
    auth.module.ts
    auth.controller.ts             # /api/auth/* endpoints
    services/simple-otp.service.ts # OTP generation + Firestore storage
    services/whatsapp.service.ts   # Twilio WhatsApp integration
    dto/*.dto.ts                   # class-validator DTOs
  users/
    users.module.ts
    users.controller.ts            # /api/users/* endpoints
    users.service.ts               # User CRUD via Firestore
    dto/*.dto.ts
  firebase-rest/
    firebase-rest.module.ts
    firestore-rest.service.ts      # Firestore REST API client
    auth-jwt.service.ts            # JWT sign/verify (replaces admin SDK)
    storage-rest.service.ts        # Firebase Storage REST API
```

## Controller Pattern

All controllers use `ApiKeyGuard` and Swagger decorators:

```typescript
@ApiTags('Auth')
@Controller('api/auth')
@UseGuards(ApiKeyGuard)
@ApiSecurity('api-key')
export class AuthController {
  @Post('send-otp-whatsapp')
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @ApiOperation({ summary: 'Enviar codigo OTP via WhatsApp' })
  @ApiResponse({ status: 200, description: 'OTP enviado' })
  @ApiResponse({ status: 400, description: 'Telefone invalido' })
  async sendOtpWhatsApp(@Body() body: SendPhoneOtpDto) { ... }
}
```

## Response Format

All responses include `success` field:

```typescript
// Success
return { success: true, message: '...', data: { ... } };

// Failure (throw NestJS exceptions)
throw new BadRequestException('Mensagem legivel');
throw new UnauthorizedException('Token invalido');
```

## Key Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /api/auth/send-otp-whatsapp | Send 4-digit OTP via WhatsApp |
| POST | /api/auth/verify-otp | Verify OTP code |
| POST | /api/auth/verify-otp-login | Verify OTP + login (returns JWT) |
| POST | /api/auth/check-user-status | Verify JWT, return user status |
| POST | /api/auth/reset-password | Send password reset email |
| GET | /api/users/check-cpf/:cpf | Check if CPF exists |

## Rules

- Every controller uses `@UseGuards(ApiKeyGuard)` -- client sends `x-api-key` header
- Rate limiting via `@Throttle()` on all endpoints
- DTOs use `class-validator` decorators for input validation
- Swagger docs auto-generated (`@ApiTags`, `@ApiOperation`, `@ApiResponse`)
- Environment: Railway deployment, base URL from `API_BASE_URL` env var
