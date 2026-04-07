import { useEffect, useRef } from 'react'
import { usePomodoroStore } from '../store/pomodoroStore'

/**
 * Drives the Pomodoro countdown tick every second.
 * Also bootstraps settings from the main process on mount.
 */
export function usePomodoro(): void {
  const { isRunning, tick, loadSettings } = usePomodoroStore()
  const tickRef = useRef(tick)
  tickRef.current = tick

  // Load persisted settings once on mount
  useEffect(() => {
    loadSettings()
  }, [loadSettings])

  // Countdown ticker
  useEffect(() => {
    if (!isRunning) return
    const id = setInterval(() => tickRef.current(), 1000)
    return () => clearInterval(id)
  }, [isRunning])
}
