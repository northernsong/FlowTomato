// ─── Browser-native API layer (replaces Electron IPC bridge) ─────────────────

import type { AppSettings, FeishuSyncPayload, FeishuSyncResult } from './env.d'

const SETTINGS_KEY = 'flow-tomato-settings'

export const DEFAULT_SETTINGS: AppSettings = {
  feishu: { enabled: false },
  workDuration: 25,
  shortBreakDuration: 5,
  longBreakDuration: 15,
  longBreakInterval: 4,
  autoStartBreaks: false,
  autoStartWork: false,
  notificationsEnabled: true
}

/** Retrieve all persisted settings from localStorage */
export function getSettings(): AppSettings {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY)
    if (!raw) return { ...DEFAULT_SETTINGS }
    return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) }
  } catch {
    return { ...DEFAULT_SETTINGS }
  }
}

/** Update settings (partial merge) and persist to localStorage */
export function setSettings(partial: Partial<AppSettings>): AppSettings {
  const current = getSettings()
  const updated: AppSettings = {
    ...current,
    ...partial,
    feishu: partial.feishu ? { ...current.feishu, ...partial.feishu } : current.feishu
  }
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(updated))
  return updated
}

/** Show a browser notification (requests permission if needed) */
export async function sendNotification(title: string, body: string): Promise<void> {
  const settings = getSettings()
  if (!settings.notificationsEnabled) return
  if (!('Notification' in window)) return

  if (Notification.permission === 'granted') {
    new Notification(title, { body, icon: '/icon-192x192.png' })
  } else if (Notification.permission !== 'denied') {
    const perm = await Notification.requestPermission()
    if (perm === 'granted') {
      new Notification(title, { body, icon: '/icon-192x192.png' })
    }
  }
}

/** Sync a completed Pomodoro session to Feishu via Webhook */
export async function feishuSync(payload: FeishuSyncPayload): Promise<FeishuSyncResult> {
  const settings = getSettings()
  if (!settings.feishu.enabled) {
    return { success: false, message: '飞书同步未启用' }
  }
  if (!settings.feishu.webhookUrl) {
    return { success: false, error: '未配置飞书 Webhook URL' }
  }
  return sendFeishuWebhook(settings.feishu.webhookUrl, payload)
}

/** Send a test message to Feishu */
export async function feishuTest(): Promise<FeishuSyncResult> {
  const settings = getSettings()
  if (!settings.feishu.webhookUrl) {
    return { success: false, error: '未配置飞书 Webhook URL' }
  }
  const testPayload: FeishuSyncPayload = {
    phase: 'work',
    completedPomodoros: 1,
    durationSeconds: 1500,
    timestamp: Date.now()
  }
  return sendFeishuWebhook(settings.feishu.webhookUrl, testPayload)
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

const PHASE_LABELS: Record<FeishuSyncPayload['phase'], string> = {
  work: '🍅 专注工作',
  shortBreak: '☕ 短休息',
  longBreak: '🌿 长休息'
}

function buildMessage(payload: FeishuSyncPayload): string {
  const label = PHASE_LABELS[payload.phase]
  const minutes = Math.floor(payload.durationSeconds / 60)
  const time = new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  if (payload.phase === 'work') {
    return `${label} 完成！\n⏱ 专注时长：${minutes} 分钟\n🏆 今日已完成：${payload.completedPomodoros} 个番茄\n🕐 ${time}`
  }
  return `${label} 开始！\n⏱ 休息时长：${minutes} 分钟\n🍅 已累计：${payload.completedPomodoros} 个番茄\n🕐 ${time}`
}

async function sendFeishuWebhook(
  webhookUrl: string,
  payload: FeishuSyncPayload
): Promise<FeishuSyncResult> {
  const text = buildMessage(payload)
  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify({ msg_type: 'text', content: { text } })
    })
    const data = (await response.json()) as { code: number; msg: string }
    if (data.code === 0) {
      return { success: true, message: '飞书通知发送成功' }
    }
    return { success: false, error: `飞书返回错误：${data.msg}` }
  } catch (err) {
    return { success: false, error: `发送失败：${String(err)}` }
  }
}
