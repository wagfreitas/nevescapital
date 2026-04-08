# Twilio WhatsApp Integration

OTP delivery via WhatsApp Business API through Twilio.

## Architecture

```
Flutter App -> NestJS Backend -> Twilio API -> WhatsApp -> User
```

The backend handles all Twilio communication. Flutter never talks to Twilio directly.

## WhatsApp Service

`functions/src/auth/services/whatsapp.service.ts`:

```typescript
@Injectable()
export class WhatsAppService {
  async sendOtpMessage(phone: string, code: string): Promise<boolean> {
    const message = await this.client.messages.create({
      from: `whatsapp:${this.fromNumber}`,
      to: `whatsapp:+${cleanPhone}`,
      contentSid: this.otpContentSid,          // Content Template SID
      contentVariables: JSON.stringify({ '1': code }),  // Template variable
    });
    return true;
  }
}
```

## Content Template

- Template SID: `HXc63e56630589f6a10de0d304c0ee09f1`
- Template has one variable `{{1}}` for the OTP code
- Pre-approved by WhatsApp (required for business messaging)

## OTP Flow Details

1. `SimpleOtpService.sendOtp(phone)` generates 4-digit code, saves to Firestore `otp_codes`
2. `WhatsAppService.sendOtpMessage()` called **fire-and-forget** (non-blocking)
3. Response returned to client immediately, WhatsApp delivery is async
4. OTP expires after 10 minutes, max 5 verification attempts
5. Old OTPs for same phone deleted before creating new one

## Environment Variables

```
TWILIO_ACCOUNT_SID=<account sid>
TWILIO_AUTH_TOKEN=<auth token>
TWILIO_WHATSAPP_FROM=+14155238886    # Twilio WhatsApp sandbox or business number
TWILIO_OTP_CONTENT_SID=HXc63e56630589f6a10de0d304c0ee09f1
```

## Webhook

`whatsapp-webhook.controller.ts` handles incoming messages from users.
Auto-reply: "Esse canal e destinado apenas ao envio de codigo OTP..."

## Rules

- Phone format: digits only, with country code (e.g., `5511989630454`)
- Minimum phone length: 12 digits
- WhatsApp delivery is fire-and-forget -- don't wait for delivery confirmation
- OTP code is 4 digits (not 6)
- Rate limit: 3 OTP requests per minute per endpoint
