import { usePomodoro } from './hooks/usePomodoro'
import { usePomodoroStore } from './store/pomodoroStore'
import { Timer } from './components/Timer'
import { Controls } from './components/Controls'
import { History } from './components/History'
import { Settings } from './components/Settings'
import { feishuTest } from './api'
import type { AppSettings } from './env.d'

const DEFAULT_DURATIONS = {
  work: 25 * 60,
  shortBreak: 5 * 60,
  longBreak: 15 * 60
}

export default function App(): JSX.Element {
  usePomodoro()

  const {
    phase,
    timeLeft,
    isRunning,
    completedPomodoros,
    sessions,
    settings,
    lastSyncResult,
    activeTab,
    start,
    pause,
    reset,
    skip,
    saveSettings,
    setActiveTab
  } = usePomodoroStore()

  const totalDuration = settings
    ? (phase === 'work'
        ? settings.workDuration
        : phase === 'shortBreak'
          ? settings.shortBreakDuration
          : settings.longBreakDuration) * 60
    : DEFAULT_DURATIONS[phase]

  const TABS = [
    { id: 'timer' as const, label: '⏱ 计时' },
    { id: 'history' as const, label: '📋 记录' },
    { id: 'settings' as const, label: '⚙️ 设置' }
  ]

  return (
    <div className={`app phase-${phase}`}>
      {/* Header */}
      <header className="app-header">
        <h1 className="app-title">🍅 FlowTomato</h1>
        <div className="pomodoro-count" title="今日已完成番茄数">
          {'🍅'.repeat(Math.min(completedPomodoros % 4 || (completedPomodoros > 0 ? 4 : 0), 4))}
          {completedPomodoros > 0 && (
            <span className="pomodoro-total"> ×{completedPomodoros}</span>
          )}
        </div>
      </header>

      {/* Tab navigation */}
      <nav className="tabs">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            className={`tab-btn ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </nav>

      {/* Tab content */}
      <main className="app-main">
        {activeTab === 'timer' && (
          <div className="timer-tab">
            <Timer phase={phase} timeLeft={timeLeft} totalDuration={totalDuration} />
            <Controls
              isRunning={isRunning}
              onStart={start}
              onPause={pause}
              onReset={reset}
              onSkip={skip}
            />
            {lastSyncResult && (
              <div className={`sync-status ${lastSyncResult.success ? 'success' : 'error'}`}>
                {lastSyncResult.success
                  ? `✅ ${lastSyncResult.message ?? '飞书同步成功'}`
                  : `⚠️ ${lastSyncResult.error ?? '飞书同步失败'}`}
              </div>
            )}
          </div>
        )}

        {activeTab === 'history' && (
          <History sessions={sessions} completedPomodoros={completedPomodoros} />
        )}

        {activeTab === 'settings' && (
          <Settings
            settings={settings}
            onSave={(partial: Partial<AppSettings>) => saveSettings(partial)}
            onFeishuTest={feishuTest}
          />
        )}
      </main>
    </div>
  )
}
