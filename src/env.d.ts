/// <reference types="vite/client" />

// ─── App types ────────────────────────────────────────────────────────────────

export interface AppSettings {
  feishu: FeishuConfig
  workDuration: number
  shortBreakDuration: number
  longBreakDuration: number
  longBreakInterval: number
  autoStartBreaks: boolean
  autoStartWork: boolean
  notificationsEnabled: boolean
}

export interface FeishuConfig {
  /** 飞书机器人 Webhook URL */
  webhookUrl?: string
  /** 是否启用飞书同步 */
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
