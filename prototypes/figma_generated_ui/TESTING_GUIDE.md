# 🧪 Sacred Wisdom - Testing Guide

Complete guide for testing all features of the Sacred Wisdom application.

## 🚀 Quick Start Testing

### Option 1: Guest Mode (Easiest)
1. Open the application
2. Wait for the startup screen to finish (1.5 seconds)
3. Click **"Continue as Guest"** button at the bottom
4. Start asking questions immediately!

### Option 2: Register New Account
1. Open the application
2. Wait for the startup screen
3. Click **"Register"** tab
4. Enter any email: `test@example.com`
5. Enter a password that meets requirements: `Test1234!`
6. Click **"Create Account"**
7. You'll be logged in automatically!

### Option 3: Login with Existing Account
1. First register an account (see Option 2)
2. Logout from the menu
3. Click **"Login"** tab
4. Enter the same credentials
5. Click **"Login"**

---

## 📋 Complete Feature Testing Checklist

### ✅ Startup Screen
**What to test:**
- [ ] Beautiful loading animation appears
- [ ] "Sacred Wisdom" logo and branding visible
- [ ] Loading bar animates smoothly
- [ ] Screen shows for ~1.5 seconds
- [ ] Automatically transitions to Auth screen

**How to test:**
- Refresh the page to see the startup screen again
- Check browser console for any errors

---

### ✅ Authentication Screen

#### **Login Tab**

**Valid Login:**
1. Click "Login" tab (if not already selected)
2. Enter email: `user@example.com`
3. Enter password: `Password123!`
4. Click "Login" button
5. ✅ Should see success toast and redirect to chat

**Invalid Login (Test Validation):**

Test Case 1: Empty email
- Email: `` (leave blank)
- Password: `Password123!`
- Click Login
- ❌ Should show error: "Email is required"

Test Case 2: Invalid email format
- Email: `notanemail`
- Password: `Password123!`
- Click Login
- ❌ Should show error: "Invalid email format"

Test Case 3: Weak password
- Email: `test@example.com`
- Password: `weak`
- Click Login
- ❌ Should show error: "Password must be at least 8 characters"

**Show/Hide Password:**
- [ ] Click eye icon to show password
- [ ] Click again to hide password
- [ ] Password field toggles between text/password type

---

#### **Register Tab**

**Valid Registration:**
1. Click "Register" tab
2. Enter email: `newuser@example.com`
3. Enter password: `SecurePass123!`
4. Watch password strength indicator turn green
5. Click "Create Account"
6. ✅ Should see success toast and redirect to chat

**Password Strength Indicator:**

Test Case 1: Weak password
- Enter: `pass`
- [ ] Red bar (weak)
- [ ] Missing requirements shown with X icons

Test Case 2: Medium password
- Enter: `Password1`
- [ ] Yellow bars (medium)
- [ ] Most requirements met

Test Case 3: Strong password
- Enter: `SecurePass123!`
- [ ] All 3 bars green (strong)
- [ ] All requirements have green checkmarks:
  - ✓ 8+ characters
  - ✓ Uppercase letter
  - ✓ Lowercase letter
  - ✓ Number
  - ✓ Special character

**Invalid Registration:**

Test Case 1: Email already exists
- Email: `test@example.com` (if you already registered this)
- Password: `Password123!`
- Click "Create Account"
- ❌ Should show error about email existing (in real app)
- ℹ️ In mock: Will succeed anyway

---

#### **Guest Mode**

**Starting Guest Session:**
1. On auth screen (any tab)
2. Look for "OR" divider
3. Click **"Continue as Guest"** button
4. [ ] Should see info toast: "Continuing as guest - 10 queries per day"
5. [ ] Redirected to chat screen
6. [ ] Yellow banner at top showing remaining queries

---

### ✅ Chat Screen (Guest Mode)

#### **Guest Mode Banner**
- [ ] Yellow/orange banner visible at top
- [ ] Shows "Guest Mode: X queries remaining today"
- [ ] "Sign In" button on right side
- [ ] Clicking "Sign In" returns to auth screen

#### **Sending Messages (Guest)**

**First Query:**
1. Type in the text area: `What is karma?`
2. Click send button (paper plane icon) OR press Enter
3. [ ] Your message appears on right (blue/purple gradient)
4. [ ] Loading animation appears (3 bouncing dots)
5. [ ] After ~2 seconds, assistant message appears on left (white)
6. [ ] Message includes spiritual wisdom about karma
7. [ ] Citations appear below (document title, page, relevance %)
8. [ ] Banner updates: "9 queries remaining"

