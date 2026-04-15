# OpenAPI Specification Usage Guide

**File**: [`openapi.yaml`](../openapi.yaml)  
**Version**: OpenAPI 3.1.0  
**Last Updated**: February 15, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Viewing the Spec](#viewing-the-spec)
3. [Generating Client SDKs](#generating-client-sdks)
4. [Testing with Swagger UI](#testing-with-swagger-ui)
5. [Integrating with Development](#integrating-with-development)
6. [Validation and Linting](#validation-and-linting)
7. [CI/CD Integration](#cicd-integration)

---

## Overview

The OpenAPI specification provides:
- ✅ Complete API documentation for all 5 endpoints
- ✅ Request/response schemas with validation rules
- ✅ All 13 error codes with examples
- ✅ Authentication flows (JWT Bearer tokens)
- ✅ Rate limiting documentation
- ✅ Interactive examples for testing

### Endpoints Documented

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/register` | POST | Register new user |
| `/auth/login` | POST | Login user |
| `/auth/refresh` | POST | Refresh access token |
| `/auth/logout` | POST | Logout user |
| `/api/chat/query` | POST | Submit query and get AI answer |
| `/health` | GET | Health check |

---

## Viewing the Spec

### Option 1: Swagger UI (Local)

**Quick Start**:
```bash
# Using Docker
docker run -p 8080:8080 \
  -e SWAGGER_JSON=/openapi.yaml \
  -v $(pwd)/openapi.yaml:/openapi.yaml \
  swaggerapi/swagger-ui

# Visit: http://localhost:8080
```

**Using NPM**:
```bash
npm install -g swagger-ui-dist
swagger-ui-dist -p 8080 -s openapi.yaml
```

### Option 2: Swagger Editor (Online)

1. Go to [editor.swagger.io](https://editor.swagger.io)
2. Click **File > Import File**
3. Upload `openapi.yaml`
4. Edit and validate in real-time

### Option 3: Redoc (Beautiful Docs)

```bash
# Using Docker
docker run -p 8080:80 \
  -e SPEC_URL=https://raw.githubusercontent.com/shashigemini/cs698-repo/main/openapi.yaml \
  redocly/redoc

# Visit: http://localhost:8080
```

### Option 4: VS Code Extension

1. Install extension: **OpenAPI (Swagger) Editor**
2. Open `openapi.yaml`
3. Right-click > **Preview Swagger**

---

## Generating Client SDKs

### For Frontend (Dart/Flutter)

**Using openapi-generator**:
```bash
# Install generator
brew install openapi-generator  # macOS
# or
npm install -g @openapitools/openapi-generator-cli

# Generate Dart client
openapi-generator generate \
  -i openapi.yaml \
  -g dart \
  -o apps/frontend/lib/generated/api_client \
  --additional-properties=pubName=spiritual_qa_api

# Add to pubspec.yaml
# dependencies:
#   spiritual_qa_api:
#     path: lib/generated/api_client
```

**Usage in Flutter**:
```dart
import 'package:spiritual_qa_api/api.dart';

final api = DefaultApi(
  ApiClient(basePath: 'http://localhost:8000')
);

// Register user
try {
  final response = await api.registerUser(
    registerRequest: RegisterRequest(
      email: 'user@example.com',
      password: 'SecurePass123!',
    ),
  );
  print('User ID: ${response.userId}');
} catch (e) {
  print('Error: $e');
}

// Submit query
final queryResponse = await api.submitQuery(
  queryRequest: QueryRequest(
    query: 'What is karma?',
    guestSessionId: 'uuid...',
  ),
);
print('Answer: ${queryResponse.answer}');
```

### For Backend Testing (Python)

**Using openapi-python-client**:
```bash
pip install openapi-python-client

openapi-python-client generate \
  --path openapi.yaml \
  --config generator-config.yaml
```

**Usage**:
```python
from spiritual_qa_client import Client
from spiritual_qa_client.api.authentication import register_user
from spiritual_qa_client.models import RegisterRequest

client = Client(base_url="http://localhost:8000")

# Register user
request = RegisterRequest(
    email="user@example.com",
    password="SecurePass123!"
)
response = register_user.sync(client=client, json_body=request)
print(f"User ID: {response.user_id}")
```

### For Admin Panel (TypeScript/React)

**Using openapi-typescript-codegen**:
```bash
npx openapi-typescript-codegen \
  --input openapi.yaml \
  --output ./src/api \
  --client axios
```

**Usage**:
```typescript
import { AuthenticationService, ChatService } from './api';

// Login
const authResponse = await AuthenticationService.loginUser({
  email: 'user@example.com',
  password: 'SecurePass123!',
});

// Submit query
const queryResponse = await ChatService.submitQuery({
  query: 'What is karma?',
  conversationId: null,
  guestSessionId: null,
});
console.log(queryResponse.answer);
```

---

## Testing with Swagger UI

### Step 1: Start Backend
```bash
cd apps/backend
uvicorn app.main:app --reload
```

### Step 2: Start Swagger UI
```bash
docker run -p 8080:8080 \
  -e SWAGGER_JSON=/openapi.yaml \
  -v $(pwd)/openapi.yaml:/openapi.yaml \
  swaggerapi/swagger-ui
```

### Step 3: Test Endpoints

1. **Open Swagger UI**: http://localhost:8080
2. **Register User**:
   - Expand `POST /auth/register`
   - Click **Try it out**
   - Fill in email and password
   - Click **Execute**
   - Copy `access_token` from response

3. **Authorize**:
   - Click **Authorize** button (top right)
   - Enter: `Bearer <access_token>`
   - Click **Authorize**

4. **Submit Query**:
   - Expand `POST /api/chat/query`
   - Click **Try it out**
   - Fill in query
   - Click **Execute**
   - View answer and citations

---

## Integrating with Development

### Backend Validation (FastAPI)

FastAPI automatically generates OpenAPI spec at `/docs` and `/openapi.json`. Compare with our spec:

```bash
# Start backend
uvicorn app.main:app --reload

# View auto-generated spec
curl http://localhost:8000/openapi.json > generated-openapi.json

# Compare with our spec
diff openapi.yaml generated-openapi.json
```

**Keep them in sync**:
- Update `openapi.yaml` when API changes
- Use Pydantic models that match OpenAPI schemas
- Add OpenAPI examples to FastAPI routes

### Frontend Contract Testing

**Using Dredd**:
```bash
npm install -g dredd

# Test API against spec
dredd openapi.yaml http://localhost:8000
```

**Using Prism (Mock Server)**:
```bash
# Install Prism
npm install -g @stoplight/prism-cli

# Start mock server
prism mock openapi.yaml

# Backend runs on: http://localhost:4010
# Test frontend against mock before real backend is ready
```

---

## Validation and Linting

### Using Spectral (Recommended)

**Install**:
```bash
npm install -g @stoplight/spectral-cli
```

**Validate**:
```bash
# Basic validation
spectral lint openapi.yaml

# Custom rules (.spectral.yaml)
spectral lint openapi.yaml --ruleset .spectral.yaml
```

**Custom Rules** (`.spectral.yaml`):
```yaml
extends: [[spectral:oas, all]]
rules:
  operation-description: error
  operation-tags: error
  operation-operationId: error
  info-contact: error
  info-license: error
```

### Using openapi-spec-validator (Python)

```bash
pip install openapi-spec-validator

# Validate
openapi-spec-validator openapi.yaml
```

### Using Swagger CLI

```bash
npm install -g @apidevtools/swagger-cli

# Validate
swagger-cli validate openapi.yaml
```

---

## CI/CD Integration

### GitHub Actions Workflow

**`.github/workflows/openapi-validation.yml`**:
```yaml
name: Validate OpenAPI Spec

on:
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'apps/backend/**'
  push:
    branches:
      - main

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install Spectral
        run: npm install -g @stoplight/spectral-cli
      
      - name: Validate OpenAPI Spec
        run: spectral lint openapi.yaml
      
      - name: Check for Breaking Changes
        uses: oasdiff/oasdiff-action@v0.0.15
        with:
          base: ${{ github.base_ref }}
          revision: ${{ github.head_ref }}
          format: text
  
  test-contract:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Start Backend
        run: |
          cd apps/backend
          pip install -r requirements.txt
          uvicorn app.main:app --host 0.0.0.0 --port 8000 &
          sleep 10
      
      - name: Install Dredd
        run: npm install -g dredd
      
      - name: Test API Contract
        run: dredd openapi.yaml http://localhost:8000
```

### Pre-commit Hook

**`.pre-commit-config.yaml`**:
```yaml
repos:
  - repo: https://github.com/stoplightio/spectral
    rev: v6.11.0
    hooks:
      - id: spectral
        args: ['lint', 'openapi.yaml']
```

**Install**:
```bash
pip install pre-commit
pre-commit install
```

---

## Advanced Usage

### Splitting Large Specs

For maintainability, split into multiple files:

**openapi.yaml**:
```yaml
openapi: 3.1.0
info:
  title: Spiritual Q&A Platform API
  version: 1.0.0

paths:
  $ref: './paths/index.yaml'

components:
  schemas:
    $ref: './components/schemas/index.yaml'
  securitySchemes:
    $ref: './components/security.yaml'
```

**Merge for distribution**:
```bash
npm install -g @apidevtools/swagger-cli
swagger-cli bundle openapi.yaml --outfile openapi-bundled.yaml
```

### Versioning Strategy

**Semantic Versioning**:
- **Major** (1.x.x): Breaking changes (remove endpoint, change response structure)
- **Minor** (x.1.x): Backward-compatible additions (new endpoint, new optional field)
- **Patch** (x.x.1): Bug fixes (documentation updates, example corrections)

**URL Versioning** (future):
```yaml
servers:
  - url: https://api.example.com/v1
  - url: https://api.example.com/v2
```

### Generating API Documentation Site

**Using Redocly**:
```bash
npx @redocly/cli build-docs openapi.yaml \
  --output docs/api/index.html
```

**Deploy to GitHub Pages**:
```yaml
# .github/workflows/deploy-docs.yml
name: Deploy API Docs

on:
  push:
    branches:
      - main
    paths:
      - 'openapi.yaml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docs
        run: npx @redocly/cli build-docs openapi.yaml -o index.html
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./
```

---

## Troubleshooting

### Common Issues

**Issue**: Spectral validation errors
```
Error: operation-description - Operation description is required
```
**Solution**: Add descriptions to all endpoints and operations

---

**Issue**: Client generation fails
```
Error: Unknown type 'ErrorResponse'
```
**Solution**: Ensure all `$ref` references are valid and schemas are defined

---

**Issue**: Swagger UI shows "Failed to load API definition"
```
Fetch error: undefined
```
**Solution**: 
1. Check CORS settings on backend
2. Verify OpenAPI spec is valid YAML
3. Ensure server URLs are correct

---

**Issue**: Dredd tests fail
```
Fail: POST /auth/register - Expected 200, got 422
```
**Solution**: Check request body matches spec exactly (including required fields)

---

## Best Practices

### Maintaining Spec

✅ **DO**:
- Update spec before implementing API changes
- Add examples for all request/response bodies
- Document all error codes with examples
- Use semantic versioning
- Validate spec on every commit (CI/CD)

❌ **DON'T**:
- Make breaking changes without major version bump
- Add undocumented endpoints
- Remove fields without deprecation period
- Skip examples (they're crucial for client generation)

### Security

✅ **DO**:
- Document authentication requirements clearly
- Mark sensitive fields (passwords) as `format: password`
- Include rate limiting documentation
- Document CORS requirements

❌ **DON'T**:
- Include example secrets or tokens in spec
- Expose internal error details in examples
- Document admin-only endpoints in public spec

---

## Resources

### Tools
- [Swagger Editor](https://editor.swagger.io) - Online editor
- [Redoc](https://redocly.com/redoc) - Beautiful API docs
- [Spectral](https://stoplight.io/open-source/spectral) - Linter
- [Prism](https://stoplight.io/open-source/prism) - Mock server
- [OpenAPI Generator](https://openapi-generator.tech) - Client generation

### Documentation
- [OpenAPI 3.1 Spec](https://spec.openapis.org/oas/v3.1.0)
- [Swagger Guide](https://swagger.io/docs/specification/about/)
- [Best Practices](https://swagger.io/resources/articles/best-practices-in-api-design/)

### Community
- [OpenAPI Slack](https://open-api.slack.com)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/openapi)

---

## Next Steps

1. ✅ **Validate Spec**: Run `spectral lint openapi.yaml`
2. ✅ **View in Swagger UI**: Start Docker container
3. ✅ **Generate Client**: Create Dart SDK for Flutter
4. ✅ **Add to CI/CD**: Set up GitHub Actions validation
5. ✅ **Deploy Docs**: Build and host API documentation

**Questions?** Open an issue in the repository or contact the development team.
