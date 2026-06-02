import { ChatService } from '../core/ChatService';
import { Store } from '../core/Store';
import { Message } from '../model/MessageModel';
import { AppStorage } from '@kit.ArkUI';

export class ChatViewModel {
  private static instance: ChatViewModel | null = null;
  private store: Store;
  private chatService: ChatService;

  messages: Message[] = [];
  isTyping: boolean = false;
  currentTab: string = 'chat';
  private isInitialized: boolean = false;

  private constructor() {
    this.store = Store.getInstance();
    this.chatService = ChatService.getInstance();
  }

  static getInstance(): ChatViewModel {
    if (!this.instance) {
      this.instance = new ChatViewModel();
    }
    return this.instance;
  }

  async init(): Promise<void> {
    if (this.isInitialized) return;
    this.isInitialized = true;

    try {
      this.messages = this.store.getState().chat.messages;
      this.isTyping = this.store.getState().chat.isTyping;
    } catch (error) {
      console.error('ChatViewModel 初始化失败:', error);
    }
  }

  async sendMessage(content: string): Promise<void> {
    if (!content.trim()) return;
    await this.chatService.sendUserMessage(content);
    this.syncFromStore();
  }

  private syncFromStore(): void {
    const state = this.store.getState();
    this.messages = state.chat.messages;
    this.isTyping = state.chat.isTyping;
  }

  switchTab(tab: string): void {
    this.currentTab = tab;
  }

  clearChat(): void {
    this.chatService.clearChat();
    this.syncFromStore();
  }

  getChatHistory(): Message[] {
    return this.chatService.getChatHistory();
  }
}
