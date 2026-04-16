# P5 Test Specifications

> **Project**: Spiritual Q&A Platform  
> **Sprint**: P5 — Testing  
> **Date**: 2026-04-06  
> **Coverage Target**: ≥ 80% per file  

This document contains the English-language test specification for four core files:
two from the frontend (Flutter/Dart) and two from the backend (Python/FastAPI).
Each specification describes every function, its purpose, and a table of unit tests
that collectively exercise ≥ 80% of the function's execution paths.

---

# Table of Contents

1. [Frontend File 1: CryptographyService](#1-frontend-file-1-cryptographyservice)
2. [Frontend File 2: ChatController](#2-frontend-file-2-chatcontroller)
3. [Backend File 1: security.py](#3-backend-file-1-securitypy)
4. [Backend File 2: auth_service.py](#4-backend-file-2-auth_servicepy)
5. [Test Execution Scripts](#test-execution-scripts)

---

# 1. Frontend File 1: CryptographyService

**File**: `apps/frontend/lib/core/services/cryptography_service.dart`  
**Lines**: 155  
**Functions**: 8 (including `_deriveKeyRoutine` top-level helper)  
**Test Framework**: `flutter_test`

## 1.1 File Overview

`CryptographyService` provides all cryptographic primitives for the application's
End-to-End Encryption (E2EE) system. It uses the `cryptography` Dart package
to orchestrate:
- **Argon2id** for password-based key derivation (via background Isolate)
- **HKDF-SHA256** for deterministic sub-key derivation
- **AES-256-GCM** for authenticated encryption/decryption and key wrapping

The class has no branching logic within individual methods (no `if/else` paths);
however, each method has nominal and exception paths (e.g., wrong key, wrong AAD,
corrupted ciphertext). The primary concern is testing cryptographic correctness:
round-trip fidelity, key independence, and tamper detection.

## 1.2 Function Inventory

| # | Function | Lines | Visibility | Purpose |
|---|----------|-------|------------|---------|
| 1 | `_deriveKeyRoutine` | 8–29 | private (top-level) | Isolate entry point for Argon2id key derivation. Receives password, salt, and a Web/native flag, then returns 32 raw bytes. |
| 2 | `deriveLocalMasterKey` | 41–55 | public | Derives a Local Master Key (LMK) from a plaintext password and salt via Argon2id, off-loading computation to a background Isolate. |
| 3 | `deriveAuthToken` | 60–69 | public | Deterministically derives a base64url-encoded ClientAuthToken from an LMK using HKDF-SHA256 with `"auth_token_derivation"` info. |
| 4 | `expandKey` | 72–75 | public | Expands a shorter key to 256 bits via HKDF-SHA256 with `"key_expansion"` info. |
| 5 | `generateRandomKey` | 78–80 | public | Generates a cryptographically random 256-bit AES key. |
| 6 | `wrapKey` | 85–97 | public | Encrypts (wraps) a target SecretKey using AES-256-GCM with an optional AAD binding. Returns base64url-encoded ciphertext. |
| 7 | `unwrapKey` | 100–117 | public | Decrypts (unwraps) a base64url-encoded wrapped key using AES-256-GCM. Returns the original SecretKey. |
| 8 | `encryptContent` | 122–133 | public | Encrypts a plaintext string using AES-256-GCM with optional AAD. Returns base64url-encoded ciphertext. |
| 9 | `decryptContent` | 136–153 | public | Decrypts a base64url-encoded ciphertext using AES-256-GCM with optional AAD. Returns the original plaintext string. |

## 1.3 Execution Path Analysis

| Function | Path | Description |
|----------|------|-------------|
| `deriveLocalMasterKey` | P1-Nominal | Password + salt → Argon2id → 32-byte SecretKey |
| `deriveAuthToken` | P2-Nominal | LMK → HKDF → base64url string |
| `expandKey` | P3-Nominal | Short key → HKDF → 256-bit SecretKey |
| `generateRandomKey` | P4-Nominal | → random 256-bit SecretKey |
| `wrapKey` | P5-Nominal-AAD | Key + wrapping key + AAD → base64url ciphertext |
| `wrapKey` | P5-Nominal-NoAAD | Key + wrapping key, no AAD (defaults to `[]`) → base64url ciphertext |
| `unwrapKey` | P6-Nominal | Correct wrapped key + correct wrapping key + correct AAD → original key |
| `unwrapKey` | P6-Exception-WrongKey | Wrong wrapping key → `SecretBoxAuthenticationError` thrown |
| `unwrapKey` | P6-Exception-WrongAAD | Correct key but wrong AAD → `SecretBoxAuthenticationError` thrown |
| `unwrapKey` | P6-Exception-Corrupted | Corrupted base64 data → exception thrown |
| `encryptContent` | P7-Nominal-AAD | Plaintext + key + AAD → base64url ciphertext |
| `encryptContent` | P7-Nominal-NoAAD | Plaintext + key, no AAD → base64url ciphertext |
| `encryptContent` | P7-EmptyContent | Empty string `""` + key → valid ciphertext |
| `decryptContent` | P8-Nominal | Correct ciphertext + correct key + correct AAD → original plaintext |
| `decryptContent` | P8-Exception-WrongKey | Wrong key → `SecretBoxAuthenticationError` thrown |
| `decryptContent` | P8-Exception-WrongAAD | Correct key but swapped AAD → `SecretBoxAuthenticationError` thrown |

## 1.4 Test Specification Table

| Test ID | Function Under Test | Test Purpose | Input | Expected Output |
|---------|-------------------|--------------|-------|-----------------|
| CS-01 | `deriveLocalMasterKey` | Same password + salt produces deterministic output | `password="test-password"`, `salt=utf8.encode("test-salt")` — called twice | Both returned keys have identical bytes |
| CS-02 | `deriveLocalMasterKey` | Output has correct length (32 bytes) | `password="pw"`, `salt=[1,2,3,4]` | `key.extractBytes().length == 32` |
| CS-03 | `deriveLocalMasterKey` | Different passwords produce different keys | `password="pw-a"` vs `password="pw-b"`, same salt | Bytes differ |
| CS-04 | `deriveLocalMasterKey` | Different salts produce different keys | Same password, `salt=[0]` vs `salt=[1]` | Bytes differ |
| CS-05 | `deriveAuthToken` | Produces non-empty base64url string | LMK = `SecretKey(List.generate(32, (i) => i))` | Non-empty string, valid base64url |
| CS-06 | `deriveAuthToken` | Token differs from raw LMK bytes | LMK as above | Token ≠ `base64Url.encode(lmk.extractBytes())` |
| CS-07 | `deriveAuthToken` | Deterministic: same LMK → same token | Same LMK called twice | Both tokens are identical |
| CS-08 | `expandKey` | Output is a 256-bit (32-byte) key | 128-bit input key (`SecretKey(List.generate(16, (i) => i))`) | `expandedKey.extractBytes().length == 32` |
| CS-09 | `expandKey` | Expanded key differs from input key | 256-bit key as input | Expanded bytes ≠ input bytes |
| CS-10 | `expandKey` | Deterministic: same input → same expansion | Same key called twice | Identical output |
| CS-11 | `generateRandomKey` | Returns a 256-bit (32-byte) key | No input | `key.extractBytes().length == 32` |
| CS-12 | `generateRandomKey` | Two generated keys are different | Generate key1, key2 | `key1.extractBytes() != key2.extractBytes()` |
| CS-13 | `wrapKey` | Wrap-then-unwrap round-trip (with AAD) | `keyToWrap` + `wrappingKey` + `aad=[1,2,3]` | `unwrapKey` recovers original key bytes exactly |
| CS-14 | `wrapKey` | Wrap-then-unwrap round-trip (no AAD) | `keyToWrap` + `wrappingKey`, no `aad` parameter | `unwrapKey(result, wrappingKey)` recovers original key |
| CS-15 | `wrapKey` | Wrapped output is a non-empty base64url string | Any valid keys | Non-empty string |
| CS-16 | `unwrapKey` | Fails with wrong wrapping key | Wrapped with `keyA`, unwrap with `keyB` | Throws exception |
| CS-17 | `unwrapKey` | Fails with mismatched AAD | Wrapped with `aad=[1]`, unwrap with `aad=[2]` | Throws exception |
| CS-18 | `encryptContent` | Encrypt-then-decrypt round-trip (with AAD) | `content="Hello"`, `key`, `aad=utf8.encode("conv:msg")` | `decryptContent` returns `"Hello"` |
| CS-19 | `encryptContent` | Encrypt-then-decrypt round-trip (no AAD) | `content="Hello"`, `key`, no `aad` | `decryptContent(result, key)` returns `"Hello"` |
| CS-20 | `encryptContent` | Empty string encrypts and decrypts correctly | `content=""`, `key` | Decrypt returns `""` |
| CS-21 | `encryptContent` | Unicode content encrypts and decrypts correctly | `content="🕉 ॐ नमः शिवाय"`, `key` | Decrypt returns identical Unicode string |
| CS-22 | `decryptContent` | Fails with wrong key | Encrypted with `keyA`, decrypt with `keyB` | Throws exception |
| CS-23 | `decryptContent` | Fails with swapped AAD context | Encrypted with `aad="conv-A:msg-1"`, decrypt with `aad="conv-B:msg-1"` | Throws exception |
| CS-24 | `encryptContent` | Two encryptions of same content produce different ciphertexts (random nonce) | Same `content` + same `key`, encrypted twice | `ciphertext1 != ciphertext2` |

**Coverage Estimate**: 24 tests cover all 9 functions, all nominal paths, all optional parameter
branches (`aad` present vs. null), and all exception paths. Estimated coverage: **~95%**.

---

# 2. Frontend File 2: ChatController

**File**: `apps/frontend/lib/features/chat/application/chat_controller.dart`  
**Lines**: 222  
**Functions**: 8 public + 1 private (`_init`)  
**Test Framework**: `flutter_test` + `mocktail` + `riverpod`

## 2.1 File Overview

`ChatController` is a Riverpod `@Riverpod(keepAlive: true)` notifier that manages
the entire chat lifecycle. It holds a `ChatState` (Freezed immutable model) with:
messages, loading flag, error string, guest queries remaining, conversation ID,
and recent conversation list.

The controller depends on:
- `chatRepositoryProvider` — API calls (will be mocked with `MockChatRepository`)
- `guestServiceProvider` — guest query budget tracking (will be mocked)
- `authControllerProvider` — current user ID (will be overridden)
- `storageServiceProvider` — secure storage (will use `MockStorageService`)

All methods except `newConversation` and `resetError` are `async` and interact
with repositories that may throw exceptions.

## 2.2 Function Inventory

| # | Function | Lines | Purpose |
|---|----------|-------|---------|
| 1 | `build()` | 23–36 | Riverpod lifecycle: sets up auth state listener, triggers `_init()` on first build. Returns default `ChatState`. |
| 2 | `_init()` | 38–64 | Loads initial guest budget and conversations for authenticated users. Sets state. Completes `_initCompleter`. |
| 3 | `sendQuery(query, {guestSessionId})` | 66–148 | Main entry point: sends user query to repo, adds messages, handles guest rate limits, handles exceptions. |
| 4 | `loadConversation(id)` | 150–169 | Loads message history for a specific conversation. Handles repo errors. |
| 5 | `fetchRecentConversations()` | 171–184 | Refreshes the list of recent conversations from repo. Silent error handling. |
| 6 | `deleteConversation(id)` | 186–197 | Deletes a conversation, refreshes list, resets to new conversation if active. |
| 7 | `exportConversation(id)` | 199–207 | Exports conversation data. Returns data or null on error. |
| 8 | `newConversation()` | 209–216 | Resets state to empty conversation (clears messages, conversationId, error, rateLimitExceeded). |
| 9 | `resetError()` | 218–220 | Clears the error field in state. |

## 2.3 Execution Path Analysis

| Function | Path | Description | Lines |
|----------|------|-------------|-------|
| `build` | P1-FirstBuild | `_initialized` is false → sets `_initialized = true`, calls `_init()` | 31–34 |
| `build` | P1-Rebuild | `_initialized` is already true → skips `_init()` | 31 |
| `build` | P1-AuthChanged | Auth listener fires with changed state → resets ChatState + calls `_init()` | 24–29 |
| `_init` | P2-Guest | `authState` is null or guest → skips `repo.getConversations()`, sets state with empty list | 45, 50–55 |
| `_init` | P2-Authenticated | `authState` is a real user ID → fetches conversations from repo | 45–48, 50–55 |
| `_init` | P2-Exception | `repo.getConversations()` throws → catches exception, logs error | 57–58 |
| `_init` | P2-CompleterAlready | `_initCompleter` already completed → `finally` block is a no-op | 60–62 |
| `sendQuery` | P3-Blocked-Loading | `state.isLoading == true` → returns immediately | 69–72 |
| `sendQuery` | P3-Blocked-RateLimit | `state.rateLimitExceeded == true` → returns immediately | 69–72 |
| `sendQuery` | P3-GuestZeroRemaining | `guestSessionId != null` and `guestQueriesRemaining <= 0` → sets rateLimitExceeded, returns | 74–81 |
| `sendQuery` | P3-Success-Auth | Authenticated query → adds user msg, calls repo, adds assistant msg, calls `fetchRecentConversations` (if new) | 83–131 |
| `sendQuery` | P3-Success-Guest | Guest query → adds user msg, calls repo, increments guest usage, decrements remaining | 83–127 |
| `sendQuery` | P3-Success-ExistingConv | `conversationId` is not null → does NOT call `fetchRecentConversations` | 129 |
| `sendQuery` | P3-Error-RateLimit | Repo throws `RateLimitException` → sets `rateLimitExceeded=true`, `guestQueriesRemaining=0` | 137–143 |
| `sendQuery` | P3-Error-Other | Repo throws other exception → sets `error=e.toString()` | 144–146 |
| `loadConversation` | P4-Success | Repo returns message history → sets state with messages | 157–161 |
| `loadConversation` | P4-Error | Repo throws → sets error = `"Failed to load conversation history"` | 162–168 |
| `fetchRecentConversations` | P5-Success | Repo returns conversations → updates `recentConversations` and `queryUsage` | 173–180 |
| `fetchRecentConversations` | P5-Error | Repo throws → logs error silently (state unchanged) | 181–183 |
| `deleteConversation` | P6-Success-DifferentConv | Deletes conversation that is NOT the active one → refreshes list, does NOT call `newConversation` | 187–193 |
| `deleteConversation` | P6-Success-ActiveConv | Deletes the currently active conversation → refreshes list, calls `newConversation()` | 191–193 |
| `deleteConversation` | P6-Error | Repo throws → logs error silently | 194–196 |
| `exportConversation` | P7-Success | Returns exported string data | 200–202 |
| `exportConversation` | P7-Error | Repo throws → returns `null` | 203–206 |
| `newConversation` | P8-Nominal | Resets `messages`, `conversationId`, `error`, `rateLimitExceeded` | 209–216 |
| `resetError` | P9-Nominal | Sets `error = null` | 218–220 |

## 2.4 Test Specification Table

| Test ID | Function Under Test | Test Purpose | Setup / Input | Expected Output |
|---------|-------------------|--------------|---------------|-----------------|
| CC-01 | `build` | Initial state has correct defaults | Create ProviderContainer, read state | `isLoading=false`, `messages=[]`, `error=null`, `rateLimitExceeded=false`, `guestQueriesRemaining=3` |
| CC-02 | `build` / `_init` | Guest user initialization skips conversation fetch | Auth = `null`, mock repo `getConversations` | `recentConversations=[]`, repo `getConversations` never called |
| CC-03 | `build` / `_init` | Authenticated user initialization fetches conversations | Auth = `"real-user-id"`, mock repo returns 2 conversations | `recentConversations.length==2`, `queryUsage==2` |
| CC-04 | `build` / `_init` | Init error is caught and logged (no crash) | Auth = `"real-user"`, mock repo throws `Exception` | State remains default, no unhandled exception |
| CC-05 | `sendQuery` | Blocked when `isLoading` is true | Manually set state with `isLoading=true`, call `sendQuery("q")` | No state change, returns immediately |
| CC-06 | `sendQuery` | Blocked when `rateLimitExceeded` is true | Manually set state with `rateLimitExceeded=true`, call `sendQuery("q")` | No state change, returns immediately |
| CC-07 | `sendQuery` | Guest with zero remaining triggers rate limit | Set `guestQueriesRemaining=0`, call `sendQuery("q", guestSessionId: "g")` | `rateLimitExceeded=true`, `error="Rate limit exceeded"`, `guestQueriesRemaining=0` |
| CC-08 | `sendQuery` | Authenticated success — user message added optimistically | Mock repo returns `AnswerResult`, call `sendQuery("test")` | During: `isLoading=true`, `messages.length=1`, `messages[0].sender="user"`. After: `isLoading=false`, `messages.length=2`, `messages[1].sender="assistant"` |
| CC-09 | `sendQuery` | Guest success — decrements guest queries | `guestQueriesRemaining=3`, call `sendQuery("q", guestSessionId: "g")` | `guestQueriesRemaining` decreases by 1 |
| CC-10 | `sendQuery` | New conversation triggers `fetchRecentConversations` | `conversationId=null`, authenticated, call `sendQuery("q")` | `recentConversations` updated after repo call |
| CC-11 | `sendQuery` | Existing conversation does NOT trigger `fetchRecentConversations` | `conversationId="existing-id"`, call `sendQuery("q")` | Repo `getConversations` called only from `_init`, not again |
| CC-12 | `sendQuery` | Network error sets error state | Mock repo throws `Exception("NetworkError")` | `isLoading=false`, `error` contains `"NetworkError"` |
| CC-13 | `sendQuery` | RateLimitException error sets rate limit state | Mock repo throws `Exception("RateLimitException")` | `rateLimitExceeded=true`, `error="Rate limit exceeded"`, `guestQueriesRemaining=0` |
| CC-14 | `loadConversation` | Success loads messages | Mock `loadHistory("conv-1")` returns 2 messages | `messages.length==2`, `isLoading=false`, `conversationId="conv-1"` |
| CC-15 | `loadConversation` | Loading state during fetch | Call `loadConversation("conv-1")`, check mid-call state | `isLoading=true`, `messages=[]`, `conversationId="conv-1"` |
| CC-16 | `loadConversation` | Error sets failure message | Mock `loadHistory` throws `Exception` | `isLoading=false`, `error="Failed to load conversation history"`, `messages=[]` |
| CC-17 | `fetchRecentConversations` | Success updates conversation list | Mock `getConversations` returns 3 conversations | `recentConversations.length==3`, `queryUsage==3` |
| CC-18 | `fetchRecentConversations` | Error is silently caught (no state change) | Mock `getConversations` throws | State `recentConversations` unchanged from before call |
| CC-19 | `deleteConversation` | Deleting non-active conversation refreshes list | Active `conversationId="A"`, delete `"B"` | `conversationId` remains `"A"`, list refreshed |
| CC-20 | `deleteConversation` | Deleting active conversation resets to new | Active `conversationId="A"`, delete `"A"` | `conversationId=null`, `messages=[]`, `error=null` |
| CC-21 | `deleteConversation` | Error is silently caught | Mock `deleteConversation` throws | No unhandled exception, state unchanged |
| CC-22 | `exportConversation` | Success returns export string | Mock `exportConversation("id")` returns `"exported data"` | Return value == `"exported data"` |
| CC-23 | `exportConversation` | Error returns null | Mock `exportConversation` throws | Return value == `null` |
| CC-24 | `newConversation` | Resets all conversation state | State has `messages=[msg]`, `conversationId="X"`, `error="err"`, `rateLimitExceeded=true` | After: `messages=[]`, `conversationId=null`, `error=null`, `rateLimitExceeded=false` |
| CC-25 | `resetError` | Clears error field | State has `error="some error"` | `error=null` |
| CC-26 | `resetError` | No-op when error is already null | State has `error=null` | `error=null` (no exception) |

**Coverage Estimate**: 26 tests cover all 9 functions, all branching paths (13 distinct paths
in `sendQuery` alone), and exception handling. Estimated coverage: **~90%**.

---

# 3. Backend File 1: security.py

**File**: `apps/backend/app/core/security.py`  
**Lines**: 146  
**Functions**: 6  
**Test Framework**: `pytest` + `pytest-asyncio`

## 3.1 File Overview

`security.py` provides the core security primitives for the backend:
- **Argon2id** password hashing via `argon2-cffi`
- **RS256 JWT** creation and validation via `python-jose`
- **CSRF token** generation via `secrets`

The module uses a module-level `PasswordHasher` instance `_ph` configured with
Argon2id parameters (64 MB memory, 3 iterations, 1 parallelism).

## 3.2 Function Inventory

| # | Function | Lines | Purpose |
|---|----------|-------|---------|
| 1 | `hash_password(password: str) → str` | 28–30 | Hashes a plaintext password (or ClientAuthToken) using Argon2id. Returns the hash string. |
| 2 | `verify_password(plain: str, hashed: str) → bool` | 33–41 | Verifies a plaintext against a stored Argon2id hash. Returns `True` for match, `False` for mismatch. Catches `VerifyMismatchError`. |
| 3 | `create_access_token(settings, *, user_id, role, extra_claims) → (str, datetime)` | 44–78 | Generates a signed RS256 JWT access token with claims `sub`, `role`, `type=access`, `jti`, `iat`, `exp`, and optional `extra_claims`. Returns `(token, expires_at)`. |
| 4 | `create_refresh_token(settings, *, user_id) → (str, datetime, str)` | 81–108 | Generates a signed RS256 JWT refresh token with claims `sub`, `type=refresh`, `jti`, `iat`, `exp`. Returns `(token, expires_at, jti)`. |
| 5 | `decode_token(settings, token, *, expected_type) → dict` | 111–140 | Decodes and validates a JWT. Two error paths: `JWTError` → `TokenError`, type mismatch → `TokenError`. |
| 6 | `generate_csrf_token() → str` | 143–145 | Returns a URL-safe random string via `secrets.token_urlsafe(32)`. |

## 3.3 Execution Path Analysis

| Function | Path | Description |
|----------|------|-------------|
| `hash_password` | P1-Nominal | String input → Argon2id hash starting with `$argon2id$` |
| `verify_password` | P2-Match | Correct plain + valid hash → `True` |
| `verify_password` | P2-Mismatch | Wrong plain → `VerifyMismatchError` caught → `False` |
| `create_access_token` | P3-DefaultRole | No `role` param → defaults to `"user"` |
| `create_access_token` | P3-CustomRole | `role="admin"` → payload includes `"role": "admin"` |
| `create_access_token` | P3-NoExtraClaims | `extra_claims=None` → `{}` merged into payload |
| `create_access_token` | P3-WithExtraClaims | `extra_claims={"foo": "bar"}` → payload includes `"foo"` |
| `create_refresh_token` | P4-Nominal | Generates token with `type=refresh`, unique JTI, expiry in days |
| `decode_token` | P5-ValidAccess | Valid access token, `expected_type="access"` → returns payload dict |
| `decode_token` | P5-ValidRefresh | Valid refresh token, `expected_type="refresh"` → returns payload dict |
| `decode_token` | P5-InvalidJWT | Garbage string → `JWTError` → `TokenError` raised |
| `decode_token` | P5-TypeMismatch | Access token decoded with `expected_type="refresh"` → `TokenError` raised with log |
| `decode_token` | P5-ExpiredToken | Expired JWT → `JWTError` → `TokenError` raised |
| `generate_csrf_token` | P6-Nominal | → URL-safe string of ~43 characters |
| `generate_csrf_token` | P6-Unique | Two sequential calls → different tokens |

## 3.4 Test Specification Table

| Test ID | Function Under Test | Test Purpose | Input | Expected Output |
|---------|-------------------|--------------|-------|-----------------|
| SEC-01 | `hash_password` | Returns Argon2id-format string | `"MyP@ssw0rd!"` | String starts with `"$argon2id$"` |
| SEC-02 | `hash_password` | Different calls produce different hashes (unique salts) | `"same-password"` called twice | `hash1 != hash2` |
| SEC-03 | `hash_password` | Handles empty string input | `""` | Returns a valid hash string (no crash) |
| SEC-04 | `hash_password` | Handles long input (1000 chars) | `"A" * 1000` | Returns a valid hash string |
| SEC-05 | `hash_password` | Handles special characters | `"pÄ$$wörd!@#☺"` | Returns a valid hash string |
| SEC-06 | `verify_password` | Correct password verifies successfully | `"pw"` hashed, then verified with `"pw"` | `True` |
| SEC-07 | `verify_password` | Wrong password fails verification | `"pw"` hashed, verified with `"wrong"` | `False` |
| SEC-08 | `verify_password` | Empty password correctly fails | `"hello"` hashed, verified with `""` | `False` |
| SEC-09 | `verify_password` | Verification is case-sensitive | `"Password"` hashed, verified with `"password"` | `False` |
| SEC-10 | `create_access_token` | Payload contains required claims | `user_id="u1"`, `role="user"` | Decoded payload has `sub="u1"`, `role="user"`, `type="access"`, `jti` present, `iat` present, `exp` present |
| SEC-11 | `create_access_token` | Default role is `"user"` | `user_id="u1"`, no `role` arg | Decoded `role == "user"` |
| SEC-12 | `create_access_token` | Extra claims are merged into payload | `extra_claims={"custom": "val"}` | Decoded `payload["custom"] == "val"` |
| SEC-13 | `create_access_token` | Extra claims can override `role` | `role="user"`, `extra_claims={"role": "admin"}` | Decoded `role == "admin"` |
| SEC-14 | `create_access_token` | Returns valid `datetime` for expiry | Any valid input | `isinstance(expires_at, datetime)`, `expires_at > now` |
| SEC-15 | `create_access_token` | Each call produces unique JTI | Two calls with same `user_id` | `jti1 != jti2` |
| SEC-16 | `create_refresh_token` | Payload contains required claims | `user_id="u1"` | Decoded has `sub="u1"`, `type="refresh"`, `jti` present |
| SEC-17 | `create_refresh_token` | Returns (token, expires_at, jti) tuple | `user_id="u1"` | All three values present and correctly typed |
| SEC-18 | `create_refresh_token` | JTI in decoded payload matches returned JTI | `user_id="u1"` | `decoded["jti"] == returned_jti` |
| SEC-19 | `decode_token` | Valid access token decodes correctly | Create access token → decode with `expected_type="access"` | Returns payload with all claims |
| SEC-20 | `decode_token` | Valid refresh token decodes correctly | Create refresh token → decode with `expected_type="refresh"` | Returns payload with `type="refresh"` |
| SEC-21 | `decode_token` | Invalid token raises `TokenError` | `token="not-a-jwt"` | `TokenError` raised with "Invalid token" message |
| SEC-22 | `decode_token` | Type mismatch raises `TokenError` | Access token decoded with `expected_type="refresh"` | `TokenError` raised with message about expected vs actual type |
| SEC-23 | `decode_token` | Logs error on invalid JWT | `token="garbage"` | `caplog` contains `"JWT Validation Error"` |
| SEC-24 | `decode_token` | Logs error on type mismatch | Access token, `expected_type="refresh"` | `caplog` contains `"Token type mismatch"` |
| SEC-25 | `generate_csrf_token` | Returns ~43 character URL-safe string | No input | `len(token) == 43` |
| SEC-26 | `generate_csrf_token` | Two tokens are unique | Two sequential calls | `token1 != token2` |
| SEC-27 | `generate_csrf_token` | Token contains only URL-safe characters | No input | Matches regex `^[A-Za-z0-9_-]+$` |

**Coverage Estimate**: 27 tests cover all 6 functions, all happy paths, all exception
paths (mismatch, JWTError, type mismatch), edge cases (empty, long, special chars),
and logging verification. Estimated coverage: **~95%**.

---

# 4. Backend File 2: auth_service.py

**File**: `apps/backend/app/services/auth_service.py`  
**Lines**: 301  
**Functions**: 9 (including `__init__`)  
**Test Framework**: `pytest` + `pytest-asyncio` + `unittest.mock`

## 4.1 File Overview

`AuthService` is the central authentication orchestrator. It coordinates:
- `UserRepository` — database CRUD for users and E2EE keys
- `TokenService` — JWT token pair generation and rotation
- `hash_password` / `verify_password` — Argon2id hashing

**All methods will be tested with fully mocked dependencies** — no real database or
external services. `UserRepository` and `TokenService` will be replaced with
`MagicMock`/`AsyncMock` instances.

## 4.2 Function Inventory

| # | Function | Lines | Purpose |
|---|----------|-------|---------|
| 1 | `__init__(settings, session)` | 31–39 | Initializes service with settings, DB session, UserRepository, and TokenService. |
| 2 | `register(*, email, client_auth_token, salt, wrapped_account_key, recovery_wrapped_ak)` | 41–107 | Registers a new user: checks uniqueness, hashes auth token, decodes salt, creates user + E2EE keys, generates token pair. |
| 3 | `login_challenge(*, email)` | 109–142 | Step 1 of login: returns user's salt (or fake salt for non-existent user to prevent enumeration). |
| 4 | `login_verify(*, email, client_auth_token)` | 144–188 | Step 2 of login: verifies auth token, retrieves E2EE keys, generates token pair. |
| 5 | `refresh_tokens(*, refresh_token)` | 190–206 | Delegates to TokenService to rotate refresh token. |
| 6 | `logout(*, user_id, token_jti, token_exp)` | 208–229 | Revokes the user's refresh token via TokenService. |
| 7 | `delete_account(*, user_id)` | 231–240 | Deletes user from DB. Returns bool. |
| 8 | `change_password(*, user_id, new_auth_token, new_wrapped_account_key)` | 242–261 | Updates password hash and wrapped AK in DB. |
| 9 | `recover_account(*, email, new_auth_token, new_wrapped_account_key)` | 263–300 | Recovers account: finds user by email, updates credentials, generates new token pair. |

## 4.3 Execution Path Analysis

| Function | Path | Description |
|----------|------|-------------|
| `register` | P1-Success | New email → create user + keys → generate tokens → commit → return dict |
| `register` | P1-DuplicateEmail | Email exists → `EmailExistsError` raised at line 67 |
| `register` | P1-UrlsafeSalt | Salt is valid urlsafe base64 → decoded via `urlsafe_b64decode` |
| `register` | P1-StandardSalt | Salt is standard base64 (urlsafe decode fails) → falls back to `b64decode` |
| `login_challenge` | P2-UserExists | User found → retrieve E2EE keys → return real salt + recovery wrapped AK |
| `login_challenge` | P2-UserNotExists | User not found → generate deterministic fake salt from email hash → return fake data |
| `login_challenge` | P2-KeysMissing | User exists but no E2EE keys → `KeysNotFoundError` raised |
| `login_verify` | P3-Success | User exists + correct token + keys present → return tokens + wrapped AK |
| `login_verify` | P3-UserNotExists | User not found → hash dummy token (timing protection) → `AuthError` raised |
| `login_verify` | P3-WrongToken | User found + wrong token → `AuthError` raised |
| `login_verify` | P3-KeysMissing | User found + correct token + no keys → `KeysNotFoundError` raised |
| `refresh_tokens` | P4-Success | Valid refresh token → delegate to TokenService → return new pair |
| `logout` | P5-Success | Revokes token via TokenService, logs "User logged out" |
| `delete_account` | P6-UserExists | User found → delete → commit → return `True` |
| `delete_account` | P6-UserNotExists | User not found → `_user_repo.delete` returns `False` → no commit → return `False` |
| `change_password` | P7-Success | Hash new token → update keys in DB → commit |
| `recover_account` | P8-Success | User found by email → update credentials → generate tokens → commit → return dict |
| `recover_account` | P8-UserNotFound | User not found → `AccountNotFoundError` raised |

## 4.4 Test Specification Table

| Test ID | Function Under Test | Test Purpose | Mocked Setup | Input | Expected Output |
|---------|-------------------|--------------|--------------|-------|-----------------|
| AUTH-01 | `__init__` | Service initializes with correct dependencies | Settings + Session | `AuthService(settings, session)` | `_settings`, `_session`, `_user_repo`, `_token_service` all set |
| AUTH-02 | `register` | Successful registration returns token dict | `get_by_email → None`, `create → User(id=UUID, role="user")`, `create_e2ee_keys → OK`, `generate_token_pair → {"access_token":..., "refresh_token":..., "access_expires_at":...}` | `email="new@example.com"`, `client_auth_token="token"`, `salt=urlsafe_b64("salt")`, `wrapped_account_key="wak"`, `recovery_wrapped_ak="rwak"` | Dict with `user_id`, `access_token`, `refresh_token`, `access_expires_at`; session.commit called |
| AUTH-03 | `register` | Duplicate email raises `EmailExistsError` | `get_by_email → User(...)` (already exists) | Any valid params with existing email | `EmailExistsError` raised |
| AUTH-04 | `register` | Standard base64 salt decoded via fallback | `get_by_email → None`; salt uses standard base64 that would cause urlsafe decode error | `salt="ab+c/d=="` | Salt is decoded (fallback `b64decode`), registration succeeds |
| AUTH-05 | `register` | Hashes the client auth token (not stored raw) | `get_by_email → None` | Any valid params | `create` called with `password_hash` starting with `$argon2id$` |
| AUTH-06 | `register` | E2EE keys stored with correct parameters | `get_by_email → None` | `wrapped_account_key="wak"`, `recovery_wrapped_ak="rwak"` | `create_e2ee_keys` called with matching `wrapped_account_key` and `recovery_wrapped_ak` |
| AUTH-07 | `login_challenge` | Existing user returns real salt | `get_by_email → User(id=UUID)`, `get_e2ee_keys → Keys(salt=bytes, recovery_wrapped_ak="rwak")` | `email="exists@example.com"` | Dict with base64-encoded `salt` and `recovery_wrapped_ak` |
| AUTH-08 | `login_challenge` | Non-existent user returns fake salt (anti-enumeration) | `get_by_email → None` | `email="ghost@example.com"` | Dict with `salt` (valid base64) and `recovery_wrapped_ak` (valid base64); no exception |
| AUTH-09 | `login_challenge` | Fake salt is deterministic per email | `get_by_email → None` | Same email called twice | Both returned `salt` values are identical |
| AUTH-10 | `login_challenge` | User exists but no keys raises `KeysNotFoundError` | `get_by_email → User(...)`, `get_e2ee_keys → None` | `email="nokeys@example.com"` | `KeysNotFoundError` raised |
| AUTH-11 | `login_verify` | Correct credentials return token dict + wrapped AK | `get_by_email → User(password_hash=hash_of("token"))`, `verify_password → True`, `get_e2ee_keys → Keys(wrapped_account_key="wak")` | `email="user@example.com"`, `client_auth_token="token"` | Dict with `user_id`, `access_token`, `refresh_token`, `wrapped_account_key="wak"` |
| AUTH-12 | `login_verify` | Non-existent user raises `AuthError` (timing-safe) | `get_by_email → None` | `email="ghost@example.com"`, `client_auth_token="any"` | `AuthError` raised; execution still takes non-trivial time (dummy hash) |
| AUTH-13 | `login_verify` | Wrong token raises `AuthError` | `get_by_email → User(...)`, `verify_password → False` | `email="user@example.com"`, `client_auth_token="wrong"` | `AuthError` raised |
| AUTH-14 | `login_verify` | User exists, correct token, but no keys raises `KeysNotFoundError` | `get_by_email → User(...)`, `verify_password → True`, `get_e2ee_keys → None` | Valid credentials | `KeysNotFoundError` raised |
| AUTH-15 | `refresh_tokens` | Delegates to TokenService and returns new pair | `rotate_refresh_token → {"access_token":"a", "refresh_token":"r", "access_expires_at": datetime}` | `refresh_token="old-rt"` | Dict with `access_token`, `refresh_token`, `access_expires_at` |
| AUTH-16 | `logout` | Calls `revoke_refresh_token` on TokenService | `revoke_refresh_token` is an `AsyncMock` | `user_id="u1"`, `token_jti="jti"`, `token_exp=1700000000.0` | `revoke_refresh_token` called with `token_jti="jti"`, `user_id="u1"`, and a `datetime` for `expires_at` |
| AUTH-17 | `logout` | Correctly converts float timestamp to UTC datetime | Same as above | `token_exp=1700000000.0` | `expires_at` argument is `datetime(2023, 11, 14, 22, 13, 20, tzinfo=utc)` |
| AUTH-18 | `delete_account` | Existing user deleted → returns True | `_user_repo.delete → True` | `user_id=str(uuid4())` | Returns `True`, `session.commit()` called |
| AUTH-19 | `delete_account` | Non-existent user → returns False | `_user_repo.delete → False` | `user_id=str(uuid4())` | Returns `False`, `session.commit()` NOT called |
| AUTH-20 | `change_password` | Updates hash and wrapped AK in DB | `update_e2ee_keys` is `AsyncMock` | `user_id=str(uuid4())`, `new_auth_token="new-token"`, `new_wrapped_account_key="new-wak"` | `update_e2ee_keys` called with matching UUID, hashed token (starts with `$argon2id$`), `wrapped_account_key="new-wak"`; `session.commit()` called |
| AUTH-21 | `recover_account` | Existing user recovery returns tokens + wrapped AK | `get_by_email → User(id=UUID, role="user")`, `update_e2ee_keys → OK`, `generate_token_pair → pair` | `email="user@example.com"`, `new_auth_token="new"`, `new_wrapped_account_key="new-wak"` | Dict with `user_id`, `access_token`, `refresh_token`, `wrapped_account_key="new-wak"`; `session.commit()` called |
| AUTH-22 | `recover_account` | Non-existent user raises `AccountNotFoundError` | `get_by_email → None` | `email="ghost@example.com"` | `AccountNotFoundError` raised |
| AUTH-23 | `recover_account` | Password is hashed before storage | `get_by_email → User(...)` | `new_auth_token="new-token"` | `update_e2ee_keys` receives `password_hash` starting with `$argon2id$` |

**Coverage Estimate**: 23 tests cover all 9 functions, all branching paths (success, error,
exception), salt decoding fallback, timing-safe dummy hash, and DB commit/no-commit
verification. Estimated coverage: **~92%**.

---

# Summary Statistics

| File | Functions | Tests | Paths Covered | Est. Coverage |
|------|-----------|-------|---------------|---------------|
| `cryptography_service.dart` | 8+1 | 24 | 16/16 | ~95% |
| `chat_controller.dart` | 9 | 26 | 26/26 | ~90% |
| `security.py` | 6 | 27 | 15/15 | ~95% |
| `auth_service.py` | 9 | 23 | 18/18 | ~92% |
| **Total** | **33** | **100** | **75/75** | **~93%** |

> All 100 unit tests are designed to be **isolated** — frontend tests mock the
> `ChatRepository` and `GuestService`, backend tests mock `UserRepository` and
> `TokenService`. No test requires network connectivity or external services.

---

# Test Execution Scripts

To simplify running the frontend and backend test suites independently, two
standalone scripts should be created. Each script runs the relevant tests in
isolation, reports results, and exits with a non-zero code on failure (suitable
for CI/CD integration).

## Frontend Test Script

**File to create**: `apps/frontend/scripts/run_tests.sh`

### Purpose

Runs only the two P5 frontend unit-test files with coverage enabled:

| Test File | Tests |
|-----------|-------|
| `test/core/services/cryptography_service_test.dart` | CS-01 … CS-24 |
| `test/features/chat/application/chat_controller_test.dart` | CC-01 … CC-26 |

### Script Behavior

1. Navigate to `apps/frontend/`.
2. Run `flutter test` targeting the two P5 test files explicitly.
3. Enable coverage collection (`--coverage`).
4. Print a pass/fail summary.
5. Exit with code `0` on success, `1` on failure.


### Usage

```bash
chmod +x apps/frontend/scripts/run_tests.sh
./apps/frontend/scripts/run_tests.sh
```

---

## Backend Test Script

**File to create**: `apps/backend/scripts/run_p5_tests.sh`

### Purpose

Runs only the two P5 backend unit-test files with coverage enabled:

| Test File | Tests |
|-----------|-------|
| `tests/test_security.py` | SEC-01 … SEC-27 |
| `tests/test_auth_service.py` | AUTH-01 … AUTH-23 |

### Script Behavior

1. Navigate to `apps/backend/`.
2. Activate the virtual environment (if present).
3. Run `pytest` targeting the two P5 test files with verbose output and
   coverage (`--cov`).
4. Print a pass/fail summary.
5. Exit with code `0` on success, `1` on failure.


### Usage

```bash
chmod +x apps/backend/scripts/run_p5_tests.sh
./apps/backend/scripts/run_p5_tests.sh
```

---

## Running Both Suites Together

For convenience, a top-level script can chain both:

**File to create**: `tools/dev/run_all_p5_tests.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running Frontend P5 Tests..."
"$REPO_ROOT/apps/frontend/scripts/run_tests.sh"
FRONTEND_EXIT=$?

echo ""
echo "Running Backend P5 Tests..."
"$REPO_ROOT/apps/backend/scripts/run_p5_tests.sh"
BACKEND_EXIT=$?

echo ""
echo "========================================"
echo " Combined P5 Results"
echo "========================================"
[ $FRONTEND_EXIT -eq 0 ] && echo "  Frontend: ✅ PASS" || echo "  Frontend: ❌ FAIL"
[ $BACKEND_EXIT  -eq 0 ] && echo "  Backend:  ✅ PASS" || echo "  Backend:  ❌ FAIL"

[ $FRONTEND_EXIT -eq 0 ] && [ $BACKEND_EXIT -eq 0 ] && exit 0 || exit 1
```
