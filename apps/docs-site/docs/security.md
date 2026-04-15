---
title: "Security & Authentication"
sidebar_position: 6
---

# Security

This page documents the security architecture, implemented hardening measures, and the future security roadmap for the Spiritual Q&A Platform.

## Authentication Model

The platform utilizes a robust JWT-based authentication system designed for both security and platform compatibility.

### JWT Strategy
- **Access Token**: Short-lived (15 min) token containing `user_id`, `role`, and expiration claims.
- **Refresh Token**: Long-lived (7 days) token used to obtain new access tokens. Implements **token rotation**, where the old refresh token is revoked upon use.

### Token Storage by Platform

| Platform | Access Token | Refresh Token | CSRF Token |
|----------|-------------|---------------|------------|
| **Web** | HttpOnly Cookie | HttpOnly Cookie | Non-HttpOnly Cookie/Header |
| **iOS** | Keychain (`flutter_secure_storage`) | Keychain | N/A |
| **Android** | KeyStore (`flutter_secure_storage`) | KeyStore | N/A |

## Hardening Measures

### 1. Runtime Protection (freeRASP)
The mobile applications are protected by **freeRASP** for real-time threat detection:
- **Integrity Checks**: Detects if the app has been tampered with or resigned.
- **Environment Checks**: Detects Root/Jailbreak, Emulators, and Hooking frameworks (e.g., Frida).

> [!IMPORTANT]
> **Initialization Robustness**: `freeRASP` configuration and initialization must be wrapped in a `try-catch` block to prevent startup hangs if environment variables are missing or platform-specific initialization fails.

### 2. Zero-Log Policy & Scrubbing
To prevent accidental leakage of sensitive data in diagnostics:
- **Scrubbing**: The `AppLogger.scrub()` utility redacts `password`, `token`, and `email` fields from all network diagnostic data.
- **Interception**: A custom `HttpInterceptor` ensures logs are scrubbed before they reach the console or persistent storage.

### 3. Transport Security
- **HTTPS Only**: All traffic is enforced over TLS 1.2+ with HSTS enabled.
- **Certificate Pinning**: Strict SHA-256 certificate pinning is enforced via `http_certificate_pinning` on mobile.
- **CORS**: Web origins are strictly restricted to allowed production domains.

## Data Privacy

### Account Deletion Flow
In compliance with international privacy standards, users can permanently delete their data:
1. **Request**: User initiates delete from the app settings.
2. **Backend Execution**: The server verifies the JWT, then performs a cascading delete of the `users` record, which automatically removes all associated `chat_sessions` and `chat_messages`.
3. **Completion**: All active tokens are invalidated, and the client clears local secure storage.

### Guest Anonymity
Guest users have a zero-persistence policy:
- `guest_session_id` is a random UUID used solely for rate limiting.
- Guest conversations are processed in-memory and are **never** persisted to the database or logged.

## Security Roadmap

| Feature | Status | Requirement |
| :--- | :--- | :--- |
| **App Attestation** | Planned | Play Integrity / DeviceCheck backend verification. |
| **Request Signing** | Planned | Backend signature verification (HMAC). |
| **WAF Integration** | In Progress | Cloud-layer protection against common web attacks. |

For a detailed task breakdown, see [SECURITY_ROADMAP.md](file:///workspaces/cs698-repo/docs/SECURITY_ROADMAP.md).
