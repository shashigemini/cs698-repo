# 🎨 Sacred Wisdom - UI Components & Actions Guide

Visual guide showing every button, action, and interaction in the application.

---

## 📱 Screen Flow Overview

```
┌─────────────────┐
│ StartupScreen   │ (1.5s auto-transition)
│  - Logo         │
│  - Loading bar  │
└────────┬────────┘
         ↓
┌─────────────────┐
│  AuthScreen     │
│  ┌──────────┐   │
│  │ Login    │   │ ← Tab (clickable)
│  │ Register │   │ ← Tab (clickable)
│  └──────────┘   │
│  📧 Email       │ ← Input field
│  🔒 Password    │ ← Input field + 👁️ toggle
│  [Login] btn    │ ← Button
│       OR        │
│  [Guest] btn    │ ← Button (MAIN ENTRY POINT)
└────────┬────────┘
         ↓
┌─────────────────┐
│  ChatScreen     │
│  (Guest/Auth)   │
│  🎯 Features    │
│  📨 Messages    │
│  ⚙️ Menu        │
└─────────────────┘
```

---

## 🎬 Screen 1: Startup Screen

### Visual Elements
```
┌──────────────────────────────────┐
│                                  │
│         ✨ [Sacred Wisdom]       │
│           (animated)             │
│                                  │
│      ▓▓▓▓▓▓▓▓▓▓░░░░░░            │
│         Loading...               │
│                                  │
└──────────────────────────────────┘
```

### Actions
- ⏱️ **No user actions** - automatic transition after 1.5s
- 🎨 Shows loading animation
- 📍 Auto-navigates to AuthScreen

---

## 🔐 Screen 2: Auth Screen

### Top Section
```
┌──────────────────────────────────┐
│  ℹ️ Testing Guide Banner         │
│  "Click Continue as Guest"       │
│  📧 test@example.com             │
│  🔒 Test1234!                    │
└──────────────────────────────────┘
```
**🖱️ Actions:** Read demo credentials (not clickable)

---

### Logo Section
```
┌──────────────────────────────────┐
│         📖 ✨                     │
│     Sacred Wisdom                │
│  Your AI guide to spiritual      │
│         texts                    │
└──────────────────────────────────┘
```
**🖱️ Actions:** Visual branding (not clickable)

---

### Tab Navigation
```
┌──────────────────────────────────┐
│  ┌──────────┬──────────┐         │
│  │  Login   │ Register │         │
│  │ (active) │          │         │
│  └──────────┴──────────┘         │
└──────────────────────────────────┘
```

#### 🖱️ **Button: Login Tab**
- **Location:** Left tab
- **Action:** Switches to login form
- **Visual:** Highlighted when active

#### 🖱️ **Button: Register Tab**
- **Location:** Right tab
- **Action:** Switches to register form
- **Visual:** Highlighted when active

---

### Login Form (When "Login" tab active)

```
┌──────────────────────────────────┐
│  Email                           │
│  ┌─────────────────────────────┐ │
│  │ 📧 you@example.com         │ │ ← Input
│  └─────────────────────────────┘ │
│                                  │
│  Password                        │
│  ┌─────────────────────────────┐ │
│  │ 🔒 ••••••••            👁️  │ │ ← Input + Toggle
│  └─────────────────────────────┘ │
│                                  │
│  [ Error message area ]          │
│                                  │
│  ┌─────────────────────────────┐ │
│  │         Login               │ │ ← Button
│  └─────────────────────────────┘ │
└──────────────────────────────────┘
```

#### 📝 **Input: Email Field**
- **Type:** Text input (email type)
- **Validation:** RFC 5322 email format
- **Max length:** 255 characters
- **Required:** Yes
- **Example:** test@example.com

#### 📝 **Input: Password Field**
- **Type:** Password (toggleable to text)
- **Validation:**
  - Min 8 characters
  - 1 uppercase letter
  - 1 lowercase letter
  - 1 digit
  - 1 special character
- **Required:** Yes
- **Example:** Test1234!

