# Sorayomi Security & Privacy Design

## Problem

The Cloud Function (`generateReading`) currently accepts requests from anyone who knows the URL. No authentication, no rate limiting, no PII protection. An attacker could exhaust the OpenAI budget in minutes.

## Architecture

```
iOS App
  │
  ├─ App Attest (Apple hardware attestation)
  │   └─ Generates device integrity token
  │
  ├─ Firebase App Check
  │   └─ Wraps App Attest token for Firebase verification
  │
  └─ HTTPS POST with App Check token in header
      │
      ▼
Firebase Cloud Function (generateReading)
  │
  ├─ 1. App Check verification ← reject non-genuine apps
  ├─ 2. Input validation ← size limits, required fields
  ├─ 3. Rate limiting ← per-IP, sliding window
  ├─ 4. PII scrubbing ← mask phone/email/address before AI call
  ├─ 5. OpenAI call ← store:false, no data retention
  └─ 6. Response ← no sensitive data in logs
```

## Security Layers

### Layer 1: Firebase App Check (Device Attestation)

- Uses Apple **App Attest** (iOS 14+, hardware-backed)
- Cloud Function verifies App Check token on every request
- Rejects requests from emulators, modified apps, scripts
- Dev environment uses **Debug provider** for simulator testing

### Layer 2: Rate Limiting (Server-side)

- **Per-IP**: 30 requests per 15-minute window
- **Global**: 1000 requests per hour (cost protection)
- In-memory store (resets on cold start — acceptable for cost protection)
- Returns HTTP 429 with retry-after header

### Layer 3: Input Validation

- System prompt: max 5,000 characters
- User prompt: max 2,000 characters
- Conversation history: max 20 messages, each max 2,000 characters
- Total payload: max 100KB
- Reject requests exceeding limits with 400

### Layer 4: PII Scrubbing

Before sending to OpenAI, scrub:
- Phone numbers: `090-xxxx-xxxx` → `[電話番号]`
- Email addresses: `user@example.com` → `[メールアドレス]`
- Addresses: Patterns like `〒xxx-xxxx` → `[住所]`
- Credit card numbers: 16-digit sequences → `[カード番号]`
- My Number (マイナンバー): 12-digit sequences → `[個人番号]`

### Layer 5: OpenAI Data Controls

- `store: false` — OpenAI will not retain input/output
- No logging of prompt content on our server
- Only log: timestamp, IP hash, token count, success/error status

## Privacy Design

### Data Flow Principle: Minimal Data, No Persistence

```
User input → PII scrub → OpenAI → response → user
                                      ↑
                              Nothing stored on server
```

### What is sent to OpenAI
- Scrubbed system prompt (fortune-telling persona instructions)
- Scrubbed user prompt (seasonal context, fortune system data)
- Scrubbed conversation history (follow-up questions)

### What is NOT sent to OpenAI
- User's birthday, blood type, or personal profile (used locally only for calculations)
- Device identifiers
- IP addresses

### Privacy Manifest (PrivacyInfo.xcprivacy)
- NSPrivacyTracking: false
- No collected data types
- API usage: UserDefaults (CA92.1), Keychain (for free trial)

### On-Device Data
- UserProfile stored in UserDefaults (birthday, blood type) — never leaves device
- Reading history stored in UserDefaults — never uploaded
- Free trial flag in Keychain — never uploaded

## Files to Modify

| File | Changes |
|------|---------|
| `firebase/functions/src/index.ts` | App Check, rate limit, PII scrub, input validation, store:false |
| `firebase/functions/package.json` | Add firebase-admin dependency |
| `Sorayomi/App/AppCheckProviderFactory.swift` | New: App Check setup |
| `Sorayomi/App/SorayomiApp.swift` | Initialize App Check |
| `Sorayomi/Data/Firebase/CloudFunctionClient.swift` | Add App Check token header |
| `Sorayomi/Sorayomi.entitlements` | Add App Attest capability |
| `Sorayomi/PrivacyInfo.xcprivacy` | Confirm declarations |

## Deployment Steps

1. Enable App Check in Firebase Console → App Attest provider
2. `firebase functions:secrets:set OPENAI_API_KEY`
3. `cd firebase && firebase deploy --only functions`
4. Copy function URL → `AppConstants.cloudFunctionBaseURL`
5. Register app in Firebase Console with Bundle ID + Team ID
