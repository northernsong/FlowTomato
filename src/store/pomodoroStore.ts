import { create } from 'zustand'
import type { AppSettings, FeishuSyncResult } from '../env.d'
import { DEFAULT_SETTINGS, getSettings, setSettings, sendNotification, feishuSync } from '../api'

// ─── Types ────────────────────────────────────────────────────────────────────

export type Phase = 'work' | 'shortBreak' | 'longBreak'

export interface Session {
  id: string
  phase: Phase
  durationSeconds: number
  completedAt: number
  feishuSynced: boolean
}

export interface PomodoroState {
  // Timer state
  phase: Phase
  timeLeft: number          // seconds
  isRunning: boolean
  completedPomodoros: number
  sessions: Session[]

  // Settings
  settings: AppSettings

  // Feishu last sync result
  lastSyncResult: FeishuSyncResult | null

  // UI state
  activeTab: 'timer' | 'history' | 'settings'
}

export interface PomodoroActions {
  start: () => void
  pause: () => void
  reset: () => void
  skip: () => void
  tick: () => void
  completePhase: () => void
  loadSettings: () => void
  saveSettings: (partial: Partial<AppSettings>) => void
  setActiveTab: (tab: PomodoroState['activeTab']) => void
  setLastSyncResult: (result: FeishuSyncResult | null) => void
}

// ─── Store ────────────────────────────────────────────────────────────────────

const initialSettings = getSettings()

export const usePomodoroStore = create<PomodoroState & PomodoroActions>((set, get) => ({
  // Initial state
  phase: 'work',
  timeLeft: initialSettings.workDuration * 60,
  isRunning: false,
  completedPomodoros: 0,
  sessions: [],
  settings: initialSettings,
  lastSyncResult: null,
  activeTab: 'timer',

  start: () => set({ isRunning: true }),
  pause: () => set({ isRunning: false }),

  reset: () => {
    const { phase, settings } = get()
    const s = settings ?? DEFAULT_SETTINGS
    const durations: Record<Phase, number> = {
      work: s.workDuration * 60,
      shortBreak: s.shortBreakDuration * 60,
      longBreak: s.longBreakDuration * 60
    }
    set({ isRunning: false, timeLeft: durations[phase] })
  },

  skip: () => {
    get().completePhase()
  },

  tick: () => {
    const { timeLeft, isRunning } = get()
    if (!isRunning) return
    if (timeLeft <= 1) {
      get().completePhase()
    } else {
      set({ timeLeft: timeLeft - 1 })
    }
  },

  completePhase: () => {
    const { phase, completedPomodoros, settings } = get()
    const s = settings ?? DEFAULT_SETTINGS

    // Record session
    const durationSeconds =
      phase === 'work'
        ? s.workDuration * 60
        : phase === 'shortBreak'
          ? s.shortBreakDuration * 60
          : s.longBreakDuration * 60

    const session: Session = {
      id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
      phase,
      durationSeconds,
      completedAt: Date.now(),
      feishuSynced: false
    }

    // Determine next phase
    let newCompletedPomodoros = completedPomodoros
    let nextPhase: Phase = 'work'

    if (phase === 'work') {
      newCompletedPomodoros += 1
      const isLongBreak = newCompletedPomodoros % s.longBreakInterval === 0
      nextPhase = isLongBreak ? 'longBreak' : 'shortBreak'
    }
    // else work follows any break

    const nextDurations: Record<Phase, number> = {
      work: s.workDuration * 60,
      shortBreak: s.shortBreakDuration * 60,
      longBreak: s.longBreakDuration * 60
    }

    const autoStart =
      (nextPhase !== 'work' && s.autoStartBreaks) || (nextPhase === 'work' && s.autoStartWork)

    set((state) => ({
      phase: nextPhase,
      timeLeft: nextDurations[nextPhase],
      isRunning: autoStart,
      completedPomodoros: newCompletedPomodoros,
      sessions: [session, ...state.sessions].slice(0, 100) // keep last 100
    }))

    // Fire side effects: notification + feishu sync
    const phaseLabels: Record<Phase, string> = {
      work: '专注完成！',
      shortBreak: '短休息结束',
      longBreak: '长休息结束'
    }
    sendNotification('FlowTomato 🍅', phaseLabels[phase])

    if (s.feishu.enabled) {
      const payload = {
        phase,
        completedPomodoros: newCompletedPomodoros,
        durationSeconds,
        timestamp: Date.now()
      }
      feishuSync(payload).then((result) => {
        get().setLastSyncResult(result)
        // Mark the session as synced
        set((state) => ({
          sessions: state.sessions.map((sess) =>
            sess.id === session.id ? { ...sess, feishuSynced: result.success } : sess
          )
        }))
      })
    }
  },

  loadSettings: () => {
    const settings = getSettings()
    set((state) => {
      if (state.isRunning) return { settings }
      const phaseDurationKey: Record<Phase, keyof AppSettings> = {
        work: 'workDuration',
        shortBreak: 'shortBreakDuration',
        longBreak: 'longBreakDuration'
      }
      const durationMinutes = settings[phaseDurationKey[state.phase]] as number
      return { settings, timeLeft: durationMinutes * 60 }
    })
  },

  saveSettings: (partial) => {
    const updated = setSettings(partial)
    set({ settings: updated })
  },

  setActiveTab: (tab) => set({ activeTab: tab }),
  setLastSyncResult: (result) => set({ lastSyncResult: result })
}))
