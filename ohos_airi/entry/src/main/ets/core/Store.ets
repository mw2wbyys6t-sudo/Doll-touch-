import { AppStorage } from '@kit.ArkUI';

export interface ChatMessage {
  id: string;
  type: 'user' | 'assistant';
  content: string;
  timestamp: number;
  emotion?: string;
}

export type ActionType =
  | 'ADD_CHAT_MESSAGE'
  | 'CLEAR_CHAT'
  | 'SET_THINKING'
  | 'UPDATE_EMOTIONAL_STATE'
  | 'INCREASE_INTIMACY'
  | 'TOGGLE_VOICE'
  | 'TOGGLE_AUTO_SPEAK'
  | 'TOGGLE_DARK_MODE';

export interface Action {
  type: ActionType;
  payload?: unknown;
}

export interface AppState {
  chat: {
    messages: ChatMessage[];
    isTyping: boolean;
  };
  character: {
    intimacy: number;
    voiceEnabled: boolean;
    autoSpeak: boolean;
    darkMode: boolean;
    emotionalState: string;
  };
}

const INITIAL_STATE: AppState = {
  chat: {
    messages: [],
    isTyping: false,
  },
  character: {
    intimacy: 0,
    voiceEnabled: true,
    autoSpeak: true,
    darkMode: false,
    emotionalState: 'idle',
  },
};

export class Store {
  private static instance: Store | null = null;
  private state: AppState;
  private listeners: Set<(state: AppState) => void> = new Set();

  private constructor() {
    this.state = { ...INITIAL_STATE };
  }

  static getInstance(): Store {
    if (!this.instance) {
      this.instance = new Store();
    }
    return this.instance;
  }

  getState(): AppState {
    return this.state;
  }

  dispatch(action: Action): void {
    this.state = this.reducer(this.state, action);
    this.notifyListeners();
  }

  private reducer(state: AppState, action: Action): AppState {
    switch (action.type) {
      case 'ADD_CHAT_MESSAGE':
        return {
          ...state,
          chat: {
            ...state.chat,
            messages: [...state.chat.messages, action.payload as ChatMessage],
          },
        };
      case 'CLEAR_CHAT':
        return {
          ...state,
          chat: {
            ...state.chat,
            messages: [],
          },
        };
      case 'SET_THINKING':
        return {
          ...state,
          chat: {
            ...state.chat,
            isTyping: action.payload as boolean,
          },
        };
      case 'UPDATE_EMOTIONAL_STATE':
        return {
          ...state,
          character: {
            ...state.character,
            emotionalState: action.payload as string,
          },
        };
      case 'INCREASE_INTIMACY':
        return {
          ...state,
          character: {
            ...state.character,
            intimacy: state.character.intimacy + (action.payload as number),
          },
        };
      case 'TOGGLE_VOICE':
        return {
          ...state,
          character: {
            ...state.character,
            voiceEnabled: !state.character.voiceEnabled,
          },
        };
      case 'TOGGLE_AUTO_SPEAK':
        return {
          ...state,
          character: {
            ...state.character,
            autoSpeak: !state.character.autoSpeak,
          },
        };
      case 'TOGGLE_DARK_MODE':
        return {
          ...state,
          character: {
            ...state.character,
            darkMode: !state.character.darkMode,
          },
        };
      default:
        return state;
    }
  }

  subscribe(listener: (state: AppState) => void): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  private notifyListeners(): void {
    this.listeners.forEach((listener) => {
      try {
        listener(this.state);
      } catch (error) {
        console.error('Store listener error:', error);
      }
    });
  }
}
