import { MessageSquare } from 'lucide-react';

export default function StartupScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-100 via-blue-50 to-teal-50 flex items-center justify-center p-4">
      <div className="text-center space-y-6">
        <div className="relative inline-flex items-center justify-center">
          <div className="bg-gradient-to-br from-teal-600 to-cyan-600 p-5 rounded-xl shadow-lg">
            <MessageSquare className="w-10 h-10 text-white" />
          </div>
        </div>

        <div className="space-y-2">
          <h1 className="text-3xl font-semibold text-gray-900">
            Sacred Wisdom
          </h1>
          <p className="text-gray-600">
            Your AI guide to spiritual texts
          </p>
        </div>

        <div className="flex flex-col items-center space-y-2">
          <div className="w-48 h-1 bg-gray-200 rounded-full overflow-hidden">
            <div className="h-full bg-teal-600 rounded-full animate-[loading_1.5s_ease-in-out_infinite]"></div>
          </div>
          <p className="text-sm text-gray-500">Loading...</p>
        </div>
      </div>

      <style>{`
        @keyframes loading {
          0%, 100% {
            transform: translateX(-100%);
          }
          50% {
            transform: translateX(100%);
          }
        }
      `}</style>
    </div>
  );
}