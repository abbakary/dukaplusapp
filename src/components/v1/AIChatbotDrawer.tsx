import React, { useState, useRef, useEffect } from 'react';
import { 
  Sparkles, 
  X, 
  Send, 
  Bot, 
  User, 
  RefreshCw, 
  TrendingUp, 
  Boxes, 
  Users, 
  CalendarDays,
  ShieldCheck
} from 'lucide-react';
import { Language } from '@/types/v1';
import { getTranslation } from '@/utils/translations';

interface Message {
  id: string;
  sender: 'ai' | 'user';
  text: string;
  timestamp: string;
}

interface AIChatbotDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  language: Language;
  initialPrompt?: string;
}

export const AIChatbotDrawer: React.FC<AIChatbotDrawerProps> = ({
  isOpen,
  onClose,
  language,
  initialPrompt,
}) => {
  const t = (key: any) => getTranslation(language, key);

  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'm-1',
      sender: 'ai',
      text: language === 'sw'
        ? 'Jambo! Mimi ni **Msaidizi Mahiri wa Duka+**. Ninaweza kukusaidia kuchambua mauzo, kutabiri bidhaa zilizopungua stoo, kusimamia madeni ya wateja, au kupanga matukio ya kalenda. Nikusaidie nini leo?'
        : 'Hello! I am your **Duka+ AI Retail Assistant**. I can help you analyze revenue, forecast inventory restocking, score customer credit risks, or schedule calendar events. How can I help you today?',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
  ]);

  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (initialPrompt && isOpen) {
      handleSendMessage(initialPrompt);
    }
  }, [initialPrompt, isOpen]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  const handleSendMessage = async (textToSend?: string) => {
    const text = textToSend || inputMessage;
    if (!text.trim() || isLoading) return;

    const userMsg: Message = {
      id: `msg-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages(prev => [...prev, userMsg]);
    setInputMessage('');
    setIsLoading(true);

    try {
      const response = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: text,
          language,
          shopContext: {
            shopName: 'Al-Falah Pharmacy',
            type: 'Pharmacy',
            revenueToday: 'TSh 850,000',
            activeCustomers: 342,
            lowStockCount: 8,
            overdueCustomers: 5,
            location: 'Dar es Salaam, Tanzania',
          },
        }),
      });

      const data = await response.json();
      const aiReply: Message = {
        id: `ai-${Date.now()}`,
        sender: 'ai',
        text: data.reply || 'Samahani, jaribu tena.',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };

      setMessages(prev => [...prev, aiReply]);
    } catch (err: any) {
      setMessages(prev => [
        ...prev,
        {
          id: `ai-err-${Date.now()}`,
          sender: 'ai',
          text: 'Mtandao umeshindwa kupokea jibu. Tafadhali jaribu tena.',
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null;

  const quickChips = language === 'sw' ? [
    '📊 Mauzo ya leo yapoje?',
    '📦 Ni dawa gani zimepungua stoo?',
    '👥 Wateja gani wana madeni makubwa?',
    '📅 Panga matukio ya wiki kwa AI',
  ] : [
    '📊 How are today\'s sales?',
    '📦 Which medications are low stock?',
    '👥 Who has overdue credit debt?',
    '📅 Schedule weekly events with AI',
  ];

  return (
    <div className="fixed inset-y-0 right-0 w-full sm:w-[440px] bg-white border-l border-[#E1DFDD] shadow-2xl z-50 flex flex-col justify-between font-sans select-none animate-in slide-in-from-right duration-200">
      {/* Drawer Header */}
      <div className="p-4 bg-gradient-to-r from-[#24284A] to-[#6264A7] text-white flex items-center justify-between border-b border-[#323762]">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-white/10 flex items-center justify-center text-amber-300">
            <Sparkles className="w-4 h-4 animate-pulse" />
          </div>
          <div>
            <h3 className="font-bold text-sm leading-tight text-white">{t('aiAssistantTitle')}</h3>
            <p className="text-[10px] text-slate-200">Gemini 3.7 Flash • Swahili & English</p>
          </div>
        </div>
        <button onClick={onClose} className="p-1.5 hover:bg-white/10 rounded-lg text-slate-200 transition-colors">
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Messages Scroll Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-[#F8F8F8]">
        {messages.map(msg => (
          <div
            key={msg.id}
            className={`flex items-start gap-2.5 ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            {msg.sender === 'ai' && (
              <div className="w-7 h-7 rounded-lg bg-[#6264A7] text-white flex items-center justify-center shrink-0 text-xs shadow-xs">
                <Bot className="w-4 h-4" />
              </div>
            )}

            <div
              className={`max-w-[85%] rounded-2xl px-3.5 py-2.5 text-xs leading-relaxed shadow-xs ${
                msg.sender === 'user'
                  ? 'bg-[#0078D4] text-white rounded-tr-none'
                  : 'bg-white text-[#323130] border border-[#E1DFDD] rounded-tl-none'
              }`}
            >
              <div className="whitespace-pre-line prose-xs">{msg.text}</div>
              <div className={`text-[9px] mt-1 text-right ${msg.sender === 'user' ? 'text-blue-100' : 'text-[#605E5C]'}`}>
                {msg.timestamp}
              </div>
            </div>

            {msg.sender === 'user' && (
              <div className="w-7 h-7 rounded-lg bg-[#0078D4] text-white flex items-center justify-center shrink-0 text-xs shadow-xs">
                <User className="w-4 h-4" />
              </div>
            )}
          </div>
        ))}

        {isLoading && (
          <div className="flex items-center gap-2 text-xs text-[#605E5C] bg-white p-3 rounded-xl border border-[#EDEBE9] w-fit">
            <RefreshCw className="w-3.5 h-3.5 animate-spin text-[#6264A7]" />
            <span>AI is analyzing shop telemetry...</span>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Suggested Quick Prompt Chips */}
      <div className="p-2.5 bg-white border-t border-[#EDEBE9] flex items-center gap-1.5 overflow-x-auto text-[11px]">
        {quickChips.map((chip, idx) => (
          <button
            key={idx}
            onClick={() => handleSendMessage(chip)}
            className="px-2.5 py-1 rounded-full bg-[#F3F2F1] hover:bg-[#EDEBE9] text-[#323130] whitespace-nowrap font-medium transition-colors border border-[#EDEBE9] active:scale-95"
          >
            {chip}
          </button>
        ))}
      </div>

      {/* Input Composer */}
      <div className="p-3 bg-white border-t border-[#E1DFDD]">
        <div className="flex items-center gap-2">
          <input
            type="text"
            placeholder={t('askQuestionPlaceholder')}
            value={inputMessage}
            onChange={e => setInputMessage(e.target.value)}
            onKeyDown={e => {
              if (e.key === 'Enter') handleSendMessage();
            }}
            className="flex-1 px-3.5 py-2 text-xs bg-[#F3F2F1] border border-transparent focus:border-[#0078D4] focus:bg-white rounded-xl outline-none"
          />
          <button
            onClick={() => handleSendMessage()}
            disabled={!inputMessage.trim() || isLoading}
            className={`p-2 rounded-xl text-white transition-all shadow-xs ${
              inputMessage.trim() && !isLoading
                ? 'bg-[#6264A7] hover:bg-[#555793] active:scale-95 cursor-pointer'
                : 'bg-[#C8C6C4] cursor-not-allowed'
            }`}
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