**Using Suggested Questions:**
1. If no messages yet, click any suggestion button
2. [ ] Question populates in input field
3. [ ] Click send or press Enter
4. [ ] Response appears as above

**Try These Questions:**
- "What does the Bhagavad Gita teach about karma?"
- "Explain the Buddhist concept of mindfulness"
- "What is dharma and why is it important?"
- "How do I cultivate compassion?"
- "What is the path to enlightenment?"
- "What do the texts say about overcoming suffering?"

#### **Character Counter**
1. Type a long message (over 2000 characters)
2. [ ] Counter turns red when over limit
3. [ ] Send button becomes disabled
4. [ ] Can't send until under 2000 chars

#### **Rate Limit Testing**
1. Send 10 queries total (watch counter decrease)
2. After 10th query:
   - [ ] Modal appears: "Daily Limit Reached"
   - [ ] Text explains you need to sign in
   - [ ] "Sign In" and "Maybe Later" buttons
   - [ ] Input field becomes disabled
   - [ ] Placeholder text: "Sign in to continue..."

#### **Menu (Guest Mode)**
1. Click hamburger menu (top right)
2. [ ] Drawer slides in from right
3. [ ] Shows yellow warning box with guest mode info
4. [ ] Shows remaining queries
5. [ ] "Sign In for Unlimited Access" button
6. [ ] Clicking button returns to auth screen

---

### ✅ Chat Screen (Authenticated Mode)

#### **Logging In First**
1. From guest mode, click "Sign In" 
2. Login or register with valid credentials
3. [ ] Redirected back to chat screen
4. [ ] No yellow banner (guest mode banner removed)
5. [ ] Email shown under "Sacred Wisdom" logo
6. [ ] "New Chat" button visible in header

#### **Authenticated Features**

**Header Display:**
- [ ] "Sacred Wisdom" logo on left
- [ ] Your email shown below logo
- [ ] "New Chat" button available
- [ ] Menu button on right

**Sending Unlimited Messages:**
1. Send a message: `Tell me about meditation`
2. [ ] Message sent successfully
3. [ ] No rate limit counter
4. [ ] No limit on number of queries
5. [ ] Can send as many as you want!

**New Conversation:**
1. Send a few messages
2. Click "New Chat" button (in header)
3. [ ] Success toast: "New conversation started"
4. [ ] All messages cleared
5. [ ] Empty state with suggestions appears
6. [ ] Can start fresh conversation

**Citations Interaction:**
1. Send any question
2. Wait for response with citations
3. [ ] Citations appear at bottom of assistant message
4. [ ] Shows "Sources:" label
5. [ ] Each citation shows:
   - Document title (bold)
   - Page number
   - Relevance score (e.g., "95% relevant")
6. [ ] External link icon on left
7. [ ] Hover shows blue highlight
8. [ ] Clicking would open document (not implemented in mock)

**Menu (Authenticated Mode):**
1. Click hamburger menu
2. [ ] Shows "Signed in as"
3. [ ] Shows your email
4. [ ] "New Conversation" button
5. [ ] Red "Logout" button at bottom

**Logout:**
1. Click menu → Logout
2. [ ] Confirmation dialog appears
3. [ ] "Are you sure you want to log out?"
4. [ ] Mentions conversation history is saved
5. [ ] Click "Logout" to confirm
6. [ ] Success toast: "Logged out successfully"
7. [ ] Redirected to auth screen (guest mode)
8. [ ] Can continue as guest with 10 new queries

---

## 🎯 Keyboard Shortcuts

### Chat Input
- **Enter**: Send message
- **Shift + Enter**: New line in message
- **Tab**: Move to send button

---

## 🎨 Responsive Design Testing

### Mobile (< 600px)
1. Resize browser to 400px width
2. [ ] Layout adapts to mobile
3. [ ] Buttons stack vertically
4. [ ] Text remains readable
5. [ ] Menu works smoothly

### Tablet (600-1024px)
1. Resize browser to 768px width
2. [ ] Comfortable reading width
3. [ ] All features accessible
4. [ ] Good spacing

### Desktop (> 1024px)
1. Resize browser to 1920px width
2. [ ] Max width ~1200px for chat
3. [ ] Centered content
4. [ ] Clean, spacious layout

