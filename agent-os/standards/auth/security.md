# Security

## API Key Guard (Backend)

All backend endpoints require `x-api-key` header:

```typescript
// common/guards/api-key.guard.ts
@Injectable()
export class ApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const apiKey = request.headers['x-api-key'];
    if (apiKey !== process.env.API_KEY) throw new UnauthorizedException();
    return true;
  }
}
```

Flutter sends the key via `EnvService.apiKey` in every request header.

## JWT Authentication

- Backend signs JWT with `AuthJwtService.signToken()` after OTP verification
- Payload: `{ sub: userId, phone, iat, exp }`
- Issuer: `neves-capital-api`, Audience: `pagpag-app`
- Expiry: 7 days (configurable via `JWT_EXPIRES_IN`)
- Verification: `AuthJwtService.verifyToken()` checks signature, issuer, audience

## Encryption (Mobile)

`EncryptionService` -- AES-256-CBC for sensitive data before Firestore storage:

```dart
// Encrypt before saving
final cpfEncrypted = await EncryptionService.encrypt(cpf);
final cpfHash = EncryptionService.hash(cpf);  // SHA-256 for search

// Decrypt after reading
final cpf = await EncryptionService.decrypt(encryptedData);
```

- IV prepended to ciphertext: `base64(iv):base64(encrypted)`
- Hash: SHA-256 of normalized data (digits only) -- for query without decryption
- Key stored in FlutterSecureStorage, falls back to default (must change in prod)

## Secure Storage (Mobile)

`SecureStorageService` -- Keychain (iOS) / KeyStore (Android):

```dart
static const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,  // No iCloud sync
  ),
);
```

Stores: auth tokens, userId, email, CPF, biometric preference.

## Rate Limiting (Backend)

All endpoints use `@Throttle()`:
- OTP send: 3 requests/minute
- OTP verify: 10 requests/minute
- Password reset: 5 requests/minute

## Rules

- Sensitive fields in Firestore are always encrypted (CPF, email, phone)
- Hashed versions stored alongside for query capability
- API keys loaded from `.env` via `EnvService` -- never hardcoded
- Logout clears ALL local data (SecureStorage, SharedPreferences, caches)
- OTP codes expire after 10 minutes, max 5 attempts
