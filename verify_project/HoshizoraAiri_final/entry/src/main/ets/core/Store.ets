import { EmotionalState } from './EmotionalFSM';
import { Live2DState } from './AnimationScheduler';

export interface ChatMessage {
  id: string;
  type: 'user' | 'assistant';
  content: string;
  timestamp: number;
  emotion?: EmotionalState;
}

export interface UserProfile {
  id: string;
  nickname: string;
  intimacy: number;
  lastInteract: number;
  preferences: Record<string, any>;
}

export interface AppState {
  ui: {
    isDarkMode: boolean;
    isLoading: boolean;
    currentPage: string;
  };
  chat: {
    messages: ChatMessage[];
    isTyping: boolean;
    isThinking: boolean;
  };
  character: {
    emotionalState: EmotionalState;
    live2DState: Live2DState;
    voiceEnabled: boolean;
    autoSpeak: boolean;
  };
  user: UserProfile;
}

const INITIAL_STATE: AppState = {
  ui: {
    isDarkMode: false,
    isLoading: false,
    currentPage: 'chat',
  },
  chat: {
    messages: [],
    isTyping: false,
    isThinking: false,
  },
  character: {
    emotionalState: 'idle',
    live2DState: {
      currentExpression: 'idle',
      currentMotion: 'idle',
      isTalking: false,
      isThinking: false,
      lipSyncProgress: 0,
      blinkProgress: 0,
    },
    voiceEnabled: true,
    autoSpeak: true,
  },
  user: {
    id: 'user_001',
    nickname: '主人',
    intimacy: 50,
    lastInteract: Date.now(),
    preferences: {},
  },
};

export type ActionType =
  | 'TOGGLE_DARK_MODE'
  | 'SET_LOADING'
  | 'ADD_CHAT_MESSAGE'
  | 'CLEAR_CHAT'
  | 'SET_TYPING'
  | 'SET_THINKING'
  | 'UPDATE_EMOTIONAL_STATE'
  | 'UPDATE_LIVE2D_STATE'
  | 'TOGGLE_VOICE'
  | 'TOGGLE_AUTO_SPEAK'
  | 'UPDATE_USER_PROFILE'
  | 'INCREASE_INTIMACY'
  | 'RESET_STATE';

export interface Action {
  type: ActionType;
  payload?: any;
}

export type Reducer = (state: AppState, action: Action) => AppState;

export class Store {
  private static instance: Store | null = null;
  private state: AppState;
  private listeners: Array<(state: AppState) => void> = [];
  private reducers: Map<ActionType, (state: AppState, payload: any) => AppState> = new Map();

  private constructor() {
    this.state = { ...INITIAL_STATE };
    this.setupReducers();
  }

  static getInstance(): Store {
    if (!this.instance) {
      this.instance = new Store();
    }
    return this.instance;
  }

  private setupReducers(): void {
    this.reducers.set('TOGGLE_DARK_MODE', (state: AppState) => ({
      ...state,
      ui: { ...state.ui, isDarkMode: !state.ui.isDarkMode },
    }));

    this.reducers.set('SET_LOADING', (state: AppState, payload: boolean) => ({
      ...state,
      ui: { ...state.ui, isLoading: payload },
    }));

    this.reducers.set('ADD_CHAT_MESSAGE', (state: AppState, payload: ChatMessage) => ({
      ...state,
      chat: {
        ...state.chat,
        messages: [...state.chat.messages.slice(-49), payload],
      },
    }));

    this.reducers.set('CLEAR_CHAT', (state: AppState) => ({
      ...state,
      chat: { ...state.chat, messages: [] },
    }));

    this.reducers.set('SET_TYPING', (state: AppState, payload: boolean) => ({
      ...state,
      chat: { ...state.chat, isTyping: payload },
    }));

    this.reducers.set('SET_THINKING', (state: AppState, payload: boolean) => ({
      ...state,
      chat: { ...state.chat, isThinking: payload },
      character: { ...state.character, live2DState: { ...state.character.live2DState, isThinking: payload } },
    }));

    this.reducers.set('UPDATE_EMOTIONAL_STATE', (state: AppState, payload: EmotionalState) => ({
      ...state,
      character: { ...state.character, emotionalState: payload },
    }));

    this.reducers.set('UPDATE_LIVE2D_STATE', (state: AppState, payload: Live2DState) => ({
      ...state,
      character: { ...state.character, live2DState: payload },
    }));

    this.reducers.set('TOGGLE_VOICE', (state: AppState) => ({
      ...state,
      character: { ...state.character, voiceEnabled: !state.character.voiceEnabled },
    }));

    this.reducers.set('TOGGLE_AUTO_SPEAK', (state: AppState) => ({
      ...state,
      character: { ...state.character, autoSpeak: !state.character.autoSpeak },
    }));

    this.reducers.set('UPDATE_USER_PROFILE', (state: AppState, payload: Partial<UserProfile>) => ({
      ...state,
      user: { ...state.user, ...payload },
    }));

    this.reducers.set('INCREASE_INTIMACY', (state: AppState, payload: number = 1) => ({
      ...state,
      user: {
        ...state.user,
        intimacy: Math.min(100, state.user.intimacy + payload),
        lastInteract: Date.now(),
      },
    }));

    this.reducers.set('RESET_STATE', (state: AppState) => ({
      ...INITIAL_STATE,
      user: state.user,
    }));
  }

  dispatch(action: Action): void {
    const reducer = this.reducers.get(action.type);
    if (reducer) {
      this.state = reducer(this.state, action.payload);
      this.notifyListeners();
    }
  }

  getState(): AppState {
    return { ...this.state };
  }

  subscribe(listener: (state: AppState) => void): () => void {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners(): void {
    this.listeners.forEach(listener => listener(this.state));
  }

  reset(): void {
    this.dispatch({ type: 'RESET_STATE' });
  }
}
