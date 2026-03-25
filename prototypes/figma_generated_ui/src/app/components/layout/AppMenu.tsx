import { MessageSquare, LogOut, User as UserIcon, AlertTriangle, CheckCircle } from 'lucide-react';
import { Button } from '../ui/button';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from '../ui/sheet';
import type { User } from '../../App';

interface AppMenuProps {
  isOpen: boolean;
  onClose: () => void;
  isGuest: boolean;
  user: User | null;
  remainingQueries?: number;
  onNewConversation?: () => void;
  onLogout?: () => void;
  onSignIn?: () => void;
}

export default function AppMenu({
  isOpen,
  onClose,
  isGuest,
  user,
  remainingQueries = 10,
  onNewConversation,
  onLogout,
  onSignIn,
}: AppMenuProps) {
  return (
    <Sheet open={isOpen} onOpenChange={onClose}>
      <SheetContent side="left" className="w-[280px] bg-gradient-to-b from-purple-50 to-blue-50 p-0 rounded-xl shadow-lg">
        <div className="flex flex-col h-full">
          {/* Header */}
          <SheetHeader className="px-4 py-4 bg-gradient-to-r from-teal-500 to-cyan-500">
            <div className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5 text-white" />
              <SheetTitle className="text-base font-semibold text-white">
                Sacred Wisdom
              </SheetTitle>
            </div>
            <SheetDescription className="text-xs text-white/80 sr-only">
              Your AI guide to spiritual texts
            </SheetDescription>
          </SheetHeader>

          {/* Content */}
          <div className="flex-1 overflow-y-auto p-3">
            <div className="space-y-2">
              {!isGuest && user ? (
                <>
                  {/* User Profile Section */}
                  <div className="bg-white/80 backdrop-blur-sm rounded-lg p-3 mb-3 shadow-md">
                    <div className="flex items-center gap-2 mb-2">
                      <div className="bg-gradient-to-br from-teal-500 to-cyan-500 p-1.5 rounded-md">
                        <UserIcon className="w-4 h-4 text-white" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs text-purple-600">Signed in as</p>
                        <p className="text-sm font-medium text-gray-900 truncate">{user.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-1.5 text-xs text-green-700 bg-green-100 rounded-md px-2 py-1">
                      <CheckCircle className="w-3 h-3" />
                      <span>Unlimited Access</span>
                    </div>
                  </div>

                  {/* New Conversation Button */}
                  <Button
                    variant="outline"
                    className="w-full justify-start h-10 bg-white/60 border-purple-200 hover:bg-white hover:border-purple-300 rounded-lg shadow-sm"
                    onClick={() => {
                      onNewConversation?.();
                      onClose();
                    }}
                  >
                    <MessageSquare className="w-4 h-4 mr-2 text-purple-600" />
                    <span className="text-sm text-gray-900">New Conversation</span>
                  </Button>
                </>
              ) : (
                /* Guest Mode */
                <>
                  {/* Guest Status Card */}
                  <div className="bg-gradient-to-br from-amber-100 to-orange-100 rounded-lg p-3 mb-3 shadow-md">
                    <div className="flex items-start gap-2">
                      <AlertTriangle className="w-4 h-4 text-amber-700 flex-shrink-0 mt-0.5" />
                      <div className="flex-1">
                        <p className="text-sm font-medium text-amber-900 mb-1">Guest Mode</p>
                        <p className="text-xs text-amber-800 mb-2">
                          Limited to 10 queries per day
                        </p>
                        <div className="bg-white/90 rounded-md px-2 py-1.5">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-xs text-gray-700">Remaining</span>
                            <span className="text-xs font-semibold text-gray-900">{remainingQueries} / 10</span>
                          </div>
                          <div className="w-full bg-gray-200 rounded-full h-1.5 overflow-hidden">
                            <div
                              className="bg-gradient-to-r from-teal-500 to-cyan-500 h-full rounded-full transition-all duration-300"
                              style={{ width: `${(remainingQueries / 10) * 100}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Sign In Button */}
                  <Button
                    className="w-full h-10 bg-gradient-to-r from-teal-600 to-cyan-600 hover:from-teal-700 hover:to-cyan-700 text-white rounded-lg text-sm shadow-md"
                    onClick={() => {
                      onSignIn?.();
                      onClose();
                    }}
                  >
                    Sign In for Unlimited Access
                  </Button>

                  {/* Benefits */}
                  <div className="bg-white/70 backdrop-blur-sm rounded-lg p-3 mt-2 shadow-sm">
                    <p className="text-xs font-medium text-purple-700 mb-2">With an account:</p>
                    <ul className="space-y-1.5">
                      {['Unlimited queries', 'Save conversation history', 'Personalized insights'].map((benefit, idx) => (
                        <li key={idx} className="flex items-center gap-2 text-xs text-gray-700">
                          <div className="w-1 h-1 bg-gradient-to-r from-teal-600 to-cyan-600 rounded-full"></div>
                          {benefit}
                        </li>
                      ))}
                    </ul>
                  </div>
                </>
              )}
            </div>
          </div>

          {/* Footer - Logout */}
          {!isGuest && user && (
            <div className="p-3 bg-gradient-to-r from-red-50 to-pink-50 mt-auto">
              <Button
                variant="ghost"
                className="w-full justify-start h-10 text-red-600 hover:bg-white hover:border-red-200 rounded-lg border-2 border-red-100 bg-white/50"
                onClick={() => {
                  onLogout?.();
                  onClose();
                }}
              >
                <LogOut className="w-4 h-4 mr-2" />
                <span className="text-sm">Logout</span>
              </Button>
            </div>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}