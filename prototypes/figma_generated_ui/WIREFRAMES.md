# Sacred Wisdom - Application Wireframes

## Overview
This document provides wireframe layouts for all screens in the Sacred Wisdom application.

---

## 1. Startup Screen (Loading Screen)

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│                                                               │
│                                                               │
│                        ┌─────────┐                           │
│                        │         │                           │
│                        │  📱💬   │  (Icon: MessageSquare)    │
│                        │         │                           │
│                        └─────────┘                           │
│                                                               │
│                                                               │
│                    Sacred Wisdom                              │
│                                                               │
│              Your AI guide to spiritual texts                │
│                                                               │
│                                                               │
│                   ───────────────────                         │
│                   [Loading Animation]                         │
│                       Loading...                              │
│                                                               │
│                                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- Centered layout
- Gradient icon container with MessageSquare icon
- App title (Sacred Wisdom)
- Tagline
- Progress bar with animation
- Loading text

**Background:** Purple-100 → Blue-50 → Teal-50 gradient

---

## 2. Authentication Screen

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│                        ┌─────────┐                           │
│                        │  📱💬   │                           │
│                        └─────────┘                           │
│                                                               │
│                    Sacred Wisdom                              │
│              Your AI guide to spiritual texts                │
│                                                               │
│     ┌───────────────────────────────────────────────┐       │
│     │  ┌────────────┬────────────┐                  │       │
│     │  │   Login    │  Register  │  (Tabs)          │       │
│     │  └────────────┴────────────┘                  │       │
│     │                                                │       │
│     │  Email                                         │       │
│     │  ┌──────────────────────────────────────┐    │       │
│     │  │ 📧 you@example.com                   │    │       │
│     │  └──────────────────────────────────────┘    │       │
│     │                                                │       │
│     │  Password                                      │       │
│     │  ┌──────────────────────────────────────┐    │       │
│     │  │ 🔒 ••••••••                      👁  │    │       │
│     │  └──────────────────────────────────────┘    │       │
│     │                                                │       │
│     │  [Password Strength Indicator - Register]     │       │
│     │  [✓] 8+ characters                            │       │
│     │  [✓] Uppercase letter                         │       │
│     │  [✗] Number                                   │       │
│     │                                                │       │
│     │  ┌──────────────────────────────────────┐    │       │
│     │  │        Login / Create Account         │    │       │
│     │  └──────────────────────────────────────┘    │       │
│     │                                                │       │
│     │               ─────── OR ───────              │       │
│     │                                                │       │
│     │  ┌──────────────────────────────────────┐    │       │
│     │  │       Continue as Guest               │    │       │
│     │  └──────────────────────────────────────┘    │       │
│     │  Limited to 10 queries per day                │       │
│     │                                                │       │
│     └───────────────────────────────────────────────┘       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Components:**

### Login Tab:
- Email input with icon
- Password input with show/hide toggle
- Error message display area
- Login button (Teal gradient)
- Divider
- Guest mode button (Outline)
- Helper text

### Register Tab:
- Email input with icon
- Password input with show/hide toggle
- Password strength indicator (3-bar visual)
- Password requirements checklist:
  - 8+ characters
  - Uppercase letter
  - Lowercase letter
  - Number
  - Special character
- Create Account button (Teal gradient)
- Divider
- Guest mode button (Outline)
- Helper text

**Background:** Purple-100 → Blue-50 → Teal-50 gradient
**Card:** White/90 with backdrop blur, rounded corners

---

