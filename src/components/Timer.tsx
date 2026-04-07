import type { Phase } from '../store/pomodoroStore'

interface TimerProps {
  phase: Phase
  timeLeft: number
  totalDuration: number
}

const PHASE_CONFIG: Record<Phase, { label: string; color: string; emoji: string }> = {
  work: { label: '专注工作', color: '#e74c3c', emoji: '🍅' },
  shortBreak: { label: '短休息', color: '#27ae60', emoji: '☕' },
  longBreak: { label: '长休息', color: '#2980b9', emoji: '🌿' }
}

function pad(n: number): string {
  return String(n).padStart(2, '0')
}

export function Timer({ phase, timeLeft, totalDuration }: TimerProps): JSX.Element {
  const config = PHASE_CONFIG[phase]
  const minutes = Math.floor(timeLeft / 60)
  const seconds = timeLeft % 60
  const progress = totalDuration > 0 ? (totalDuration - timeLeft) / totalDuration : 0

  // SVG ring progress
  const radius = 90
  const circumference = 2 * Math.PI * radius
  const strokeDashoffset = circumference * (1 - progress)

  return (
    <div className="timer-container">
      <div className="timer-ring-wrapper">
        <svg viewBox="0 0 220 220" className="timer-ring">
          {/* Background ring */}
          <circle
            cx="110"
            cy="110"
            r={radius}
            fill="none"
            stroke="rgba(255,255,255,0.15)"
            strokeWidth="10"
          />
          {/* Progress ring */}
          <circle
            cx="110"
            cy="110"
            r={radius}
            fill="none"
            stroke={config.color}
            strokeWidth="10"
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            transform="rotate(-90 110 110)"
            style={{ transition: 'stroke-dashoffset 0.8s ease' }}
          />
        </svg>
        <div className="timer-text">
          <span className="timer-emoji">{config.emoji}</span>
          <span className="timer-digits">
            {pad(minutes)}:{pad(seconds)}
          </span>
          <span className="timer-phase-label">{config.label}</span>
        </div>
      </div>
    </div>
  )
}
