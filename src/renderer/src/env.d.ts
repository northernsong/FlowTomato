/// <reference types="vite/client" />

// ─── API types shared between main / preload / renderer ──────────────────────

export interface AppSettings {
  feishu: FeishuConfig
  workDuration: number
  shortBreakDuration: number
  longBreakDuration: number
  longBreakInterval: number
  autoStartBreaks: boolean
  autoStartWork: boolean
  notificationsEnabled: boolean
  alwaysOnTop: boolean
}

export interface FeishuConfig {
  webhookUrl?: string
  appId?: string
  appSecret?: string
  receiverOpenId?: string
  enabled: boolean
}

export interface FeishuSyncPayload {
  phase: 'work' | 'shortBreak' | 'longBreak'
  completedPomodoros: number
  durationSeconds: number
  timestamp: number
}

export interface FeishuSyncResult {
  success: boolean
  message?: string
  error?: string
}

// ─── Augment `window` with the preload bridge ────────────────────────────────

declare global {
  interface Window {
    api: {
      getSettings: () => Promise<AppSettings>
      setSettings: (partial: Partial<AppSettings>) => Promise<AppSettings>
      sendNotification: (title: string, body: string) => Promise<void>
      feishuSync: (payload: FeishuSyncPayload) => Promise<FeishuSyncResult>
      feishuTest: () => Promise<FeishuSyncResult>
    }
  }
}
