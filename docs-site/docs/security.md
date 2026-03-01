# Security

This page documents the security architecture, implemented hardening measures, and the future security roadmap for the CS698 platform.

## End-to-End Encryption (E2EE)

The platform implements a robust E2EE layer to ensure that sensitive user data and conversation content remain private.

### 1. Key Derivation Flow
We use **Argon2id** for high-entropy key derivation from user passwords.

- **Local Master Key (LMK)**: Derived locally using Argon2id with a unique salt. The LMK never leaves the device.
- **Client Auth Token**: Derived from the LMK using **HKDF-SHA256**. This token is used for standard API authentication (via JWT exchange) without ever exposing the raw password or the LMK to the server.

### 2. Encryption Layers
- **Account Key (AK)**: A random 256-bit AES key generated during registration. It is wrapped (encrypted) with the LMK using **AES-GCM** before being "backed up" to the server.
- **Conversation Keys**: Messages are encrypted using individual conversation-scoped keys, ensuring that even if one key is compromised, the entire history remains secure.
- **AAD (Additional Authenticated Data)**: We bind ciphertexts to specific `conversation_id` and `message_id` to prevent replay or substitution attacks.

### 3. Account Recovery
To prevent permanent data loss if a device is lost, we implement a recovery mechanism using a **Recovery Wrapped Account Key (RWAK)**.
- During setup, a high-entropy recovery code is generated.
- The AK is wrapped with a key derived from this recovery code and stored on the server.
- This allows the user to restore their account on a new device without the original LMK, provided they have their recovery code.

## Implemented Hardening Measures

### 1. Zero-Log Policy & Scrubbing
To prevent accidental leakage of sensitive data in diagnostics:
- **Scrubbing**: `AppLogger.scrub()` redacts `password`, `token`, `lmk`, and `ak` fields.
- **Interception**: The `HttpInterceptor` scrubs logs before they reach the console or persistent storage.

### 2. Runtime Protection (freeRASP)
The mobile applications are protected by **freeRASP** for real-time threat detection:
- **Integrity Checks**: Detects if the app has been tampered with or resigned.
- **Environment Checks**: Detects Root/Jailbreak, Emulators, and Hooking frameworks (e.g., Frida).
- **Proactive Response**: In production, the app will securely exit if a critical threat is detected.

> [!IMPORTANT]
> **Initialization Robustness**: `freeRASP` configuration and initialization MUST be wrapped in a `try-catch` block. Failure to do so can cause the app to hang on startup if environment variables are missing or platform-specific initialization fails.

### 3. Certificate Pinning
Strict SHA-256 certificate pinning is enforced via the `http_certificate_pinning` package to mitigate Man-in-the-Middle (MitM) attacks.

## Security Roadmap

| Feature | Status | Requirement |
| :--- | :--- | :--- |
| **App Attestation** | Planned | Play Integrity / DeviceCheck backend verification. |
| **Request Signing** | Planned | Backend signature verification (HMAC). |
| **Security Headers** | In Progress | Server-side HSTS/CSP/X-Frame-Options. |

For a detailed task breakdown, see [SECURITY_ROADMAP.md](https://github.com/shashigemini/cs698-repo/blob/main/docs/SECURITY_ROADMAP.md).