#### 🖱️ **Button: Show/Hide Password (👁️)**
- **Location:** Right side of password field
- **Action:** Toggles password visibility
- **States:**
  - 👁️ Eye icon = password hidden
  - 👁️‍🗨️ Eye-off icon = password visible

#### 🖱️ **Button: Login**
- **Location:** Below password field
- **Action:** Submits login form
- **Requirements:** Valid email and password
- **Result:** Success → ChatScreen, Error → Show error message
- **Loading state:** "Logging in..." text

---

### Register Form (When "Register" tab active)

```
┌──────────────────────────────────┐
│  Email                           │
│  ┌─────────────────────────────┐ │
│  │ 📧 you@example.com         │ │ ← Input
│  └─────────────────────────────┘ │
│                                  │
│  Password                        │
│  ┌─────────────────────────────┐ │
│  │ 🔒 ••••••••            👁️  │ │ ← Input + Toggle
│  └─────────────────────────────┘ │
│                                  │
│  🟢🟢🟢 Strong                   │ ← Strength indicator
│                                  │
│  ✅ 8+ characters                │
│  ✅ Uppercase letter             │
│  ✅ Lowercase letter             │
│  ✅ Number                       │
│  ✅ Special character            │
│                                  │
│  ┌─────────────────────────────┐ │
│  │    Create Account           │ │ ← Button
│  └─────────────────────────────┘ │
└──────────────────────────────────┘
```

#### 📊 **Visual: Password Strength Indicator**
- **Location:** Below password field
- **States:**
  - 🔴 Red bar = Weak (1-2 requirements)
  - 🟡 Yellow bars = Medium (3 requirements)
  - 🟢 Green bars = Strong (4-5 requirements)
- **Real-time:** Updates as you type

#### ✅ **Visual: Password Requirements Checklist**
- **Displays:** 5 requirements
- **States:**
  - ✅ Green check = Requirement met
  - ❌ Gray X = Requirement not met
- **Real-time:** Updates as you type

#### 🖱️ **Button: Create Account**
- **Location:** Below requirements checklist
- **Action:** Submits registration form
- **Requirements:** Valid email and strong password
- **Result:** Success → ChatScreen, Error → Show error message
- **Loading state:** "Creating account..." text

---

### Guest Mode Section (Both tabs)

```
┌──────────────────────────────────┐
│           ──── OR ────            │
│                                  │
│  ┌─────────────────────────────┐ │
│  │   Continue as Guest         │ │ ← Button (MAIN)
│  └─────────────────────────────┘ │
│                                  │
│  Limited to 10 queries per day   │
└──────────────────────────────────┘
```

#### 🖱️ **Button: Continue as Guest** ⭐ **MOST IMPORTANT**
- **Location:** Bottom of auth card
- **Action:** Start guest session immediately
- **Requirements:** None - fastest way to test!
- **Result:** Generates guest UUID → ChatScreen (Guest mode)
- **Toast:** "Continuing as guest - 10 queries per day"

---

## 💬 Screen 3: Chat Screen - Guest Mode

### Header
```
┌──────────────────────────────────────┐
│  📖 Sacred Wisdom          ☰        │
│                            ↑ Menu   │
└──────────────────────────────────────┘
```

#### 🖱️ **Button: Menu (☰)**
- **Location:** Top right corner
- **Action:** Opens side drawer with options
- **Content (Guest):**
  - ⚠️ Guest mode warning
  - Remaining queries count
  - "Sign In for Unlimited Access" button

---

### Guest Banner (Guest Mode Only)
```
┌──────────────────────────────────────┐
│ ⚠️ Guest Mode: 10 queries remaining  │
│                         [Sign In]    │
└──────────────────────────────────────┘
```

#### 📊 **Visual: Rate Limit Counter**
- **Location:** Yellow banner below header
- **Display:** "Guest Mode: X queries remaining today"
- **Updates:** Decrements with each query
- **Colors:**
  - 🟡 Yellow = Normal (4+ queries left)
  - 🟠 Orange = Low (1-3 queries left)

