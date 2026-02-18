# Sacred Wisdom - Spiritual Q&A Platform (Frontend)

A modern web application for the **Sacred Wisdom** platform - a spiritual Q&A system that provides answers based strictly on proprietary spiritual texts using RAG (Retrieval-Augmented Generation).

## 🎯 Project Overview

This is the React/TypeScript implementation of **Issue #3 - Seamless Mobile/Web Access** from the CS 698 Software Engineering project. While the original devspec calls for a Flutter implementation supporting Web/iOS/Android, this is a web-focused implementation using React and Tailwind CSS.

### Key Features

- **🙏 Dual Access Modes**
  - **Guest Mode**: Anonymous access with 10 queries per 24-hour rolling window
  - **Authenticated Mode**: Unlimited access with persistent conversation history

- **📚 RAG-Based Answers**: All responses are grounded in spiritual texts including:
  - Bhagavad Gita Commentary
  - The Dhammapada: The Path of Truth
  - Tao Te Ching: The Way of Virtue
  - Buddhist Teachings on Loving-Kindness
  - Noble Eightfold Path
  - And other sacred texts

- **✨ Modern UI/UX**
  - Clean, contemplative design with indigo/purple color scheme
  - Responsive layout for mobile, tablet, and desktop
  - Real-time typing indicators
  - Toast notifications for user feedback
  - Smooth animations and transitions

- **📖 Citations**: Every answer includes document references with:
  - Document title
  - Page number
  - Relevance score (0-100%)

## 🏗️ Architecture

### Technology Stack

- **Frontend Framework**: React 18.3.1 with TypeScript
- **Styling**: Tailwind CSS v4
- **UI Components**: Custom component library built on Radix UI primitives
- **State Management**: React useState and useEffect hooks
- **Icons**: Lucide React
- **Notifications**: Sonner (toast notifications)
- **Build Tool**: Vite

### Application Flow

```
StartupScreen (1.5s)
  ↓
  Check stored tokens
  ↓
  ├─ Valid tokens? → ChatScreen (Authenticated)
  └─ No tokens? → AuthScreen (Guest mode option)
      ↓
      ├─ Login/Register → ChatScreen (Authenticated)
      └─ Continue as Guest → ChatScreen (Guest mode)
```

### State Management

- **Authentication State**: User object, auth status (initializing/guest/authenticated)
- **Guest Session**: UUID v4 stored in localStorage for rate limiting
- **Token Storage**: Mock JWT tokens in localStorage (simulating secure storage)
- **Conversation State**: Message history, remaining queries, conversation ID

## 🎨 UI Components

### Screens

1. **StartupScreen** (`/src/app/components/StartupScreen.tsx`)
   - Loading animation with Sacred Wisdom branding
   - Token validation simulation (1.5 seconds)

2. **AuthScreen** (`/src/app/components/AuthScreen.tsx`)
   - Login/Register tabs
   - Email and password validation
   - Password strength indicator
   - Guest mode option ("Continue as Guest" button)
   - Beautiful gradient background

3. **ChatScreen** (`/src/app/components/ChatScreen.tsx`)
   - Main chat interface
   - Message bubbles (user and assistant)
   - Citations with document references
   - Rate limit banner for guest users
   - Input field with character counter (max 2000 chars)
   - New conversation button (authenticated only)

### Key Features

