interface ControlsProps {
  isRunning: boolean
  onStart: () => void
  onPause: () => void
  onReset: () => void
  onSkip: () => void
}

export function Controls({ isRunning, onStart, onPause, onReset, onSkip }: ControlsProps): JSX.Element {
  return (
    <div className="controls">
      <button className="btn btn-secondary" onClick={onReset} title="重置">
        ↺
      </button>

      {isRunning ? (
        <button className="btn btn-primary" onClick={onPause} title="暂停">
          ⏸ 暂停
        </button>
      ) : (
        <button className="btn btn-primary" onClick={onStart} title="开始">
          ▶ 开始
        </button>
      )}

      <button className="btn btn-secondary" onClick={onSkip} title="跳过">
        ⏭
      </button>
    </div>
  )
}
