# Shared Services

Services in `lib/shared/services/` are static-method classes (no instances). They wrap platform/external APIs.

## Service Pattern

```dart
class SomeService {
  // Static methods, no constructor
  static Future<Result> doSomething() async { ... }
}
```

## Core Services

### EnvService (`lib/core/config/env_service.dart`)
Loads `.env` via `flutter_dotenv`. Provides typed getters:
```dart
static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://pagpagapp-production.up.railway.app';
static String get apiKey => dotenv.env['API_KEY'] ?? '';
static String get pagarmeApiKey => dotenv.env['PAGARME_API_KEY'] ?? '';
```

### FirestoreService (`lib/shared/services/firestore_service.dart`)
Firestore CRUD for users collection. Handles encryption/decryption transparently:
- `createUser()` -- encrypts CPF, email, phone before saving; generates hash for search
- `getUserByCpf()` -- queries by cpfHash, decrypts result
- `getUserByDocumentId()` -- direct document fetch
- `saveSale()` -- subcollection `users/{id}/sales/{saleId}`
- `updateUser()` -- partial updates with encryption

### BiometricService (`lib/shared/services/biometric_service.dart`)
Wraps `local_auth` package:
- `isAvailable()` -- checks device support
- `authenticate()` -- Face ID / Touch ID with device password fallback
- `isFaceIdAvailable()` / `isTouchIdAvailable()`

### EncryptionService (`lib/shared/services/encryption_service.dart`)
AES-256-CBC encryption + SHA-256 hashing:
- `encrypt(plaintext)` -- returns `base64(iv):base64(encrypted)`
- `decrypt(ciphertext)` -- reverses encryption
- `hash(data)` -- SHA-256 hash of normalized data

### SecureStorageService (`lib/shared/services/secure_storage_service.dart`)
FlutterSecureStorage wrapper (Keychain/KeyStore):
- `saveAuthToken()` / `getAuthToken()`
- `saveLastCpf()` / `getLastCpf()`
- `saveUserSession()` -- batch save token + userId + email
- `clearAll()` -- secure logout

### AuthApiService (`lib/features/auth/data/services/auth_api_service.dart`)
HTTP client for NestJS backend. Sends `x-api-key` header:
- `sendOtpWhatsApp(phone)` -- POST /api/auth/send-otp-whatsapp
- `verifyOtpLogin(phone, code)` -- POST /api/auth/verify-otp-login
- `checkCpf(cpf)` -- GET /api/users/check-cpf/:cpf

### Other Services
- `UserCacheService` -- in-memory + local cache for user data
- `CepService` -- Brazilian CEP (postal code) lookup
- `BalanceService` -- user balance management
- `OptimizedHttpService` -- HTTP client with connection pooling

## Rules

- Services use `AppLogger` for all logging (never `print()`)
- HTTP calls include timeout: `Duration(seconds: 10-15)`
- Error responses follow `{ success: false, message: '...' }` pattern
- Sensitive data logged via `AppLogger.sensitive()` (masked in production)
