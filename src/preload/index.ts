import { contextBridge, ipcRenderer } from 'electron'
import { electronAPI } from '@electron-toolkit/preload'

// ─── Custom API exposed to renderer ─────────────────────────────────────────

const api = {
  /** Retrieve all persisted settings */
  getSettings: (): Promise<AppSettings> => ipcRenderer.invoke('settings:get'),

  /** Update settings partially */
  setSettings: (partial: Partial<AppSettings>): Promise<AppSettings> =>
    ipcRenderer.invoke('settings:set', partial),

  /** Show a system notification */
  sendNotification: (title: string, body: string): Promise<void> =>
    ipcRenderer.invoke('notification:send', title, body),

  /** Sync a completed Pomodoro session to Feishu */
  feishuSync: (payload: FeishuSyncPayload): Promise<FeishuSyncResult> =>
    ipcRenderer.invoke('feishu:sync', payload),

  /** Send a test message to Feishu */
  feishuTest: (): Promise<FeishuSyncResult> => ipcRenderer.invoke('feishu:test')
}

// ─── Type declarations (mirrored in env.d.ts for the renderer) ───────────────

interface AppSettings {
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

interface FeishuConfig {
  webhookUrl?: string
  appId?: string
  appSecret?: string
  receiverOpenId?: string
  enabled: boolean
}

interface FeishuSyncPayload {
  phase: 'work' | 'shortBreak' | 'longBreak'
  completedPomodoros: number
  durationSeconds: number
  timestamp: number
}

interface FeishuSyncResult {
  success: boolean
  message?: string
  error?: string
}

// Use `contextBridge` APIs to expose Electron APIs to renderer only if
// context isolation is enabled, otherwise just add to the DOM global.
if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('electron', electronAPI)
    contextBridge.exposeInMainWorld('api', api)
  } catch (error) {
    console.error(error)
  }
} else {
  // @ts-ignore (define in dts)
  window.electron = electronAPI
  // @ts-ignore (define in dts)
  window.api = api
}
