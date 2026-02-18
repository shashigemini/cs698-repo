import { useState, useEffect } from 'react';
import StartupScreen from './components/StartupScreen';
import AuthScreen from './components/AuthScreen';
import ChatScreen from './components/ChatScreen';
import { Toaster } from './components/ui/sonner';

export type AuthStatus = 'initializing' | 'guest' | 'authenticated';

export interface User {
  id: string;
  email: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  accessExpiresAt: Date;
  refreshExpiresAt: Date;
}

function App() {
  const [authStatus, setAuthStatus] = useState<AuthStatus>('initializing');
  const [user, setUser] = useState<User | null>(null);
  const [guestSessionId, setGuestSessionId] = useState<string | null>(null);
  const [showAuthScreen, setShowAuthScreen] = useState(true);

  useEffect(() => {
    // Simulate token validation on startup
    const initializeAuth = async () => {
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // Check for stored tokens (mock)
      const storedTokens = localStorage.getItem('tokens');
      const storedUser = localStorage.getItem('user');
      
      if (storedTokens && storedUser) {
        const tokens: TokenPair = JSON.parse(storedTokens);
        const userData: User = JSON.parse(storedUser);
        
        // Check if access token is expired
        const accessExpiresAt = new Date(tokens.accessExpiresAt);
        if (accessExpiresAt > new Date()) {
          setUser(userData);
          setAuthStatus('authenticated');
          setShowAuthScreen(false);
          return;
        }
      }
      
      // Check for guest session
      const storedGuestId = localStorage.getItem('guest_session_id');
      if (storedGuestId) {
        setGuestSessionId(storedGuestId);
      } else {
        // Generate new guest session ID
        const newGuestId = crypto.randomUUID();
        localStorage.setItem('guest_session_id', newGuestId);
        setGuestSessionId(newGuestId);
      }
      
      setAuthStatus('guest');
    };

    initializeAuth();
  }, []);

  const handleLogin = (email: string, userData: User, tokens: TokenPair) => {
    setUser(userData);
    setAuthStatus('authenticated');
    localStorage.setItem('user', JSON.stringify(userData));
    localStorage.setItem('tokens', JSON.stringify(tokens));
    setShowAuthScreen(false);
  };

  const handleRegister = (email: string, userData: User, tokens: TokenPair) => {
    setUser(userData);
    setAuthStatus('authenticated');
    localStorage.setItem('user', JSON.stringify(userData));
    localStorage.setItem('tokens', JSON.stringify(tokens));
    setShowAuthScreen(false);
  };

  const handleGuestMode = () => {
    if (!guestSessionId) {
      const newGuestId = crypto.randomUUID();
      localStorage.setItem('guest_session_id', newGuestId);
      setGuestSessionId(newGuestId);
    }
    setShowAuthScreen(false);
  };

  const handleLogout = () => {
    setUser(null);
    setAuthStatus('guest');
    localStorage.removeItem('user');
    localStorage.removeItem('tokens');
    setShowAuthScreen(true);
  };

  if (authStatus === 'initializing') {
    return <StartupScreen />;
  }

  if (authStatus === 'authenticated' && user) {
    return (
      <>
        <ChatScreen
          user={user}
          isGuest={false}
          guestSessionId={guestSessionId}
          onLogout={handleLogout}
          onSignIn={() => setShowAuthScreen(true)}
        />
        <Toaster />
      </>
    );
  }

  if (showAuthScreen && authStatus === 'guest') {
    return (
      <>
        <AuthScreen
          onLogin={handleLogin}
          onRegister={handleRegister}
          onGuestMode={handleGuestMode}
        />
        <Toaster />
      </>
    );
  }

  // Show ChatScreen for guest mode
  return (
    <>
      <ChatScreen
        user={null}
        isGuest={true}
        guestSessionId={guestSessionId}
        onLogout={handleLogout}
        onSignIn={() => setShowAuthScreen(true)}
      />
      <Toaster />
    </>
  );
}

export default App;