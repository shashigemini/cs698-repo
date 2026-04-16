---
title: "Introduction"
sidebar_position: 1
---

# Spiritual Q&A Platform

Welcome to the **Spiritual Q&A Platform Documentation Hub**. This site serves as the "source of truth" for the application's architecture, development practices, and API specifications.

## 🎯 Project Overview

A spiritual/philosophical Q&A application that provides answers based strictly on the organization's proprietary texts using Retrieval-Augmented Generation (RAG).

The platform uses a monolithic backend built with **FastAPI**, backed by **PostgreSQL** and **Qdrant**, serving cross-platform clients built in **Flutter**.

## 🚀 Quick Start

If you are a new developer joining the project, start here:

1. **[Architecture](./architecture)**: Understand the layered structure, deployment mechanisms, and data models.
2. **[Auth Module](./modules/auth)**: Learn about the End-to-End Encryption (E2EE) authentication system.
3. **[RAG Module](./modules/rag)**: Dive into the core inference and retrieval engine.
4. **[State Management](./state-management)**: Learn how we handle global and ephemeral state.
5. **[Testing](./testing)**: Review our testing strategies and stability rules.
6. **[Security](./security)**: Understand threat models and our zero-log policies.
7. **[API Reference](/api)**: Browse the interactive OpenAPI specification.

## Core Principles

- **Immutability First**: Domain models and application states are strictly immutable.
- **Tests as Documentation**: Integration tests describe intended behavior and user flows.
- **Premium Aesthetics**: UI must feel polished, responsive, and follow the organization's design guidelines.
- **Zero-Log Diagnostics**: All diagnostic logs are scrubbed of sensitive PII.
