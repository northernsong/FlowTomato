export interface FeishuConfig {
  /** 飞书机器人 Webhook URL（推荐，配置简单） */
  webhookUrl?: string
  /** 飞书自建应用 App ID */
  appId?: string
  /** 飞书自建应用 App Secret */
  appSecret?: string
  /** 接收消息的用户 open_id（使用 Bot API 时必填） */
  receiverOpenId?: string
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
