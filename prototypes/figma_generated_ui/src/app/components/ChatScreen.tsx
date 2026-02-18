import { useState, useRef, useEffect } from 'react';
import {
  Book,
  Send,
  Menu,
  LogOut,
  AlertTriangle,
  User as UserIcon,
  MessageSquare,
  X,
  Plus,
  ExternalLink,
} from 'lucide-react';
import { Button } from './ui/button';
import { Textarea } from './ui/textarea';
import { ScrollArea } from './ui/scroll-area';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger, SheetDescription } from './ui/sheet';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from './ui/alert-dialog';
import { toast } from 'sonner';
import type { User } from '../App';
import Header from './layout/Header';
import AppMenu from './layout/AppMenu';

interface Message {
  id: string;
  sender: 'user' | 'assistant';
  content: string;
  citations?: Citation[];
  timestamp: Date;
}

interface Citation {
  documentId: string;
  title: string;
  page: number;
  relevanceScore?: number;
}

interface ChatScreenProps {
  user: User | null;
  isGuest: boolean;
  guestSessionId: string | null;
  onLogout: () => void;
  onSignIn: () => void;
}

export default function ChatScreen({
  user,
  isGuest,
  guestSessionId,
  onLogout,
  onSignIn,
}: ChatScreenProps) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [remainingQueries, setRemainingQueries] = useState(10);
  const [showRateLimitModal, setShowRateLimitModal] = useState(false);
  const [showLogoutDialog, setShowLogoutDialog] = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const MAX_QUERY_LENGTH = 2000;
  const characterCount = inputValue.length;
  const isOverLimit = characterCount > MAX_QUERY_LENGTH;
  const canSend = inputValue.trim() && !isOverLimit && !isLoading && (isGuest ? remainingQueries > 0 : true);

  // Mock spiritual texts data with realistic spiritual wisdom
  const mockSpiritualAnswers = [
    {
      answer: "According to the Bhagavad Gita, karma is the law of cause and effect that governs all action in the universe. Lord Krishna teaches Arjuna that every action bears fruit, but it is the attachment to these fruits that binds us to the cycle of rebirth. The Gita emphasizes 'Karma Yoga' - the path of selfless action performed as a duty without desire for personal gain. In Chapter 2, Verse 47, Krishna states: 'You have a right to perform your prescribed duty, but you are not entitled to the fruits of action.' This profound teaching liberates us from anxiety about results and allows us to act with pure intention. The Dhammapada further illuminates this by teaching that all we are is the result of what we have thought, reinforcing the importance of mindful action and pure intention.",
      citations: [
        { documentId: '1', title: 'Bhagavad Gita Commentary', page: 42, relevanceScore: 0.95 },
        { documentId: '2', title: 'The Dhammapada: The Path of Truth', page: 1, relevanceScore: 0.88 }
      ]
    },
    {
      answer: "Compassion, or 'karuna' in Sanskrit, is considered the very heartbeat of spiritual awakening across many traditions. The Buddha taught that compassion arises naturally when we truly understand suffering - both our own and that of others. In the Dhammapada, we learn: 'Hatred does not cease by hatred, but only by love; this is the eternal rule.' The Tao Te Ching similarly speaks of the three treasures: compassion, frugality, and humility. Lao Tzu teaches that through compassion we find courage, as compassion connects us to the universal source of life. True compassion is not pity or sympathy from a distance, but a deep recognition of our shared nature with all beings. It is the realization that in serving others, we serve ourselves, and in healing others, we heal ourselves.",
      citations: [
        { documentId: '2', title: 'The Dhammapada: The Path of Truth', page: 5, relevanceScore: 0.93 },
        { documentId: '3', title: 'Tao Te Ching: The Way of Virtue', page: 67, relevanceScore: 0.89 },
        { documentId: '4', title: 'Buddhist Teachings on Loving-Kindness', page: 23, relevanceScore: 0.86 }
      ]
    },
    {
      answer: "Mindfulness, or 'smrti' in Sanskrit, is the practice of maintaining moment-to-moment awareness of our thoughts, feelings, bodily sensations, and surrounding environment. The Buddha identified mindfulness as one of the seven factors of enlightenment. In the Satipatthana Sutta (Foundations of Mindfulness), the Buddha provides detailed instructions for cultivating awareness of body, feelings, mind, and mental objects. The practice begins simply with observing the breath - watching each inhalation and exhalation without trying to control it. This seemingly simple practice gradually reveals the impermanent nature of all phenomena and loosens our attachment to the illusion of a fixed self. The Bhagavad Gita speaks of this state as 'sthita-prajna' - steady wisdom - where one remains undisturbed by joy or sorrow, maintaining equanimity in all circumstances.",
      citations: [
        { documentId: '5', title: 'Satipatthana Sutta: Foundations of Mindfulness', page: 12, relevanceScore: 0.96 },
        { documentId: '1', title: 'Bhagavad Gita Commentary', page: 78, relevanceScore: 0.87 }
      ]
    },
    {
      answer: "The concept of duty, or 'dharma' in Sanskrit, is central to the Bhagavad Gita's teachings. Lord Krishna reveals to Arjuna that dharma operates on multiple levels - universal dharma (rita), social dharma (varna dharma), and personal dharma (svadharma). In Chapter 3, Krishna emphasizes that performing one's own dharma imperfectly is better than performing another's dharma perfectly. Dharma is not merely obligation, but the natural expression of our role in the cosmic order. It is action aligned with truth, righteousness, and the welfare of all beings. The Gita teaches that when we act in accordance with our dharma, without attachment to results, we purify our consciousness and move closer to liberation. Even challenging duties, when performed with devotion and detachment, become a path to enlightenment.",
      citations: [
        { documentId: '1', title: 'Bhagavad Gita Commentary', page: 115, relevanceScore: 0.94 },
        { documentId: '6', title: 'The Philosophy of Dharma', page: 34, relevanceScore: 0.91 }
      ]
    },
    {
      answer: "The path to enlightenment, known as 'moksha' or 'nirvana', is described differently across spiritual traditions, yet all point to the same ultimate truth. The Buddha outlined the Noble Eightfold Path: right view, right intention, right speech, right action, right livelihood, right effort, right mindfulness, and right concentration. The Bhagavad Gita presents three main paths: Karma Yoga (path of selfless action), Bhakti Yoga (path of devotion), and Jnana Yoga (path of knowledge). The Tao Te Ching teaches that enlightenment comes through wu wei - effortless action in harmony with the Tao. Despite these varied approaches, all traditions agree that enlightenment requires the dissolution of the ego, the cultivation of wisdom and compassion, and direct realization of our true nature beyond the limited self. It is not a destination to be reached but a reality to be awakened to here and now.",
      citations: [
        { documentId: '7', title: 'The Noble Eightfold Path', page: 8, relevanceScore: 0.95 },
        { documentId: '1', title: 'Bhagavad Gita Commentary', page: 156, relevanceScore: 0.92 },
        { documentId: '3', title: 'Tao Te Ching: The Way of Virtue', page: 45, relevanceScore: 0.88 }
      ]
    },
    {
      answer: "Detachment, or 'vairagya' in Sanskrit, is often misunderstood as cold indifference or withdrawal from life. True detachment, as taught in the Bhagavad Gita, is freedom from compulsive desire and aversion while remaining fully engaged in life. Chapter 2, Verse 48 instructs: 'Perform your duty equipoised, O Arjuna, abandoning all attachment to success or failure. Such equanimity is called yoga.' This teaching doesn't ask us to stop caring about outcomes, but to release our desperate clinging to them. The Dhammapada illuminates this further: 'From attachment arises sorrow, from attachment arises fear. For one who is wholly free from attachment, there is no sorrow, much less fear.' Detachment allows us to love more deeply, act more effectively, and experience life more fully, because we are no longer imprisoned by our anxieties about gain and loss.",
      citations: [
        { documentId: '1', title: 'Bhagavad Gita Commentary', page: 89, relevanceScore: 0.93 },
        { documentId: '2', title: 'The Dhammapada: The Path of Truth', page: 213, relevanceScore: 0.90 }
      ]
    }
  ];

  const spiritualSuggestions = [
    'What does the Bhagavad Gita teach about karma?',
    'Explain the Buddhist concept of mindfulness',
    'What is dharma and why is it important?',
    'How do I cultivate compassion according to spiritual texts?',
    'What is the path to enlightenment?',
    'What do the texts say about overcoming suffering?'
  ];

  useEffect(() => {
    if (scrollAreaRef.current) {
      scrollAreaRef.current.scrollTop = scrollAreaRef.current.scrollHeight;
    }
  }, [messages]);

  const handleSendMessage = async () => {
    if (!canSend) return;

    const userMessage: Message = {
      id: crypto.randomUUID(),
      sender: 'user',
      content: inputValue.trim(),
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);

    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1500 + Math.random() * 1000));

    try {
      // Mock response
      const randomAnswer = mockSpiritualAnswers[Math.floor(Math.random() * mockSpiritualAnswers.length)];
      const randomCitations = randomAnswer.citations.slice(0, Math.floor(Math.random() * 3) + 1);

      const assistantMessage: Message = {
        id: crypto.randomUUID(),
        sender: 'assistant',
        content: randomAnswer.answer,
        citations: randomCitations,
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, assistantMessage]);

      // Update conversation ID for authenticated users
      if (!isGuest && !conversationId) {
        const newConversationId = crypto.randomUUID();
        setConversationId(newConversationId);
        localStorage.setItem('last_conversation_id', newConversationId);
      }

      // Update remaining queries for guests
      if (isGuest) {
        const newRemainingQueries = remainingQueries - 1;
        setRemainingQueries(newRemainingQueries);
        
        if (newRemainingQueries === 0) {
          setShowRateLimitModal(true);
        } else if (newRemainingQueries <= 3) {
          toast.warning(`Only ${newRemainingQueries} queries remaining today`);
        }
      }
    } catch (error) {
      toast.error('Failed to get response. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const handleNewConversation = () => {
    setMessages([]);
    setConversationId(null);
    localStorage.removeItem('last_conversation_id');
    toast.success('New conversation started');
  };

  const handleLogoutClick = () => {
    setShowLogoutDialog(true);
  };

  const confirmLogout = () => {
    onLogout();
    setShowLogoutDialog(false);
    toast.success('Logged out successfully');
  };

  return (
    <div className="h-screen flex flex-col bg-gradient-to-br from-purple-100 via-blue-50 to-teal-50">
      {/* Header */}
      <Header onMenuClick={() => setIsMenuOpen(true)} />

      {/* Menu */}
      <AppMenu
        isOpen={isMenuOpen}
        onClose={() => setIsMenuOpen(false)}
        isGuest={isGuest}
        user={user}
        remainingQueries={remainingQueries}
        onNewConversation={handleNewConversation}
        onLogout={() => setShowLogoutDialog(true)}
        onSignIn={onSignIn}
      />

      {/* Main Chat Area */}
      <div className="flex-1 overflow-hidden flex flex-col">
        <ScrollArea className="flex-1" ref={scrollAreaRef}>
          <div className="max-w-4xl mx-auto px-4 py-6">
            {messages.length === 0 ? (
              <div className="h-full flex items-center justify-center">
                <div className="text-center space-y-4 max-w-md px-4">
                  <div className="inline-flex items-center justify-center">
                    <div className="bg-gradient-to-br from-teal-500 to-cyan-500 p-5 rounded-xl shadow-lg">
                      <MessageSquare className="w-10 h-10 text-white" />
                    </div>
                  </div>
                  <h2 className="text-xl font-semibold text-gray-900">
                    Ask about spiritual texts
                  </h2>
                  <p className="text-sm text-gray-700">
                    Explore wisdom from the Bhagavad Gita, Dhammapada, Tao Te Ching, and other sacred texts.
                  </p>
                  <div className="grid grid-cols-1 gap-2 pt-4">
                    {spiritualSuggestions.map((suggestion) => (
                      <button
                        key={suggestion}
                        onClick={() => setInputValue(suggestion)}
                        className="text-left px-4 py-2.5 rounded-xl bg-white/80 backdrop-blur-sm shadow-md hover:shadow-lg hover:bg-white transition-all text-sm text-gray-700"
                      >
                        {suggestion}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-4 pb-6">
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-[85%] sm:max-w-[75%] rounded-xl px-4 py-3 shadow-md ${
                        message.sender === 'user'
                          ? 'bg-gradient-to-r from-teal-600 to-cyan-600 text-white'
                          : 'bg-white/90 backdrop-blur-sm text-gray-900'
                      }`}
                    >
                      <p className="text-sm sm:text-base whitespace-pre-wrap leading-relaxed">
                        {message.content}
                      </p>

                      {message.citations && message.citations.length > 0 && (
                        <div className="mt-3 pt-3 border-t border-gray-200 space-y-2">
                          <p className="text-xs font-medium text-gray-500">Sources:</p>
                          {message.citations.map((citation, idx) => (
                            <div
                              key={idx}
                              className="flex items-start gap-2 text-xs text-gray-600 hover:text-indigo-600 transition-colors group cursor-pointer"
                            >
                              <ExternalLink className="w-3 h-3 flex-shrink-0 mt-0.5 opacity-50 group-hover:opacity-100" />
                              <span>
                                <span className="font-medium">{citation.title}</span>, p. {citation.page}
                                {citation.relevanceScore && (
                                  <span className="text-gray-400 ml-1">
                                    ({Math.round(citation.relevanceScore * 100)}% relevant)
                                  </span>
                                )}
                              </span>
                            </div>
                          ))}
                        </div>
                      )}

                      <p className="text-xs opacity-60 mt-2">
                        {message.timestamp.toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </p>
                    </div>
                  </div>
                ))}

                {isLoading && (
                  <div className="flex justify-start">
                    <div className="max-w-[85%] sm:max-w-[75%] rounded-2xl px-4 py-3 bg-white border border-gray-200">
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-indigo-600 rounded-full animate-bounce" />
                        <div className="w-2 h-2 bg-indigo-600 rounded-full animate-bounce [animation-delay:0.2s]" />
                        <div className="w-2 h-2 bg-indigo-600 rounded-full animate-bounce [animation-delay:0.4s]" />
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </ScrollArea>

        {/* Input Area */}
        <div className="bg-white shadow-lg px-4 sm:px-6 lg:px-8 py-4">
          <div className="space-y-2 max-w-4xl mx-auto">
            <div className="relative">
              <Textarea
                ref={textareaRef}
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder={
                  isGuest && remainingQueries === 0
                    ? 'Sign in to continue asking questions...'
                    : 'Ask a question about spiritual texts...'
                }
                disabled={isLoading || (isGuest && remainingQueries === 0)}
                className="min-h-[80px] resize-none pr-12 bg-white border-2 border-purple-300 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 text-gray-900 placeholder:text-gray-500"
                maxLength={MAX_QUERY_LENGTH + 100}
              />
              <Button
                size="icon"
                className="absolute bottom-2 right-2 rounded-full bg-gradient-to-r from-teal-600 to-cyan-600 hover:from-teal-700 hover:to-cyan-700 shadow-md"
                onClick={handleSendMessage}
                disabled={!canSend}
              >
                <Send className="w-4 h-4" />
              </Button>
            </div>

            <div className="flex items-center justify-between text-xs text-gray-700">
              <span>Press Enter to send, Shift+Enter for new line</span>
              <span className={isOverLimit ? 'text-red-600 font-medium' : ''}>
                {characterCount} / {MAX_QUERY_LENGTH}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Rate Limit Modal */}
      <AlertDialog open={showRateLimitModal} onOpenChange={setShowRateLimitModal}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Daily Limit Reached</AlertDialogTitle>
            <AlertDialogDescription>
              You've used all 10 guest queries today. Sign in for unlimited access to our knowledge base
              of spiritual texts and wisdom.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Maybe Later</AlertDialogCancel>
            <AlertDialogAction onClick={onSignIn}>Sign In</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Logout Confirmation */}
      <AlertDialog open={showLogoutDialog} onOpenChange={setShowLogoutDialog}>
        <AlertDialogContent className="bg-gradient-to-br from-purple-50 via-blue-50 to-teal-50">
          <AlertDialogHeader>
            <AlertDialogTitle className="text-gray-900">Confirm Logout</AlertDialogTitle>
            <AlertDialogDescription className="text-gray-700">
              Are you sure you want to log out? Your conversation history will be saved and available when
              you sign back in.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel className="border-purple-300 hover:bg-purple-50">Cancel</AlertDialogCancel>
            <AlertDialogAction 
              onClick={confirmLogout}
              className="bg-gradient-to-r from-teal-600 to-cyan-600 hover:from-teal-700 hover:to-cyan-700 text-white shadow-md"
            >
              Logout
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}