## 3. Chat Screen - Empty State

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  📚 Sacred Wisdom                           ☰ Menu     │ │ Header
│ └─────────────────────────────────────────────────────────┘ │
│                                                               │
│                                                               │
│                        ┌─────────┐                           │
│                        │         │                           │
│                        │  💬 📝  │  (Icon)                   │
│                        │         │                           │
│                        └─────────┘                           │
│                                                               │
│                 Ask about spiritual texts                    │
│                                                               │
│        Explore wisdom from the Bhagavad Gita,                │
│        Dhammapada, Tao Te Ching, and other sacred texts.    │
│                                                               │
│     ┌─────────────────────────────────────────────────┐     │
│     │ What does the Bhagavad Gita teach about karma? │     │
│     └─────────────────────────────────────────────────┘     │
│     ┌─────────────────────────────────────────────────┐     │
│     │ Explain the Buddhist concept of mindfulness    │     │
│     └─────────────────────────────────────────────────┘     │
│     ┌─────────────────────────────────────────────────┐     │
│     │ What is dharma and why is it important?        │     │
│     └─────────────────────────────────────────────────┘     │
│     ┌─────────────────────────────────────────────────┐     │
│     │ How do I cultivate compassion...                │     │
│     └─────────────────────────────────────────────────┘     │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ┌───────────────────────────────────────────────────┐   │ │
│ │ │ Ask a question about spiritual texts...         │   │ │
│ │ │                                                   │   │ │
│ │ │                                              [📤] │   │ │ Input
│ │ └───────────────────────────────────────────────────┘   │ │ Area
│ │ Press Enter to send, Shift+Enter...      0 / 2000       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- **Header:** App logo + title, Menu button
- **Empty State:**
  - Gradient icon container
  - Heading
  - Description text
  - 6 suggestion cards (glass effect)
- **Input Area:**
  - Textarea with border
  - Send button (gradient, bottom-right)
  - Helper text and character counter

**Layout:**
- Max width: 4xl (896px) centered
- Full height screen with flex column

---

## 4. Chat Screen - With Messages

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  📚 Sacred Wisdom                           ☰ Menu     │ │ Header
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                                                           │ │
│ │                         ┌─────────────────────────────┐  │ │
│ │                         │ What is karma?               │  │ │ User
│ │                         │                              │  │ │ Message
│ │                         │                        10:30 │  │ │
│ │                         └─────────────────────────────┘  │ │
│ │                                                           │ │
│ │  ┌────────────────────────────────────────────────────┐  │ │
│ │  │ According to the Bhagavad Gita, karma is the law  │  │ │
│ │  │ of cause and effect that governs all action...    │  │ │ Assistant
│ │  │                                                     │  │ │ Message
│ │  │ ────────────────                                   │  │ │
│ │  │ Sources:                                           │  │ │
│ │  │ 🔗 Bhagavad Gita Commentary, p. 42 (95% relevant) │  │ │
│ │  │ 🔗 The Dhammapada: Path of Truth, p. 1            │  │ │
│ │  │                                              10:30 │  │ │
│ │  └────────────────────────────────────────────────────┘  │ │
│ │                                                           │ │
│ │                         ┌─────────────────────────────┐  │ │
│ │                         │ Tell me more about dharma    │  │ │ User
│ │                         │                        10:31 │  │ │ Message
│ │                         └─────────────────────────────┘  │ │
│ │                                                           │ │
│ │  ┌────────────────────────────┐                         │ │
│ │  │ ● ● ●                      │  (Typing indicator)     │ │
│ │  └────────────────────────────┘                         │ │
│ │                                                           │ │
│ └─────────────────────────────────────────────────────────┘ │
├───────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ┌───────────────────────────────────────────────────┐   │ │
│ │ │ Ask a question about spiritual texts...         │   │ │
│ │ │                                                   │   │ │ Input
│ │ │                                              [📤] │   │ │ Area
│ │ └───────────────────────────────────────────────────┘   │ │
│ │ Press Enter to send, Shift+Enter...      0 / 2000       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Message Components:**

### User Message (Right-aligned):
- Teal-to-cyan gradient background
- White text
- Max width: 85% (mobile) / 75% (desktop)
- Timestamp at bottom
- Rounded corners (xl)

### Assistant Message (Left-aligned):
- White/90 background with backdrop blur
- Gray text
- Citations section with border-top
- Source links with external link icons
- Relevance scores
- Timestamp at bottom
- Rounded corners (xl)

### Typing Indicator:
- White background
- Three bouncing dots
- Animated with staggered delays

---

## 5. App Menu (Sidebar) - Guest Mode

```
┌──────────────────────────────────────┐
│                                      │
│  ┌─────────────────────────────┐    │
│  │       ┌────────┐             │    │
│  │       │   👤   │             │    │
│  │       └────────┘             │    │
│  │                              │    │
│  │      Guest User              │    │
│  │                              │    │
│  │  ┌────────────────────────┐ │    │
│  │  │  10 queries remaining  │ │    │ Badge
│  │  └────────────────────────┘ │    │
│  └─────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐   │
│  │  ➕  New Conversation         │   │ Button
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │  🔐  Sign In                  │   │ Button
│  └──────────────────────────────┘   │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
└──────────────────────────────────────┘
    Width: 320px (w-80)
```

