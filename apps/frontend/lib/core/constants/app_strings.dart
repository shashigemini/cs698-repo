/// Business-specific strings for the Spiritual Q&A platform.
///
/// Centralises all domain content so UI files stay generic and
/// branding changes only touch this file.
abstract final class AppStrings {
  // ── Brand ──────────────────────────────────────────────────
  /// Application title shown in the browser tab / task switcher.
  static const appTitle = 'Spiritual Q&A';

  /// Display name used in headers and splash screen.
  static const brandName = 'Sacred Wisdom';

  /// Short tagline shown below the brand name.
  static const tagline = 'Your AI guide to spiritual texts';

  // ── Home – empty state ─────────────────────────────────────
  /// Title shown when the chat list is empty.
  static const emptyStateTitle = 'Ask about spiritual texts';

  /// Subtitle shown when the chat list is empty.
  static const emptyStateSubtitle =
      'Explore wisdom from the Bhagavad Gita, '
      'Dhammapada, Tao Te Ching, and other sacred texts.';

  /// Pre-defined suggestion prompts for the empty state.
  static const suggestions = [
    'What does the Bhagavad Gita teach about karma?',
    'Explain the Buddhist concept of mindfulness',
    'What is dharma and why is it important?',
  ];

  // ── Guest ──────────────────────────────────────────────────
  /// Maximum queries a guest user may send before being
  /// asked to sign in.
  static const guestQueryLimit = 3;

  /// Sentinel user-id assigned to anonymous / guest users.
  static const guestUserId = 'guest-user-id';

  /// Session identifier used when sending queries as a guest.
  static const guestSessionId = 'guest-session';

  /// Label shown on the login screen for guest query limits.
  static const guestQueryLimitLabel = 'Limited to 3 queries per day';

  /// Maximum queries a regular authenticated user may send
  /// (simulated/budget limit for this version).
  static const totalUsageLimit = 50;

  // ── Drawer ──────────────────────────────────────────────────
  static const drawerGuestUser = 'Guest User';
  static const drawerNewConversation = 'New Conversation';
  static const drawerSignIn = 'Sign In / Register';
  static const drawerLogout = 'Logout';
  static const drawerSettings = 'Account Settings';
  static const drawerRecentTitle = 'Recent Conversations';
  static const drawerQueriesRemaining = 'queries remaining';

  // ── Auth ────────────────────────────────────────────────────
  static const loginTab = 'Login';
  static const registerTab = 'Register';
  static const emailLabel = 'Email';
  static const passwordLabel = 'Password';
  static const forgotPassword = 'Forgot password?';
  static const deleteAccountSuccess = 'Account deleted successfully';
  static const invalidCredentials = 'Invalid email or password';

  // Password Change
  static const changePassword = 'Change Password';
  static const newPasswordLabel = 'New Password';
  static const confirmPasswordLabel = 'Confirm Password';
  static const passwordsDoNotMatch = 'Passwords do not match';
  static const passwordChangedSuccess = 'Password changed successfully';

  // Recovery
  static const recoveryPhraseTitle = 'Your Recovery Phrase';
  static const recoveryPhraseSubtitle =
      'Please write down these 16 words in order and keep them safe. You will need them to recover your account if you forget your password.';
  static const recoveryPhraseInstructions =
      'Please write down these 16 words in order and keep them safe. You will need them to recover your account if you forget your password.';
  static const recoveryPhraseCopied = 'Recovery phrase copied';
  static const iHaveSavedMnemonic = 'I have saved my recovery phrase';
  static const iHaveSavedIt = "I've saved my recovery phrase";
  static const enterRecoveryPhrase = 'Enter your 12-word recovery phrase';
  static const accountRecovered = 'Account recovered. You are now logged in.';
  static const invalidRecoveryPhrase = 'Invalid recovery phrase';
  static const resetPassword = 'Reset Password';
  static const createAccount = 'Create Account';
  static const alreadyHaveAccount = 'Already have an account? Login';
  static const orDivider = 'OR';
  static const continueAsGuest = 'Continue as Guest';

  // ── Chat UI ─────────────────────────────────────────────────
  static const sourcesTitle = 'Sources:';
  static const scriptureVerseTitle = 'Scripture Verse';
  static const maybeLater = 'Maybe Later';
  static const signInAction = 'Sign In';

  // ── Rate limit ─────────────────────────────────────────────
  /// Banner text shown when the rate limit has been exceeded.
  static const rateLimitBanner =
      'Rate limit exceeded. Please sign in to continue.';

  /// Title of the rate-limit modal dialog.
  static const rateLimitModalTitle = 'Reached daily limit';

  /// Body text of the rate-limit modal dialog.
  static const rateLimitModalBody =
      'Sign in or create an account to continue '
      'asking questions.';

  // ── Accessibility ──────────────────────────────────────────
  static const a11yShare = 'Share response';
  static const a11yClose = 'Close';
  static const a11yAssistantTyping = 'Assistant is typing...';
  static const a11yBrandLogo = 'Sacred Wisdom logo';
  static const a11yUserAvatar = 'User avatar';

  // ── Demo Admin Panel ────────────────────────────────────────
  static const demoAdminTitle = 'Demo Admin Panel';
  static const demoUploadPdf = 'Upload PDF Document';
  static const demoPdfTitle = 'PDF Title';
  static const demoPdfAuthor = 'Author';
  static const demoPdfLogicalId = 'Logical Book ID';
  static const demoUploadButton = 'Upload Document';
  static const demoOpenAiKey = 'OpenAI API Key';
  static const demoSaveKey = 'Save OpenAI Key';
  static const demoConfigUpdated = 'Configuration updated successfully';
  static const demoPdfIngested = 'PDF uploaded and queued for ingestion';
}
