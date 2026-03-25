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