- **Password Validation**
  - Min 8 characters
  - At least 1 uppercase letter
  - At least 1 lowercase letter
  - At least 1 digit
  - At least 1 special character (!@#$%^&*)

- **Rate Limiting (Guest Mode)**
  - 10 queries per 24-hour rolling window
  - Visual indicator showing remaining queries
  - Modal when limit reached prompting sign-in

- **Responsive Design**
  - Mobile: < 600px (single column, bottom navigation)
  - Tablet: 600-1024px (optimized layout)
  - Desktop: > 1024px (full-width chat interface)

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ or Bun
- Modern web browser

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

### Environment

No environment variables required for the frontend demo. All backend calls are mocked.

## 📝 Implementation Details

### Mock Data

The application uses realistic mock data to simulate the RAG backend:

- **Spiritual Answers**: 6 different answers covering topics like:
  - Karma and the law of cause and effect
  - Compassion and loving-kindness
  - Mindfulness and present-moment awareness
  - Dharma and duty
  - The path to enlightenment
  - Detachment and equanimity

- **Citations**: Realistic references to spiritual texts with page numbers and relevance scores

### Authentication Flow (Mock)

1. **Registration/Login**
   - Validates email format (RFC 5322)
   - Validates password complexity
   - Generates mock JWT tokens
   - Stores tokens in localStorage

2. **Token Management**
   - Access token: 15-minute expiry
   - Refresh token: 7-day expiry
   - Tokens stored in localStorage (simulating secure storage)

3. **Guest Mode**
   - Generates UUID v4 for guest_session_id
   - Tracks remaining queries (10 per day)
   - No conversation history persistence

### Error Handling

The application follows the error code specifications from the backend:

- `INVALID_CREDENTIALS`: Invalid email or password
- `EMAIL_ALREADY_EXISTS`: Email already registered
- `VALIDATION_ERROR`: Input validation failed
- `RATE_LIMIT_EXCEEDED`: Guest query limit reached
- `UNAUTHORIZED`: Invalid or expired token

## 🔒 Security

### Input Validation

- **Email**: RFC 5322 format, max 255 characters
- **Password**: Complexity requirements enforced
- **Query**: 1-2000 characters, trimmed

### Token Storage

- Mock JWT tokens stored in localStorage
- Guest session ID stored in localStorage
- In production, would use:
  - Web: HttpOnly cookies with CSRF protection
  - Mobile: Keychain (iOS) / KeyStore (Android)

## 🎯 Alignment with Devspec

This implementation faithfully follows the **Issue #3 Devspec** specifications:

- ✅ Startup screen with token validation
- ✅ AuthScreen with Login/Register tabs and guest option
- ✅ ChatScreen with guest and authenticated modes
- ✅ Guest mode banner showing remaining queries
- ✅ Rate limiting (10 queries/day for guests)
- ✅ Password strength indicator
- ✅ Character counter (2000 max)
- ✅ Citations with document references
- ✅ Responsive design
- ✅ Toast notifications
- ✅ Modal dialogs for confirmations

### Deviations

- **Platform**: Web-only (React) instead of Flutter (Web/iOS/Android)
- **Backend**: Mock API calls instead of real FastAPI backend
- **Storage**: localStorage instead of platform-specific secure storage
- **State Management**: React hooks instead of Riverpod/Bloc

## 📚 Related Documentation

- [Main README](https://github.com/shashigemini/cs698-repo/blob/main/README.md)
- [Architecture Document](https://github.com/shashigemini/cs698-repo/blob/main/ARCHITECTURE.md)
- [Issue #1 - Core RAG](https://github.com/shashigemini/cs698-repo/blob/main/Issue%20%231%20Devspec)
- [Issue #2 - Authentication](https://github.com/shashigemini/cs698-repo/blob/main/Issue%20%232%20Devspec)
- [Issue #3 - Flutter Interface](https://github.com/shashigemini/cs698-repo/blob/main/Issue%20%233%20Devspec)

## 🤝 Contributing

This is a course project for CS 698 - Software Engineering at NJIT.

### Code Style

- React components use functional components with hooks
- TypeScript for type safety
- Tailwind CSS for styling
- ESLint for code quality

## 📄 License

Proprietary - All rights reserved by the Non-Profit Spiritual Organization.

## 🙏 Acknowledgments

Built with reverence for the spiritual wisdom traditions of:
- The Bhagavad Gita
- The Dhammapada
- The Tao Te Ching
- Buddhist teachings
- And other sacred texts

---

**Built with ❤️ for spiritual seekers worldwide**
