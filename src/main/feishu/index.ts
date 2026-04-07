import * as lark from '@larksuiteoapi/node-sdk'
import type { FeishuConfig, FeishuSyncPayload, FeishuSyncResult } from './types'

const PHASE_LABELS: Record<FeishuSyncPayload['phase'], string> = {
  work: '🍅 专注工作',
  shortBreak: '☕ 短休息',
  longBreak: '🌿 长休息'
}

/**
 * 飞书同步服务
 * 支持两种方式：
 * 1. Webhook URL（推荐）：在飞书群聊中添加自定义机器人，获取 Webhook URL
 * 2. Bot API：使用飞书自建应用的 App ID 和 App Secret，可向指定用户发消息
 */
export class FeishuService {
  private config: FeishuConfig
  private client: lark.Client | null = null

  constructor(config: FeishuConfig) {
    this.config = config
    if (config.appId && config.appSecret) {
      this.client = new lark.Client({
        appId: config.appId,
        appSecret: config.appSecret,
        disableTokenCache: false
      })
    }
  }

  updateConfig(config: FeishuConfig): void {
    this.config = config
    if (config.appId && config.appSecret) {
      this.client = new lark.Client({
        appId: config.appId,
        appSecret: config.appSecret,
        disableTokenCache: false
      })
    } else {
      this.client = null
    }
  }

  async syncSession(payload: FeishuSyncPayload): Promise<FeishuSyncResult> {
    if (!this.config.enabled) {
      return { success: false, message: '飞书同步未启用' }
    }

    const label = PHASE_LABELS[payload.phase]
    const minutes = Math.floor(payload.durationSeconds / 60)
    const text = this.buildMessage(label, minutes, payload.completedPomodoros, payload.phase)

    if (this.config.webhookUrl) {
      return this.sendWebhook(text)
    }

    if (this.client && this.config.receiverOpenId) {
      return this.sendBotMessage(text)
    }

    return { success: false, error: '未配置飞书同步方式，请填写 Webhook URL 或 Bot API 信息' }
  }

  private buildMessage(
    label: string,
    minutes: number,
    completedPomodoros: number,
    phase: FeishuSyncPayload['phase']
  ): string {
    const time = new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
    if (phase === 'work') {
      return `${label} 完成！\n⏱ 专注时长：${minutes} 分钟\n🏆 今日已完成：${completedPomodoros} 个番茄\n🕐 ${time}`
    }
    return `${label} 开始！\n⏱ 休息时长：${minutes} 分钟\n🍅 已累计：${completedPomodoros} 个番茄\n🕐 ${time}`
  }

  private async sendWebhook(text: string): Promise<FeishuSyncResult> {
    const url = this.config.webhookUrl!
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=utf-8' },
        body: JSON.stringify({
          msg_type: 'text',
          content: { text }
        })
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

  private async sendBotMessage(text: string): Promise<FeishuSyncResult> {
    if (!this.client) {
      return { success: false, error: '飞书客户端未初始化' }
    }
    try {
      await this.client.im.v1.message.create({
        params: { receive_id_type: 'open_id' },
        data: {
          receive_id: this.config.receiverOpenId!,
          msg_type: 'text',
          content: JSON.stringify({ text })
        }
      })
      return { success: true, message: '飞书消息发送成功' }
    } catch (err) {
      return { success: false, error: `发送失败：${String(err)}` }
    }
  }
}
