import { Observed } from '@kit.ArkUI';

@Observed
export class Message {
  id: string = '';
  content: string = '';
  sender: 'ai' | 'user' = 'ai';
  timestamp: number = 0;
  type: 'text' | 'voice' | 'image' = 'text';

  constructor(content: string = '', sender: 'ai' | 'user' = 'ai', type: 'text' | 'voice' | 'image' = 'text') {
    this.id = Date.now().toString(36) + Math.random().toString(36).substr(2);
    this.content = content;
    this.sender = sender;
    this.timestamp = Date.now();
    this.type = type;
  }
}

export interface ChatSession {
  id: string;
  messages: Message[];
  lastActive: number;
  title: string;
}

export class MessageModel {
  static createId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  static createMessage(content: string, sender: 'ai' | 'user', type: 'text' | 'voice' | 'image' = 'text'): Message {
    return new Message(content, sender, type);
  }

  static formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${month}-${day}`;
  }
}