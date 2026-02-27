# Security

This page documents the security audit findings, the implemented hardening measures, and the future security roadmap for the CS698 project.

## Security Audit: Password Transmission

A comprehensive audit was performed to evaluate how sensitive data, specifically passwords, are handled during transmission.

### Findings
- **API Contract**: Passwords are sent in the plain-text JSON body of `/auth/login` and `/auth/register` requests.
- **Transport Security**: All production traffic is mandated to use **HTTPS (TLS 1.2+)**, ensuring that entire request payloads are encrypted in transit.
- **Server-Side**: The backend uses **Argon2id** hashing before persisting passwords, ensuring they are only held in memory temporarily during the authentication cycle.

## Implemented Measures

### 1. Zero-Log Policy (Client-Side)
To prevent accidental leakage of sensitive data in logs (e.g., console output, file logs), a sensitive data scrubber was implemented.
- **Utility**: `AppLogger.scrub()` automatically redacts keys like `password`, `token`, and `api_key`.
- **Interception**: All outgoing requests are intercepted to redact sensitive fields before logging diagnostics.

### 2. Strict Certificate Pinning
To prevent Man-in-the-Middle (MitM) attacks, the frontend now uses strict certificate pinning.
- **Implementation**: The `http_certificate_pinning` package is used to verify the backend's SHA-256 fingerprint during every network handshake.

## Security Roadmap

The following enhancements are planned for future phases, requiring additional backend or infrastructure support:

| Feature | Status | Requirement |
| :--- | :--- | :--- |
| **Request Signing (HMAC)** | Deferred | Backend implementation of signature verification. |
| **App Attestation** | Deferred | Play Integrity / DeviceCheck setup and backend verification. |
| **Security Headers** | Deferred | Server configuration (HSTS, CSP, X-Frame-Options). |
| **Advanced Rate Limiting** | Deferred | Redis-backed distributed state. |

For a detailed breakdown of these tasks, see the [SECURITY_ROADMAP.md](https://github.com/shashigemini/cs698-repo/blob/main/docs/SECURITY_ROADMAP.md) in the repository.
