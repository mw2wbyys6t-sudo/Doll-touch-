export class Message {
  id: string = '';
  content: string = '';
  sender: 'ai' | 'user' = 'ai';
  timestamp: number = 0;
  type: 'text' | 'voice' | 'image' = 'text';

  constructor(content: string = '', sender: 'ai' | 'user' = 'ai', type: 'text' | 'voice' | 'image' = 'text') {
    this.id = Date.now().toString(36) + Math.random().toString(36).substring(2);
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
    return Date.now().toString(36) + Math.random().toString(36).substring(2);
  }

  static createMessage(content: string, sender: 'ai' | 'user', type: 'text' | 'voice' | 'image' = 'text'): Message {
    return new Message(content, sender, type);
  }

  static formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const h = date.getHours();
    const m = date.getMinutes();
    const hours = h < 10 ? '0' + h.toString() : h.toString();
    const minutes = m < 10 ? '0' + m.toString() : m.toString();
    return `${hours}:${minutes}`;
  }

  static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const mon = date.getMonth() + 1;
    const d = date.getDate();
    const month = mon < 10 ? '0' + mon.toString() : mon.toString();
    const day = d < 10 ? '0' + d.toString() : d.toString();
    return `${month}-${day}`;
  }
}