**Components:**

### User Section (Guest):
- Gradient icon container (Purple-to-fuchsia)
- "Guest User" text
- Query counter badge (Purple-to-fuchsia gradient)

### Action Buttons:
- New Conversation (Teal-cyan gradient)
- Sign In (Purple-fuchsia gradient)

**Background:** Purple-100 → Blue-50 → Teal-50 gradient
**Shadow:** Large shadow for depth

---

## 6. App Menu (Sidebar) - Authenticated Mode

```
┌──────────────────────────────────────┐
│                                      │
│  ┌─────────────────────────────┐    │
│  │       ┌────────┐             │    │
│  │       │   👤   │             │    │
│  │       └────────┘             │    │
│  │                              │    │
│  │      John Doe                │    │
│  │   john@example.com           │    │
│  │                              │    │
│  │  ┌────────────────────────┐ │    │
│  │  │  Unlimited queries     │ │    │
│  │  └────────────────────────┘ │    │
│  └─────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐   │
│  │  ➕  New Conversation         │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │  🚪  Logout                   │   │
│  └──────────────────────────────┘   │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

**Components:**

### User Section (Authenticated):
- Gradient icon container (Teal-to-cyan)
- User display name
- User email
- Status badge (Unlimited queries)

### Action Buttons:
- New Conversation (Teal-cyan gradient)
- Logout (White/50 bg, red text and border)

---

## 7. Alert Dialog - Rate Limit

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│                                                               │
│         ┌───────────────────────────────────────┐           │
│         │                                         │           │
│         │  Daily Limit Reached                    │           │
│         │                                         │           │
│         │  You've used all 10 guest queries      │           │
│         │  today. Sign in for unlimited access   │           │
│         │  to our knowledge base of spiritual    │           │
│         │  texts and wisdom.                     │           │
│         │                                         │           │
│         │                                         │           │
│         │  ┌──────────────┐  ┌──────────────┐   │           │
│         │  │ Maybe Later  │  │   Sign In    │   │           │
│         │  └──────────────┘  └──────────────┘   │           │
│         │                                         │           │
│         └───────────────────────────────────────┘           │
│                                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- Title: "Daily Limit Reached"
- Description: Explanation text
- Cancel button: "Maybe Later"
- Action button: "Sign In" (Primary style)

**Background:** White/default
**Overlay:** Semi-transparent dark overlay

---

## 8. Alert Dialog - Logout Confirmation

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│                                                               │
│         ┌───────────────────────────────────────┐           │
│         │                                         │           │
│         │  Confirm Logout                         │           │
│         │                                         │           │
│         │  Are you sure you want to log out?     │           │
│         │  Your conversation history will be     │           │
│         │  saved and available when you sign     │           │
│         │  back in.                               │           │
│         │                                         │           │
│         │                                         │           │
│         │  ┌──────────────┐  ┌──────────────┐   │           │
│         │  │   Cancel     │  │   Logout     │   │           │
│         │  └──────────────┘  └──────────────┘   │           │
│         │                                         │           │
│         └───────────────────────────────────────┘           │
│                                                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- Title: "Confirm Logout"
- Description: Reassurance about saved data
- Cancel button: "Cancel" (Border style)
- Action button: "Logout" (Teal-cyan gradient)

**Background:** Purple-50 → Blue-50 → Teal-50 gradient
**Overlay:** Semi-transparent dark overlay

---

## Responsive Breakpoints

### Mobile (< 640px)
```
┌─────────────────────────┐
│  📚 Sacred Wisdom   ☰  │
├─────────────────────────┤
│                         │
│   [Content Area]        │
│                         │
│   - Full width          │
│   - Single column       │
│   - Stacked elements    │
│   - px-4 padding        │
│                         │
├─────────────────────────┤
│  [Input Area]           │
│  - Full width           │
│  - Minimum padding      │
└─────────────────────────┘
```

### Tablet (640px - 1023px)
```
┌─────────────────────────────────────┐
│  📚 Sacred Wisdom            ☰     │
├─────────────────────────────────────┤
│                                     │
│      [Content Area]                 │
│                                     │
│   - Increased padding (px-6)       │
│   - Better spacing                  │
│   - Message bubbles: 75% max       │
│                                     │
├─────────────────────────────────────┤
│  [Input Area - Wider]               │
└─────────────────────────────────────┘
```

### Desktop (1024px+)
```
┌───────────────────────────────────────────────┐
│  📚 Sacred Wisdom                       ☰    │
├───────────────────────────────────────────────┤
│                                               │
│           [Content Area - Centered]           │
│          Max Width: 896px (4xl)               │
│                                               │
│   - px-8 padding                              │
│   - Comfortable reading width                 │
│   - Optimized message layout                  │
│                                               │
├───────────────────────────────────────────────┤
│     [Input Area - Centered Max Width]         │
└───────────────────────────────────────────────┘
```

---

## Component Hierarchy

```
App (Root)
├── StartupScreen (Conditional)
├── AuthScreen (Conditional)
│   ├── Header
│   ├── Tabs
│   │   ├── TabsList
│   │   │   ├── Login Tab Trigger
│   │   │   └── Register Tab Trigger
│   │   ├── Login TabContent
│   │   │   ├── Email Input
│   │   │   ├── Password Input
│   │   │   └── Login Button
│   │   └── Register TabContent
│   │       ├── Email Input
│   │       ├── Password Input
│   │       ├── Password Strength Indicator
│   │       └── Register Button
│   ├── Divider
│   └── Guest Button
└── ChatScreen (Conditional)
    ├── Header
    │   ├── Logo + Title
    │   └── Menu Button
    ├── AppMenu (Sheet/Sidebar)
    │   ├── User Profile Section
    │   │   ├── Avatar Icon
    │   │   ├── Display Name / Guest
    │   │   └── Query Counter Badge
    │   └── Action Buttons
    │       ├── New Conversation
    │       ├── Sign In (Guest) / Logout (Auth)
    ├── Chat Area
    │   ├── ScrollArea
    │   │   ├── Empty State (Conditional)
    │   │   │   ├── Icon
    │   │   │   ├── Title
    │   │   │   ├── Description
    │   │   │   └── Suggestion Cards
    │   │   └── Messages List (Conditional)
    │   │       ├── User Messages
    │   │       ├── Assistant Messages
    │   │       │   ├── Content
    │   │       │   ├── Citations
    │   │       │   └── Timestamp
    │   │       └── Typing Indicator
    │   └── Input Area
    │       ├── Textarea
    │       ├── Send Button
    │       └── Helper Text + Counter
    ├── Rate Limit Dialog
    │   ├── Title
    │   ├── Description
    │   └── Actions
    └── Logout Dialog
        ├── Title
        ├── Description
        └── Actions