---

## 🐛 Common Issues & Solutions

### Issue: "Continue as Guest" button not working
**Solution:** 
- Check browser console for errors
- Try refreshing the page
- Make sure JavaScript is enabled

### Issue: Can't login with test credentials
**Solution:**
- Password must meet requirements:
  - Min 8 characters
  - 1 uppercase letter
  - 1 lowercase letter  
  - 1 number
  - 1 special character (!@#$%^&*)
- Try: `Test1234!` or `Password123!`

### Issue: Send button disabled
**Solution:**
- Make sure message is not empty
- Check character count is under 2000
- If guest mode, make sure you have queries remaining
- Wait for previous message to finish loading

### Issue: Not seeing startup screen
**Solution:**
- Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
- Clear localStorage and refresh

---

## 📊 Test Data Reference

### Valid Test Credentials

**Email Examples:**
- `user@example.com`
- `test@test.com`
- `spiritual.seeker@wisdom.org`
- Any valid email format works!

**Valid Passwords:**
- `Test1234!`
- `Password123!`
- `SecurePass99!`
- `MyPass@2024`
- `Spiritual123!`

**Invalid Passwords (for testing validation):**
- `short` - Too short
- `nouppercase1!` - No uppercase
- `NOLOWERCASE1!` - No lowercase
- `NoNumbers!` - No numbers
- `NoSpecial123` - No special chars

### Sample Questions to Try

1. **Karma & Action:**
   - "What is karma?"
   - "Explain the law of cause and effect"
   - "What does the Gita say about selfless action?"

2. **Mindfulness:**
   - "How do I practice mindfulness?"
   - "What is meditation according to Buddhist texts?"
   - "Explain present moment awareness"

3. **Compassion:**
   - "How do I cultivate compassion?"
   - "What is loving-kindness?"
   - "Teachings on empathy and compassion"

4. **Enlightenment:**
   - "What is the path to enlightenment?"
   - "How do I achieve moksha?"
   - "Explain the Noble Eightfold Path"

5. **Philosophy:**
   - "What is dharma?"
   - "Explain the concept of detachment"
   - "What does wu wei mean?"

---

## 🎬 Complete User Journey Test

### Journey 1: Guest User
1. ✅ Start app → See startup screen
2. ✅ Click "Continue as Guest"
3. ✅ See empty chat with suggestions
4. ✅ Click suggestion or type question
5. ✅ Receive answer with citations
6. ✅ Ask 9 more questions (watch counter)
7. ✅ On 10th query, see rate limit modal
8. ✅ Click "Sign In" → Back to auth screen

### Journey 2: New User Registration
1. ✅ Start app → See startup screen
2. ✅ Click "Register" tab
3. ✅ Enter email and strong password
4. ✅ Watch password strength indicator
5. ✅ Click "Create Account"
6. ✅ See success toast and chat screen
7. ✅ Ask unlimited questions
8. ✅ Use "New Chat" to clear conversation
9. ✅ Open menu and logout
10. ✅ Confirm logout

### Journey 3: Returning User
1. ✅ Start app → See startup screen
2. ✅ Auto-redirects to chat (if tokens exist)
   - OR click "Login" tab
3. ✅ Enter credentials and login
4. ✅ Continue previous or start new conversation
5. ✅ Test all features
6. ✅ Logout when done

---

## 💡 Tips for Best Testing Experience

1. **Use Chrome DevTools:**
   - Open Console (F12) to see any errors
   - Use Network tab to see mock API calls
   - Use Application tab to inspect localStorage

2. **Test in Incognito:**
   - Fresh start without cached data
   - Tests first-time user experience

3. **Test Different Scenarios:**
   - Happy path (everything works)
   - Error cases (wrong password, etc.)
   - Edge cases (empty fields, long text)

4. **Mobile Testing:**
   - Use Chrome DevTools device emulation
   - Test on actual phone if possible
   - Try both portrait and landscape

5. **Accessibility:**
   - Try keyboard-only navigation (Tab key)
   - Test with screen reader if available
   - Check color contrast

---

## 📞 Need Help?

If something isn't working:

1. Check browser console for errors
2. Try clearing localStorage:
   ```javascript
   localStorage.clear()
   ```
3. Hard refresh the page
4. Make sure you're using a modern browser (Chrome, Firefox, Safari, Edge)

---

**Happy Testing! 🙏**

Let the wisdom of the sacred texts guide your testing journey.