#### 🖱️ **Button: Sign In (in banner)**
- **Location:** Right side of banner
- **Action:** Navigate to AuthScreen
- **Purpose:** Upgrade to unlimited access

---

### Chat Area

#### Empty State (No messages yet)
```
┌──────────────────────────────────────┐
│              📖                      │
│     Ask about spiritual texts        │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ What does the Bhagavad Gita   │  │ ← Suggestion
│  │ teach about karma?             │  │   button
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ Explain Buddhist mindfulness   │  │ ← Suggestion
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ What is dharma?                │  │ ← Suggestion
│  └────────────────────────────────┘  │
│  ...more suggestions...              │
└──────────────────────────────────────┘
```

#### 🖱️ **Buttons: Suggestion Questions**
- **Count:** 6 different suggestions
- **Action:** Fills input field with question
- **Result:** Auto-populates, then you click Send
- **Questions:**
  1. "What does the Bhagavad Gita teach about karma?"
  2. "Explain the Buddhist concept of mindfulness"
  3. "What is dharma and why is it important?"
  4. "How do I cultivate compassion?"
  5. "What is the path to enlightenment?"
  6. "What do the texts say about overcoming suffering?"

---

#### Message Display (After sending messages)
```
┌──────────────────────────────────────┐
│                    ┌──────────────┐  │
│                    │ Your message │  │ ← User message
│                    │   (right)    │  │   (blue/purple)
│                    └──────────────┘  │
│                                      │
│  ┌──────────────┐                    │
│  │ AI response  │                    │ ← Assistant
│  │   (left)     │                    │   message (white)
│  │              │                    │
│  │ Sources:     │                    │
│  │ 🔗 Gita p.42 │                    │ ← Citations
│  │ 95% relevant │                    │
│  └──────────────┘                    │
└──────────────────────────────────────┘
```

#### 📊 **Visual: User Messages**
- **Location:** Right side of screen
- **Style:** Blue-purple gradient bubble
- **Content:** Your question text
- **Timestamp:** Below message

#### 📊 **Visual: Assistant Messages**
- **Location:** Left side of screen
- **Style:** White bubble with border
- **Content:**
  - Main answer text (spiritual wisdom)
  - Citations section (if available)
  - Timestamp

#### 🔗 **Interactive: Citations**
- **Location:** Below assistant message
- **Format:**
  - 🔗 External link icon
  - **Document title** (bold)
  - Page number
  - Relevance score (%)
- **Action:** Hover to highlight (click not implemented in mock)
- **Example:** "Bhagavad Gita Commentary, p. 42 (95% relevant)"

---

### Input Area
```
┌──────────────────────────────────────┐
│  ┌────────────────────────────────┐  │
│  │ Ask a question about...        │  │ ← Text area
│  │                                │  │   (multiline)
│  │                          ✈️   │  │ ← Send button
│  └────────────────────────────────┘  │
│                                      │
│  Press Enter to send         150/2000│ ← Character
└──────────────────────────────────────┘    counter
```

#### 📝 **Input: Message Text Area**
- **Type:** Multiline textarea
- **Min height:** 80px
- **Max length:** 2000 characters
- **Auto-resize:** Grows up to 4 lines
- **Disabled when:** Loading or out of queries (guest)
- **Placeholder:** 
  - Guest: "Ask a question about spiritual texts..."
  - Guest (0 queries): "Sign in to continue..."

#### 🖱️ **Button: Send (✈️)**
- **Location:** Bottom right of textarea
- **Action:** Sends message to AI
- **Enabled when:**
  - Message is not empty
  - Under 2000 characters
  - Not loading
  - Guest: Has queries remaining
- **Result:** 
  - Message added to chat
  - Loading animation
  - AI response appears (1.5-2.5s)
  - Guest: Counter decrements

#### ⌨️ **Keyboard: Enter Key**
- **Action:** Same as clicking Send button
- **Alternative:** Shift + Enter = new line

