import { Menu, MessageSquare } from 'lucide-react';
import { Button } from '../ui/button';

interface HeaderProps {
  onMenuClick: () => void;
  showMenuButton?: boolean;
}

export default function Header({ onMenuClick, showMenuButton = true }: HeaderProps) {
  return (
    <header className="sticky top-0 z-40 w-full bg-gradient-to-r from-teal-600 to-cyan-600 shadow-lg">
      <div className="flex h-14 items-center justify-between px-3 sm:px-4">
        {/* Left side - Menu button */}
        <div className="flex items-center gap-2">
          {showMenuButton && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onMenuClick}
              className="h-10 w-10 hover:bg-white/20 rounded-lg text-white"
              aria-label="Open menu"
            >
              <Menu className="h-5 w-5" />
            </Button>
          )}
        </div>

        {/* Center - Logo and Title */}
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 flex items-center gap-2">
          <MessageSquare className="w-5 h-5 text-white" />
          <h1 className="text-base font-semibold text-white">Sacred Wisdom</h1>
        </div>

        {/* Right side - Placeholder */}
        <div className="w-10"></div>
      </div>
    </header>
  );
}