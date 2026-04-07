import type { Session } from '../store/pomodoroStore'

interface HistoryProps {
  sessions: Session[]
  completedPomodoros: number
}

const PHASE_LABELS: Record<Session['phase'], string> = {
  work: '🍅 专注',
  shortBreak: '☕ 短休息',
  longBreak: '🌿 长休息'
}

function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return s > 0 ? `${m}分${s}秒` : `${m}分钟`
}

function formatTime(ts: number): string {
  return new Date(ts).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
}

export function History({ sessions, completedPomodoros }: HistoryProps): JSX.Element {
  const todaySessions = sessions.filter((s) => {
    const today = new Date()
    const d = new Date(s.completedAt)
    return (
      d.getFullYear() === today.getFullYear() &&
      d.getMonth() === today.getMonth() &&
      d.getDate() === today.getDate()
    )
  })

  const workCount = todaySessions.filter((s) => s.phase === 'work').length
  const totalFocusMinutes = Math.round(
    todaySessions
      .filter((s) => s.phase === 'work')
      .reduce((sum, s) => sum + s.durationSeconds, 0) / 60
  )

  return (
    <div className="history">
      <h2 className="history-title">📊 今日记录</h2>

      <div className="history-stats">
        <div className="stat-card">
          <div className="stat-value">{completedPomodoros}</div>
          <div className="stat-label">累计番茄</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{workCount}</div>
          <div className="stat-label">今日番茄</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{totalFocusMinutes}</div>
          <div className="stat-label">专注分钟</div>
        </div>
      </div>

      {todaySessions.length === 0 ? (
        <div className="history-empty">
          <p>今天还没有记录</p>
          <p>开始你的第一个番茄吧！🍅</p>
        </div>
      ) : (
        <ul className="history-list">
          {todaySessions.map((s) => (
            <li key={s.id} className="history-item">
              <span className="history-phase">{PHASE_LABELS[s.phase]}</span>
              <span className="history-duration">{formatDuration(s.durationSeconds)}</span>
              <span className="history-time">{formatTime(s.completedAt)}</span>
              {s.feishuSynced && <span className="history-synced">📤</span>}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
