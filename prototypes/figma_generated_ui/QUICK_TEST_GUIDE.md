# 🎯 Quick Testing Reference

## Fastest Way to Test

### 1️⃣ **Guest Mode** (No Login Required)
```
1. Wait for startup screen (1.5 sec)
2. Click "Continue as Guest" button
3. Start asking questions!
```
✅ **You get 10 queries** - Perfect for quick testing!

---

### 2️⃣ **Login/Register** (For Unlimited Access)

**Any valid credentials work!**

**Example Login:**
- Email: `test@example.com`
- Password: `Test1234!`

**Or make your own:**
- Email: Any valid email (`user@test.com`)
- Password: Must have:
  - ✓ 8+ characters
  - ✓ 1 uppercase (A-Z)
  - ✓ 1 lowercase (a-z)
  - ✓ 1 number (0-9)
  - ✓ 1 special (!@#$%^&*)

---

## 🎮 What You Can Test

### Guest Mode Features
- ✅ Ask up to 10 questions per day
- ✅ Get AI answers with citations
- ✅ See rate limit countdown
- ✅ Rate limit modal after 10 queries
- ✅ Sign in prompts

### Authenticated Mode Features  
- ✅ Unlimited questions
- ✅ New conversation button
- ✅ Persistent sessions (mock)
- ✅ Profile menu
- ✅ Logout with confirmation

---

## 💬 Try These Questions

**Quick Test Questions:**
1. "What is karma?"
2. "Explain mindfulness"
3. "What does the Gita teach about duty?"
4. "How do I cultivate compassion?"
5. "What is the path to enlightenment?"

**Use Suggestion Buttons:**
- Click any suggestion in the empty chat screen
- Suggestions auto-fill the input field

---

## 🔄 How to Switch Modes

**Guest → Authenticated:**
1. In guest mode, click "Sign In" (banner or menu)
2. Login or register
3. Now you have unlimited access!

**Authenticated → Guest:**
1. Open menu (hamburger icon)
2. Click "Logout"
3. Confirm logout
4. Back to auth screen
5. Click "Continue as Guest"

---

## ⌨️ Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Send message | `Enter` |
| New line | `Shift + Enter` |
| Focus input | `Tab` |

---

## 🐛 Troubleshooting

**Button not working?**
- Check browser console (F12)
- Make sure JavaScript is enabled
- Try refreshing page

**Can't login?**
- Password must meet requirements (see above)
- Try demo password: `Test1234!`
- Any email format works - it's a mock!

**Guest mode stuck?**
- Refresh page to reset counter
- Or clear localStorage: `localStorage.clear()`

**Send button disabled?**
- Check message is not empty
- Message must be under 2000 characters
- Guest mode: Check you have queries left

---

## 📱 Testing Tips

1. **Try Guest Mode First** - Fastest way to see the app
2. **Then Try Registration** - See full features
3. **Test Logout/Login** - Verify flows work
4. **Send 10+ Messages as Guest** - Trigger rate limit
5. **Test Responsive Design** - Resize browser window

---

## 🎨 What to Look For

✨ **Good UX:**
- Smooth animations
- Clear feedback (toasts)
- Helpful error messages
- Responsive layout

📚 **Content Quality:**
- Spiritual wisdom in answers
- Relevant citations
- Document references with pages
- Relevance scores shown

🔒 **Security:**
- Password strength indicator
- Validation messages
- Rate limiting for guests
- Logout confirmation

---

## 📊 Expected Behavior

### Messages
- **Your messages:** Right side, blue/purple gradient
- **AI responses:** Left side, white background
- **Citations:** Below AI messages with document info
- **Loading:** 3 bouncing dots animation

### Timings
- **Startup screen:** 1.5 seconds
- **Login/Register:** 1.5 seconds
- **AI Response:** 1.5-2.5 seconds

---

## 🎉 Success Criteria

You've tested successfully if you can:
- ✅ Start app and see startup screen
- ✅ Use guest mode (ask questions)
- ✅ Hit rate limit (10 queries)
- ✅ Register new account
- ✅ Login with credentials
- ✅ Send unlimited messages when logged in
- ✅ Start new conversation
- ✅ Logout and return to auth

---

**Need more details?** Check `TESTING_GUIDE.md` for comprehensive testing instructions!

**Have fun exploring the wisdom! 🙏**
