import { useState } from 'react'
import type { AppSettings, FeishuSyncResult } from '../env.d'

interface SettingsProps {
  settings: AppSettings
  onSave: (partial: Partial<AppSettings>) => Promise<void>
  onFeishuTest: () => Promise<FeishuSyncResult>
}

export function Settings({ settings, onSave, onFeishuTest }: SettingsProps): JSX.Element {
  const [form, setForm] = useState<AppSettings>(settings)
  const [testResult, setTestResult] = useState<FeishuSyncResult | null>(null)
  const [testing, setTesting] = useState(false)
  const [saved, setSaved] = useState(false)

  function handleChange<K extends keyof AppSettings>(key: K, value: AppSettings[K]): void {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  function handleFeishuChange<K extends keyof AppSettings['feishu']>(
    key: K,
    value: AppSettings['feishu'][K]
  ): void {
    setForm((prev) => ({ ...prev, feishu: { ...prev.feishu, [key]: value } }))
  }

  async function handleSave(): Promise<void> {
    await onSave(form)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  async function handleTest(): Promise<void> {
    setTesting(true)
    setTestResult(null)
    // Save feishu config first
    await onSave({ feishu: form.feishu })
    const result = await onFeishuTest()
    setTestResult(result)
    setTesting(false)
  }

  return (
    <div className="settings">
      <h2 className="settings-title">⚙️ 设置</h2>

      {/* Timer durations */}
      <section className="settings-section">
        <h3>⏱ 时间设置</h3>
        <div className="setting-row">
          <label>专注时长（分钟）</label>
          <input
            type="number"
            min={1}
            max={120}
            value={form.workDuration}
            onChange={(e) => handleChange('workDuration', Number(e.target.value))}
          />
        </div>
        <div className="setting-row">
          <label>短休息时长（分钟）</label>
          <input
            type="number"
            min={1}
            max={60}
            value={form.shortBreakDuration}
            onChange={(e) => handleChange('shortBreakDuration', Number(e.target.value))}
          />
        </div>
        <div className="setting-row">
          <label>长休息时长（分钟）</label>
          <input
            type="number"
            min={1}
            max={60}
            value={form.longBreakDuration}
            onChange={(e) => handleChange('longBreakDuration', Number(e.target.value))}
          />
        </div>
        <div className="setting-row">
          <label>每几个番茄后长休息</label>
          <input
            type="number"
            min={2}
            max={10}
            value={form.longBreakInterval}
            onChange={(e) => handleChange('longBreakInterval', Number(e.target.value))}
          />
        </div>
      </section>

      {/* Auto-start */}
      <section className="settings-section">
        <h3>🔄 自动开始</h3>
        <div className="setting-row">
          <label>自动开始休息</label>
          <input
            type="checkbox"
            checked={form.autoStartBreaks}
            onChange={(e) => handleChange('autoStartBreaks', e.target.checked)}
          />
        </div>
        <div className="setting-row">
          <label>自动开始专注</label>
          <input
            type="checkbox"
            checked={form.autoStartWork}
            onChange={(e) => handleChange('autoStartWork', e.target.checked)}
          />
        </div>
        <div className="setting-row">
          <label>系统通知</label>
          <input
            type="checkbox"
            checked={form.notificationsEnabled}
            onChange={(e) => handleChange('notificationsEnabled', e.target.checked)}
          />
        </div>
        <div className="setting-row">
          <label>窗口置顶</label>
          <input
            type="checkbox"
            checked={form.alwaysOnTop}
            onChange={(e) => handleChange('alwaysOnTop', e.target.checked)}
          />
        </div>
      </section>

      {/* Feishu integration */}
      <section className="settings-section">
        <h3>🔗 飞书同步</h3>
        <div className="setting-row">
          <label>启用飞书同步</label>
          <input
            type="checkbox"
            checked={form.feishu.enabled}
            onChange={(e) => handleFeishuChange('enabled', e.target.checked)}
          />
        </div>

        {form.feishu.enabled && (
          <>
            <p className="settings-hint">
              方式一：Webhook（推荐）<br />
              在飞书群聊中添加「自定义机器人」，复制 Webhook URL 填入下方。
            </p>
            <div className="setting-row setting-row-full">
              <label>Webhook URL</label>
              <input
                type="url"
                placeholder="https://open.feishu.cn/open-apis/bot/v2/hook/..."
                value={form.feishu.webhookUrl ?? ''}
                onChange={(e) => handleFeishuChange('webhookUrl', e.target.value || undefined)}
              />
            </div>

            <p className="settings-hint">
              方式二：Bot API（支持更多功能）<br />
              在飞书开放平台创建「自建应用」，获取 App ID 和 App Secret。
            </p>
            <div className="setting-row setting-row-full">
              <label>App ID</label>
              <input
                type="text"
                placeholder="cli_xxxxxxxxxxxxxxxx"
                value={form.feishu.appId ?? ''}
                onChange={(e) => handleFeishuChange('appId', e.target.value || undefined)}
              />
            </div>
            <div className="setting-row setting-row-full">
              <label>App Secret</label>
              <input
                type="password"
                placeholder="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                value={form.feishu.appSecret ?? ''}
                onChange={(e) => handleFeishuChange('appSecret', e.target.value || undefined)}
              />
            </div>
            <div className="setting-row setting-row-full">
              <label>接收消息的 Open ID</label>
              <input
                type="text"
                placeholder="ou_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                value={form.feishu.receiverOpenId ?? ''}
                onChange={(e) => handleFeishuChange('receiverOpenId', e.target.value || undefined)}
              />
            </div>

            <div className="settings-actions-row">
              <button
                className="btn btn-secondary btn-small"
                onClick={handleTest}
                disabled={testing}
              >
                {testing ? '发送中...' : '🧪 测试连接'}
              </button>
            </div>

            {testResult && (
              <div className={`settings-feedback ${testResult.success ? 'success' : 'error'}`}>
                {testResult.success ? `✅ ${testResult.message}` : `❌ ${testResult.error}`}
              </div>
            )}
          </>
        )}
      </section>

      <div className="settings-footer">
        <button className="btn btn-primary" onClick={handleSave}>
          {saved ? '✅ 已保存' : '💾 保存设置'}
        </button>
      </div>
    </div>
  )
}
