import { AppStorage } from '@kit.ArkUI';

export interface PerformanceMetrics {
  fps: number;
  memoryUsage: number;
  cpuUsage: number;
  gpuUsage: number;
  lastUpdated: number;
}

export interface Alert {
  id: string;
  type: 'warning' | 'critical' | 'info';
  message: string;
  timestamp: number;
  data?: any;
}

// 兼容 HarmonyOS NEXT 的 requestAnimationFrame 替代实现
let rafId = 0;
type FrameRequestCallback = (timestamp: number) => void;
const rafCallbacks = new Map<number, FrameRequestCallback>();

function requestAnimationFrame(callback: FrameRequestCallback): number {
  const id = ++rafId;
  rafCallbacks.set(id, callback);
  setTimeout(() => {
    const cb = rafCallbacks.get(id);
    if (cb) {
      rafCallbacks.delete(id);
      cb(Date.now());
    }
  }, 16);
  return id;
}

function cancelAnimationFrame(id: number): void {
  rafCallbacks.delete(id);
}

export class PerformanceMonitor {
  private static instance: PerformanceMonitor | null = null;

  private metrics: PerformanceMetrics = {
    fps: 60,
    memoryUsage: 0,
    cpuUsage: 0,
    gpuUsage: 0,
    lastUpdated: Date.now(),
  };

  private alerts: Alert[] = [];
  private frameCount: number = 0;
  private lastFrameTime: number = Date.now();
  private animationFrame: number | null = null;
  private monitoringTimer: number | null = null;
  private alertListeners: Array<(alert: Alert) => void> = [];

  private readonly FPS_WARNING_THRESHOLD = 30;
  private readonly MEMORY_WARNING_THRESHOLD = 200;
  private readonly MAX_ALERTS = 50;

  private constructor() {}

  static getInstance(): PerformanceMonitor {
    if (!this.instance) {
      this.instance = new PerformanceMonitor();
    }
    return this.instance;
  }

  start(): void {
    console.log('PerformanceMonitor 启动');

    this.startFPSMonitor();
    this.startResourceMonitor();
  }

  private startFPSMonitor(): void {
    const loop = () => {
      this.frameCount++;

      const now = Date.now();
      const elapsed = now - this.lastFrameTime;

      if (elapsed >= 1000) {
        this.metrics.fps = Math.round((this.frameCount * 1000) / elapsed);
        this.metrics.lastUpdated = now;

        if (this.metrics.fps < this.FPS_WARNING_THRESHOLD) {
          this.addAlert({
            id: `fps_${now}`,
            type: 'warning',
            message: `FPS 降低: ${this.metrics.fps}`,
            timestamp: now,
            data: { fps: this.metrics.fps },
          });
        }

        this.frameCount = 0;
        this.lastFrameTime = now;
      }

      this.animationFrame = requestAnimationFrame(loop);
    };

    loop();
  }

  private startResourceMonitor(): void {
    if (this.monitoringTimer) {
      clearInterval(this.monitoringTimer);
    }

    this.monitoringTimer = setInterval(() => {
      this.collectMetrics();
      this.checkForWarnings();
    }, 5000) as unknown as number;
  }

  private collectMetrics(): void {
    this.metrics.memoryUsage = this.estimateMemoryUsage();
    this.metrics.lastUpdated = Date.now();
  }

  private estimateMemoryUsage(): number {
    let totalSize = 0;
    try {
      const heap = JSON.stringify(AppStorage);
      totalSize = heap.length / 1024 / 1024;
    } catch {
      totalSize = 50;
    }
    return totalSize;
  }

  private checkForWarnings(): void {
    if (this.metrics.memoryUsage > this.MEMORY_WARNING_THRESHOLD) {
      this.addAlert({
        id: `memory_${Date.now()}`,
        type: 'warning',
        message: `高内存使用: ${Math.round(this.metrics.memoryUsage)} MB`,
        timestamp: Date.now(),
        data: { memory: this.metrics.memoryUsage },
      });
    }
  }

  getMetrics(): PerformanceMetrics {
    return { ...this.metrics };
  }

  getRecentAlerts(count: number = 10): Alert[] {
    return this.alerts.slice(-count);
  }

  getAllAlerts(): Alert[] {
    return [...this.alerts];
  }

  private addAlert(alert: Alert): void {
    this.alerts.push(alert);

    if (this.alerts.length > this.MAX_ALERTS) {
      this.alerts.shift();
    }

    this.alertListeners.forEach(listener => listener(alert));
  }

  onAlert(callback: (alert: Alert) => void): () => void {
    this.alertListeners.push(callback);
    return () => {
      this.alertListeners = this.alertListeners.filter(l => l !== callback);
    };
  }

  recordAction(duration: number, actionName: string): void {
    if (duration > 100) {
      this.addAlert({
        id: `slow_action_${Date.now()}`,
        type: 'warning',
        message: `慢操作: ${actionName} (${Math.round(duration)}ms)`,
        timestamp: Date.now(),
        data: { action: actionName, duration },
      });
    }
  }

  clearAlerts(): void {
    this.alerts = [];
  }

  stop(): void {
    console.log('PerformanceMonitor 停止');

    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
      this.animationFrame = null;
    }

    if (this.monitoringTimer) {
      clearInterval(this.monitoringTimer);
      this.monitoringTimer = null;
    }
  }

  reset(): void {
    this.metrics = {
      fps: 60,
      memoryUsage: 0,
      cpuUsage: 0,
      gpuUsage: 0,
      lastUpdated: Date.now(),
    };
    this.alerts = [];
    this.frameCount = 0;
  }

  getPerformanceReport(): string {
    const fps = this.metrics.fps;
    const memory = this.metrics.memoryUsage.toFixed(2);
    const warnings = this.alerts.filter(a => a.type === 'warning').length;

    return `性能报告:
- FPS: ${fps}
- 内存: ${memory} MB
- 警告: ${warnings}
`;
  }
}
