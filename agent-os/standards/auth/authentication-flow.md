# Authentication Flow

## OTP via WhatsApp (Primary Login)

1. User enters phone number on mobile
2. Flutter calls `AuthApiService.sendOtpWhatsApp(phone)` -> backend `/api/auth/send-otp-whatsapp`
3. Backend generates 4-digit OTP, saves to Firestore `otp_codes` collection, sends via Twilio WhatsApp
4. User enters OTP code
5. Flutter calls `AuthApiService.verifyOtpLogin(phone, code)` -> backend `/api/auth/verify-otp-login`
6. Backend verifies OTP, looks up user by phoneHash in Firestore
7. If user found + complete registration -> returns JWT token + status `LOGGED_IN`
8. If user not found or incomplete -> returns status `REGISTER`
9. Flutter stores login state via `SharedPreferences` (`is_logged_in_otp: true`)

```
Mobile                    Backend                    Firestore
  |--- sendOtpWhatsApp -->|                           |
  |                       |--- save OTP doc --------->|
  |                       |--- Twilio WhatsApp ------>| (async, fire-and-forget)
  |<-- { success } -------|                           |
  |                       |                           |
  |--- verifyOtpLogin --->|                           |
  |                       |--- verify OTP doc ------->|
  |                       |--- query user by phone -->|
  |                       |--- sign JWT ------------->|
  |<-- { token, status }--|                           |
```

## Login State Management

Two login mechanisms coexist in `AuthController`:

- **Firebase Auth login**: `_currentUser != null` (legacy, CPF+password flow)
- **OTP login**: `_isLoggedInOtp = true` (primary flow, stored in SharedPreferences)
- **Combined**: `isLoggedIn = _currentUser != null || _isLoggedInOtp`

## Registration (8-step Flow)

1. CPF entry (UnifiedCpfScreen)
2. Phone number
3. OTP verification
4. Email
5. Personal data (name, birthDate, motherName)
6. Address (with CEP auto-fill)
7. Additional data (occupation, income, PEP)
8. Document upload (selfie + ID)

Progress tracked via `RegistrationProgress` entity and `LocalRegistrationStorage`.

## Biometric Auth

- Uses `local_auth` package (`BiometricService`)
- Supports Face ID, Touch ID, and device passcode fallback
- Biometric preference stored in `SecureStorageService`
- Re-authenticates using saved CPF from SecureStorage

## Logout

Clears all state in parallel:
1. Firebase signOut (if applicable)
2. SharedPreferences (`is_logged_in_otp = false`)
3. SecureStorage (`clearAll()`)
4. UserCacheService + UserHelper caches
