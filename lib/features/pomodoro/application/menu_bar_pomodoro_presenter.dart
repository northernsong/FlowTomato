import 'package:flutter/services.dart';

import '../domain/pomodoro_state.dart';

class MenuBarPomodoroSnapshot {
  const MenuBarPomodoroSnapshot({
    required this.statusLabel,
    required this.timeLabel,
    required this.detailLabel,
    required this.progress,
    required this.menuBarTitle,
    required this.canPause,
    required this.canResume,
    required this.canReset,
  });

  factory MenuBarPomodoroSnapshot.fromState(PomodoroState state) {
    final progress = _progressFor(state);
    final timeLabel = _formatDuration(state.remaining);
    final statusLabel = switch (state.status) {
      PomodoroStatus.idle => 'Ready',
      PomodoroStatus.running => switch (state.stage) {
        PomodoroStage.focus => 'Focusing',
        PomodoroStage.shortBreak => 'Short break',
        PomodoroStage.longBreak => 'Long break',
      },
      PomodoroStatus.paused => 'Paused',
      PomodoroStatus.completed => 'Completed',
    };
    final menuBarTitle = switch (state.status) {
      PomodoroStatus.idle => 'FlowTomato',
      PomodoroStatus.running => '$timeLabel ${_progressBar(progress)}',
      PomodoroStatus.paused => 'Paused $timeLabel',
      PomodoroStatus.completed => 'Done',
    };

    return MenuBarPomodoroSnapshot(
      statusLabel: statusLabel,
      timeLabel: timeLabel,
      detailLabel: state.taskTitle?.trim().isNotEmpty == true
          ? state.taskTitle!.trim()
          : _stageLabel(state.stage),
      progress: progress,
      menuBarTitle: menuBarTitle,
      canPause: state.status == PomodoroStatus.running,
      canResume: state.status == PomodoroStatus.paused,
      canReset:
          state.status == PomodoroStatus.running ||
          state.status == PomodoroStatus.paused ||
          state.status == PomodoroStatus.completed,
    );
  }

  final String statusLabel;
  final String timeLabel;
  final String detailLabel;
  final double progress;
  final String menuBarTitle;
  final bool canPause;
  final bool canResume;
  final bool canReset;

  Map<String, Object> toMap() {
    return {
      'statusLabel': statusLabel,
      'timeLabel': timeLabel,
      'detailLabel': detailLabel,
      'progress': progress,
      'menuBarTitle': menuBarTitle,
      'canPause': canPause,
      'canResume': canResume,
      'canReset': canReset,
    };
  }

  static double _progressFor(PomodoroState state) {
    if (state.total <= Duration.zero) {
      return 0;
    }
    final elapsed = state.total - state.remaining;
    return (elapsed.inMilliseconds / state.total.inMilliseconds).clamp(0, 1);
  }

  static String _formatDuration(Duration duration) {
    final sanitized = duration.isNegative ? Duration.zero : duration;
    final minutes = sanitized.inMinutes;
    final seconds = sanitized.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String _progressBar(double progress) {
    const segments = 10;
    final filled = (progress * segments).floor().clamp(0, segments);
    return '[${'#' * filled}${'-' * (segments - filled)}]';
  }

  static String _stageLabel(PomodoroStage stage) {
    return switch (stage) {
      PomodoroStage.focus => 'Focus session',
      PomodoroStage.shortBreak => 'Short break',
      PomodoroStage.longBreak => 'Long break',
    };
  }
}

class MenuBarPomodoroBridge {
  MenuBarPomodoroBridge({
    MethodChannel channel = const MethodChannel('flow_tomato/menu_bar'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> configureActions({
    required VoidCallback onPause,
    required VoidCallback onResume,
    required VoidCallback onReset,
  }) async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'pause':
          onPause();
        case 'resume':
          onResume();
        case 'reset':
          onReset();
      }
    });
  }

  Future<void> update(PomodoroState state) async {
    try {
      await _channel.invokeMethod<void>(
        'updatePomodoro',
        MenuBarPomodoroSnapshot.fromState(state).toMap(),
      );
    } on MissingPluginException {
      // The menu bar bridge only exists in the macOS runner.
    }
  }
}
