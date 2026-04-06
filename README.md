# Spiritual Q&A Platform

**Course**: CS 698 - Software Engineering
**Organization**: Non-Profit Spiritual Organization
**Last Updated**: February 15, 2026

---

## 🎯 Project Overview

A spiritual/philosophical Q&A application that provides answers based strictly on the organization's proprietary texts using Retrieval-Augmented Generation (RAG).

## 📂 Repository Structure

```text
/
├── backend/                # FastAPI (Python) - RAG & Auth Services
├── frontend/               # Flutter (Dart) - Cross-platform Client
├── docs/                   # Documentation
│   ├── specs/              # Detailed Developer Specifications
│   ├── ARCHITECTURE.md     # System Design
│   └── openapi.yaml        # API Contract
├── prototypes/             # Reference Implementations
│   └── figma_generated_ui/ # Original React/Vite UI Prototype
└── scripts/                # Utility Scripts
```

## 🚀 Getting Started

### Backend (Python)

```bash
cd backend
poetry install
poetry run uvicorn app.main:app --reload
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

## 🧪 Testing

To easily reproduce and run the tests, developers can use the provided dev container, as it comes pre-installed with all necessary frameworks and testing libraries.

### Backend (Python)

**Framework & Libraries:**
- **pytest:** The primary testing framework.
- **pytest-cov:** For measuring code coverage.
- **pytest-asyncio:** For testing asynchronous code.
- **httpx:** Used as an async HTTP client for integration and endpoint testing.
- **mutmut:** Used for mutation testing.

**How to Run Tests:**
To manually run the backend tests, execute the following script:
```bash
/workspaces/cs698-repo/backend/scripts/run_p5_tests.sh
```

### Frontend (Flutter)

**Framework & Libraries:**
- **flutter_test:** Flutter's built-in testing framework.
- **mocktail:** Library used for creating mock objects to ensure isolated testing.
- **integration_test:** SDK package for end-to-end device testing.

**How to Run Tests:**
To manually run the frontend unit tests, execute the following script:
```bash
/workspaces/cs698-repo/frontend/scripts/run_tests.sh
```

### Run All Tests

To run both the frontend and backend tests at once, execute the master script:
```bash
/workspaces/cs698-repo/scripts/run_all_p5_tests.sh
```

## 📚 Documentation

- [Architecture](./docs/ARCHITECTURE.md)
- [API Specification](./docs/openapi.yaml)
- [RAG Spec](./docs/specs/Issue%20#1%20Devspec)
- [Auth Spec](./docs/specs/Issue%20#2%20Devspec)
- [Flutter Spec](./docs/specs/Issue%20#3%20Devspec)
- [Security Roadmap](./docs/SECURITY_ROADMAP.md)

---
**Built according to POUR standards**

**Built with ❤️ for spiritual seekers worldwide**