```

---

## User Flow Diagrams

### Authentication Flow
```
[App Launch]
     ↓
[Startup Screen]
  (1.5s delay)
     ↓
[Check Stored Tokens]
     ↓
     ├─→ [Valid Token] → [Authenticated Chat]
     │
     ├─→ [No Token] → [Auth Screen]
     │                      ↓
     │                   [Login Tab]
     │                      ↓
     │              ┌───────┴────────┐
     │              ↓                ↓
     │         [Login Form]    [Register Form]
     │              ↓                ↓
     │         [Submit] ←──────→ [Submit]
     │              ↓
     │         [Auth Success]
     │              ↓
     │         [Store Tokens]
     │              ↓
     └──────→ [Authenticated Chat]
     
     [Auth Screen]
          ↓
     [Guest Button]
          ↓
     [Guest Chat]
```

### Chat Flow
```
[Chat Screen]
     ↓
[Empty State]
     ↓
     ├─→ [Click Suggestion] → [Fill Input]
     │
     └─→ [Type Query] → [Input Area]
                            ↓
                       [Press Enter]
                            ↓
                       [Validate]
                            ↓
                    ┌───────┴────────┐
                    ↓                ↓
              [Guest User]    [Auth User]
                    ↓                ↓
            [Check Limit]    [No Limit]
                    ↓                ↓
            ┌───────┴────┐          │
            ↓            ↓          │
      [Under 10]   [At Limit]      │
            ↓            ↓          │
            │    [Show Modal]       │
            │            ↓          │
            │    [Sign In?]         │
            │            ↓          │
            └────────────┴──────────┘
                         ↓
                  [Send Message]
                         ↓
                  [Show Typing]
                         ↓
                  [API Response]
                         ↓
                [Display Answer]
                         ↓
                [Show Citations]