#### 📊 **Visual: Character Counter**
- **Location:** Bottom right, below textarea
- **Display:** "X / 2000"
- **Colors:**
  - ⚫ Gray = Normal
  - 🔴 Red = Over limit (>2000)
- **Effect:** Send button disabled when red

---

### Loading State
```
┌──────────────────────────────────────┐
│  ┌──────────────┐                    │
│  │ ● ● ●        │                    │ ← Animated dots
│  │ (bouncing)   │                    │
│  └──────────────┘                    │
└──────────────────────────────────────┘
```

#### 🎨 **Visual: Loading Animation**
- **Display:** 3 dots bouncing
- **Color:** Indigo
- **Location:** Left side (like assistant message)
- **Duration:** While waiting for AI response

---

### Rate Limit Modal (After 10th query)
```
┌──────────────────────────────────────┐
│  ⚠️ Daily Limit Reached             │
│                                      │
│  You've used all 10 guest queries    │
│  today. Sign in for unlimited        │
│  access to our knowledge base.       │
│                                      │
│  [ Maybe Later ]    [  Sign In  ]   │
└──────────────────────────────────────┘
```

#### 🖱️ **Button: Maybe Later**
- **Action:** Closes modal
- **Result:** Input stays disabled, stuck at 0 queries

#### 🖱️ **Button: Sign In**
- **Action:** Navigate to AuthScreen
- **Result:** Can login/register for unlimited access

---

## 💬 Screen 3: Chat Screen - Authenticated Mode

### Header (Authenticated)
```
┌──────────────────────────────────────┐
│  📖 Sacred Wisdom   [ + New Chat ] ☰ │
│  user@email.com                      │
└──────────────────────────────────────┘
```

#### 📊 **Visual: User Email**
- **Location:** Below "Sacred Wisdom" title
- **Display:** Logged-in user's email
- **Not clickable:** Just shows who's logged in

#### 🖱️ **Button: New Chat (+ New Chat)**
- **Location:** Center-right of header
- **Action:** Clears all messages, starts fresh
- **Result:**
  - All messages cleared
  - Back to empty state
  - Success toast: "New conversation started"
  - No data loss (mock - would save in real app)

---

### No Banner (Authenticated Mode)
❌ **Yellow guest banner is hidden**
✅ **Full screen space for chat**

---

### Menu Drawer (Authenticated)
```
┌──────────────────────────────────────┐
│  Menu                           ✕    │
│  ────────────────────────────────    │
│  👤 Signed in as                     │
│  user@email.com                      │
│  ────────────────────────────────    │
│                                      │
│  [ 💬 New Conversation ]             │
│                                      │
│  ────────────────────────────────    │
│  [ 🚪 Logout ]                       │
└──────────────────────────────────────┘
```

#### 🖱️ **Button: New Conversation (in menu)**
- **Action:** Same as "New Chat" button
- **Icon:** 💬 MessageSquare
- **Result:** Clears chat, starts fresh

#### 🖱️ **Button: Logout (in menu)**
- **Style:** Red text, red hover
- **Icon:** 🚪 LogOut
- **Action:** Opens logout confirmation dialog

---

### Logout Confirmation Dialog
```
┌──────────────────────────────────────┐
│  ⚠️ Confirm Logout                  │
│                                      │
│  Are you sure you want to log out?   │
│  Your conversation history will be   │
│  saved and available when you sign   │
│  back in.                            │
│                                      │
│  [   Cancel   ]    [   Logout   ]   │
└──────────────────────────────────────┘
```

#### 🖱️ **Button: Cancel**
- **Action:** Closes dialog, stays logged in

#### 🖱️ **Button: Logout**
- **Action:** Logs out user
- **Result:**
  - Success toast: "Logged out successfully"
  - Navigate to AuthScreen
  - Can continue as guest (10 fresh queries)
  - Or login again

---

## 🎨 Visual States & Feedback

### Toast Notifications
```
┌──────────────────────────────┐
│  ✅ Success message          │
│  ⚠️ Warning message          │
│  ❌ Error message            │
│  ℹ️ Info message             │
└──────────────────────────────┘
```

