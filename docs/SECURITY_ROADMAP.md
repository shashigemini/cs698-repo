# Security Roadmap: Future Enhancements

This document outlines security features that require backend implementation or third-party service integration. These are intentionally deferred to prioritize client-side hardening.

## 1. Request Signing (HMAC)
- **Status**: Deferred (Requires Backend)
- **Scope**: All mutation endpoints (`/api/chat/query`, `/auth/*`).
- **Description**: Implement a Dio interceptor in the Flutter app to sign requests with an HMAC-SHA256 signature.
- **Backend Requirement**: Implement signature verification logic in FastAPI using a shared secret stored in environment variables.

## 2. App Attestation (Integrity Tokens)
- **Status**: Deferred (Requires Backend + Play Integrity/DeviceCheck setup)
- **Scope**: Mobile platforms (Android/iOS).
- **Description**: Use `freerasp` to generate integrity tokens on the device.
- **Backend Requirement**: Integrate with Google Play Integrity API and Apple DeviceCheck/App Attest to verify tokens on the server.

## 3. Backend Security Headers
- **Status**: Deferred (Requires Server Config)
- **Scope**: Web platform (Browser security).
- **Description**: Harden the API domain with modern security headers.
- **Recommended Headers**:
  - `Strict-Transport-Security` (HSTS): Enforce HTTPS.
  - `Content-Security-Policy` (CSP): Mitigate XSS.
  - `X-Frame-Options: DENY`: Prevent Clickjacking.
  - `X-Content-Type-Options: nosniff`: Prevent MIME-sniffing.

## 4. Advanced Rate Limiting
- **Status**: Deferred (Requires Redis)
- **Scope**: Global API.
- **Description**: Move from in-memory rate limiting to a Redis-backed distributed rate limiter to support multi-instance deployment.

## 5. E2EE Backend Infrastructure (V2 Architecture)
- **Status**: Deferred (Requires Backend + Database Migration)
- **Scope**: Authentication and Chat History Storage.
- **Description**: Implement the backend components required to support the Zero-Knowledge client architecture.
- **Backend Requirements**:
    - **Authentication**: Update the `/auth` endpoints to receive and hash a `ClientAuthToken` instead of a plain-text password.
    - **Key Storage**: Create database tables to store users' `Salt`, `WrappedAccountKey`, and `RecoveryWrappedAccountKey`.
    - **RAG E2EE-at-rest**: Implement a flow where incoming RAG queries are decrypted in volatile memory, converted to embeddings, searched against the vector database, and then the plain-text query is immediately discarded.

## 6. Password Change & Key Rotation (V2 Architecture)
- **Status**: Deferred (Requires Backend + Client implementation)
- **Scope**: Authentication and Key Management.
- **Description**: When a user changes their password, their `LocalMasterKey` (LMK) changes. We must not lose access to the `AccountKey` (AK) or past `ConversationKeys` (CKs).
- **Protocol**:
    1. Client requests a password change, providing the old password and the new password.
    2. Client derives `OldLMK` and unwraps the `WrappedAccountKey` to get `AK` in memory.
    3. Client derives `NewLMK` and a new `ClientAuthToken` from the *new* password.
    4. Client wraps the existing `AK` with the `NewLMK` -> `NewWrappedAK`.
    5. Client sends `NewClientAuthToken` and `NewWrappedAK` to the server.
    6. Server re-hashes the new token and overwrites the active `WrappedAccountKey`. All existing `ConversationKeys` remain valid because the underlying `AccountKey` did not change.