```

### Logout Flow
```
[Click Menu]
     ↓
[Open Sidebar]
     ↓
[Click Logout]
     ↓
[Show Dialog]
     ↓
     ├─→ [Cancel] → [Close Dialog]
     │
     └─→ [Confirm]
          ↓
     [Clear Tokens]
          ↓
     [Reset State]
          ↓
     [Auth Screen]
```

---

## Screen States

### 1. StartupScreen
- **State:** Loading/Initializing
- **Duration:** ~1.5 seconds
- **Next:** → AuthScreen or ChatScreen

### 2. AuthScreen
- **States:**
  - Login Tab Active
  - Register Tab Active
  - Loading (form submission)
  - Error Display
- **Next:** → ChatScreen

### 3. ChatScreen - Empty
- **State:** No messages, showing suggestions
- **Actions:** Click suggestion or type query
- **Next:** → ChatScreen with Messages

### 4. ChatScreen - Active
- **States:**
  - Idle (waiting for input)
  - Typing (user typing)
  - Sending (message sent, waiting for response)
  - Loading (showing typing indicator)
  - Displaying (showing response)
- **Substates:**
  - Guest with remaining queries
  - Guest at limit
  - Authenticated

### 5. Modals/Dialogs
- **Rate Limit Dialog:** Shows when guest hits 10 queries
- **Logout Dialog:** Shows on logout confirmation

---

## Design Specifications Summary

### Spacing
- Screen padding: 4 (mobile), 6 (tablet), 8 (desktop)
- Component gaps: 2, 4, 6
- Section spacing: 4, 6, 8

### Colors
- Gradients: Purple-Blue-Teal (backgrounds)
- Actions: Teal-Cyan (primary), Purple-Fuchsia (secondary)
- Text: Gray-900 (primary), Gray-700 (secondary)
- Borders: Purple-300, Gray-200

### Typography
- Titles: text-xl to text-3xl
- Body: text-sm to text-base
- Helper: text-xs

### Shadows
- sm: Headers, subtle elevation
- md: Buttons, messages, cards
- lg: Modals, menus, input area
- xl: Dialogs

### Borders
- Radius: lg (8px), xl (12px), 2xl (16px), full (pills)
- Width: 1px (default), 2px (emphasized)

---

## Interaction Patterns

### Hover States
- **Buttons:** Darker gradient, increased shadow
- **Cards:** Increased shadow, background transition
- **Links:** Color change, underline
- **Suggestions:** Shadow increase, background lighten

### Focus States
- **Inputs:** Border color change + visible ring (teal)
- **Buttons:** Outline for keyboard navigation

### Active States
- **Buttons:** Slightly pressed appearance
- **Tabs:** Highlighted with background color

### Disabled States
- **Opacity:** 50% reduction
- **Cursor:** not-allowed
- **Buttons:** No hover effects

### Loading States
- **Buttons:** "Loading..." text, disabled
- **Messages:** Animated typing indicator
- **Screen:** Full-screen with progress bar

---

## Accessibility Notes

1. **Color Contrast:** All text meets WCAG AA standards
2. **Focus Indicators:** Visible keyboard navigation
3. **ARIA Labels:** Proper labels for screen readers
4. **Touch Targets:** Minimum 44x44px
5. **Semantic HTML:** Proper heading hierarchy
6. **Alt Text:** All icons have screen reader alternatives

---

## Animation Specifications

### Loading Bar (Startup)
```css
@keyframes loading {
  0%, 100% { transform: translateX(-100%); }
  50% { transform: translateX(100%); }
}
Duration: 1.5s
Easing: ease-in-out
Loop: infinite
```

### Typing Indicator
```css
Animation: bounce
Dot 1: No delay
Dot 2: 0.2s delay
Dot 3: 0.4s delay
```

### Transitions
- Color: 150ms ease
- Shadow: 200ms ease
- Transform: 200ms ease
- Opacity: 150ms ease

---

**Document Version:** 1.0
**Last Updated:** February 2026
**Created for:** Sacred Wisdom Application