**Toast Messages You'll See:**

| Action | Toast |
|--------|-------|
| Continue as guest | ℹ️ "Continuing as guest - 10 queries per day" |
| Register success | ✅ "Account created successfully!" |
| Login success | ✅ "Welcome back!" |
| Logout success | ✅ "Logged out successfully" |
| New conversation | ✅ "New conversation started" |
| 3 queries left | ⚠️ "Only 3 queries remaining today" |
| API error | ❌ "Failed to get response. Please try again." |

---

### Button States

#### Enabled
- **Visual:** Full color, clickable
- **Cursor:** Pointer
- **Action:** Triggers function

#### Disabled
- **Visual:** Grayed out, opacity reduced
- **Cursor:** Not allowed
- **Action:** Nothing happens

#### Loading
- **Visual:** Disabled appearance
- **Text:** Changes (e.g., "Login" → "Logging in...")
- **Cursor:** Not allowed

#### Hover (Enabled only)
- **Visual:** Slightly darker/lighter
- **Effect:** Smooth transition
- **Cursor:** Pointer

---

## 🔄 Complete User Flows

### Flow 1: Guest User Journey
```
1. StartupScreen (auto) 
   ↓
2. AuthScreen → Click "Continue as Guest"
   ↓  
3. ChatScreen (Guest mode)
   - See yellow banner
   - Ask question (suggestion or type)
   - Get answer with citations
   - Repeat 9 more times
   ↓
4. Rate Limit Modal
   - Click "Sign In"
   ↓
5. Back to AuthScreen
```

### Flow 2: Registration Journey
```
1. StartupScreen (auto)
   ↓
2. AuthScreen → Click "Register" tab
   - Enter email: test@example.com
   - Enter password: Test1234!
   - Watch strength indicator turn green
   - Click "Create Account"
   ↓
3. ChatScreen (Authenticated)
   - No banner
   - Unlimited queries
   - Try "New Chat" button
   - Open menu
   - Click "Logout"
   ↓
4. Logout Confirmation
   - Click "Logout"
   ↓
5. Back to AuthScreen
```

### Flow 3: Quick Test Flow
```
1. Wait for startup
2. Click "Continue as Guest"
3. Click any suggestion question
4. Press Enter or click Send
5. Watch AI response appear
6. See citations below response
DONE - App tested! ✅
```

---

## 📱 Responsive Behavior

### Mobile (<600px)
- Buttons stack vertically
- Text size adjusts
- Single column layout
- Touch-optimized buttons

### Tablet (600-1024px)
- Comfortable spacing
- Two-column possible
- Good readability

### Desktop (>1024px)
- Max width constraints
- Centered content
- Spacious layout

---

## 🎯 Testing Priorities

### 🥇 Priority 1 (Must Test)
1. ✅ **Guest Mode** - Continue as Guest button
2. ✅ **Send Message** - Ask any question
3. ✅ **Get Response** - See AI answer with citations

### 🥈 Priority 2 (Should Test)
4. ✅ **Register** - Create new account
5. ✅ **Login** - Use test credentials
6. ✅ **Rate Limit** - Send 10 guest queries

### 🥉 Priority 3 (Nice to Test)
7. ✅ **New Chat** - Clear conversation
8. ✅ **Logout** - Logout flow
9. ✅ **Menu** - Open side drawer
10. ✅ **Suggestions** - Click question suggestions

---

## 🎉 Success Checklist

You've successfully explored all features if you can:

- [  ] See startup animation
- [  ] Click "Continue as Guest"
- [  ] Send a message and get response
- [  ] See citations on response
- [  ] Hit rate limit (10 queries)
- [  ] Register new account
- [  ] Login with credentials
- [  ] Send unlimited messages (authenticated)
- [  ] Use "New Chat" button
- [  ] Open menu drawer
- [  ] Logout successfully

---

**🎊 Congratulations! You now know every button and action in Sacred Wisdom!**

For detailed testing scenarios, see `TESTING_GUIDE.md`
For quick reference, see `QUICK_TEST_GUIDE.md`
