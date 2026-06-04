import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'features/pomodoro/application/pomodoro_controller.dart';
import 'features/pomodoro/domain/pomodoro_state.dart';
import 'features/tasks/application/task_board_controller.dart';
import 'features/tasks/domain/task.dart';
import 'integrations/nocodb/nocodb_base_api_client.dart';
import 'integrations/nocodb/nocodb_http.dart';
import 'integrations/nocodb/nocodb_models.dart';
import 'integrations/nocodb/nocodb_setup_service.dart';
import 'integrations/nocodb/nocodb_workspace_cache.dart';

void main() {
  runApp(const FlowTomatoApp());
}

class FlowTomatoApp extends StatelessWidget {
  const FlowTomatoApp({super.key, this.promptForNocoDBOnStart = true});

  final bool promptForNocoDBOnStart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowTomato',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: FlowTomatoHomePage(promptForNocoDBOnStart: promptForNocoDBOnStart),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFCC4A3D),
      brightness: brightness,
      surface: isDark ? const Color(0xFF121315) : const Color(0xFFF7F3EE),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'SF Pro Display',
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1B1D20) : const Color(0xFFFFFCF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE9DED2),
          ),
        ),
      ),
    );
  }
}

class FlowTomatoHomePage extends StatefulWidget {
  const FlowTomatoHomePage({super.key, this.promptForNocoDBOnStart = true});

  final bool promptForNocoDBOnStart;

  @override
  State<FlowTomatoHomePage> createState() => _FlowTomatoHomePageState();
}

class _FlowTomatoHomePageState extends State<FlowTomatoHomePage> {
  late final TaskBoardController _taskBoard;
  late final PomodoroController _pomodoro;
  final TextEditingController _newTaskController = TextEditingController();
  Timer? _timer;
  int _recordedSessions = 0;
  bool _didPromptNocoDB = false;

  @override
  void initState() {
    super.initState();
    _taskBoard = TaskBoardController()..addListener(_refresh);
    _pomodoro = PomodoroController()..addListener(_handlePomodoroChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptNocoDBSettings();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newTaskController.dispose();
    _taskBoard
      ..removeListener(_refresh)
      ..dispose();
    _pomodoro
      ..removeListener(_handlePomodoroChange)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handlePomodoroChange() {
    final state = _pomodoro.state;
    if (state.status == PomodoroStatus.completed &&
        _recordedSessions < _pomodoro.completedSessions.length) {
      final session = _pomodoro.completedSessions.last;
      if (session.stage == PomodoroStage.focus && session.taskId != null) {
        _taskBoard.recordCompletedPomodoro(session.taskId!);
      }
      _recordedSessions = _pomodoro.completedSessions.length;
      _timer?.cancel();
    }
    _refresh();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pomodoro.tick(const Duration(seconds: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.06),
                colorScheme.surface,
              ),
              Color.alphaBlend(
                const Color(0xFF4C8D7F).withValues(alpha: 0.08),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  completedTasks: _taskBoard.completedTaskCount,
                  pomodoros: _taskBoard.completedPomodoroCount,
                  focusMinutes: _taskBoard.focusMinutes,
                  onConnectNocoDB: _showNocoDBSettings,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 860) {
                        return _NarrowWorkbench(
                          taskBoard: _taskBoard,
                          pomodoro: _pomodoro,
                          newTaskController: _newTaskController,
                          onAddTask: _addTask,
                          onStartFocus: _startFocus,
                          onPause: _pomodoro.pause,
                          onResume: () {
                            _pomodoro.resume();
                            _startTicker();
                          },
                          onReset: () {
                            _timer?.cancel();
                            _pomodoro.reset();
                          },
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _TaskWorkbench(
                              taskBoard: _taskBoard,
                              newTaskController: _newTaskController,
                              onAddTask: _addTask,
                              onStartFocus: _startFocus,
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 340,
                            child: _PomodoroPanel(
                              task: _taskBoard.nowTask,
                              pomodoro: _pomodoro,
                              onStartFocus: _startFocus,
                              onPause: _pomodoro.pause,
                              onResume: () {
                                _pomodoro.resume();
                                _startTicker();
                              },
                              onReset: () {
                                _timer?.cancel();
                                _pomodoro.reset();
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addTask() {
    final text = _newTaskController.text;
    if (text.trim().isEmpty) {
      return;
    }
    _taskBoard.addTask(text);
    _newTaskController.clear();
  }

  void _startFocus() {
    final task = _taskBoard.nowTask;
    _pomodoro.startFocus(taskId: task?.id, taskTitle: task?.title);
    _startTicker();
  }

  Future<void> _showNocoDBSettings() {
    return showDialog<void>(
      context: context,
      builder: (context) => const _NocoDBSettingsDialog(),
    );
  }

  Future<void> _maybePromptNocoDBSettings() async {
    if (!widget.promptForNocoDBOnStart || _didPromptNocoDB || !mounted) {
      return;
    }
    _didPromptNocoDB = true;
    final cached = await NocoDBWorkspaceCache().read();
    if (cached != null) {
      return;
    }
    if (!mounted) {
      return;
    }
    await _showNocoDBSettings();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.completedTasks,
    required this.pomodoros,
    required this.focusMinutes,
    required this.onConnectNocoDB,
  });

  final int completedTasks;
  final int pomodoros;
  final int focusMinutes;
  final VoidCallback onConnectNocoDB;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FlowTomato',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Today focus workbench',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(label: 'Done', value: '$completedTasks'),
        _MetricPill(label: 'Tomatoes', value: '$pomodoros'),
        _MetricPill(label: 'Minutes', value: '$focusMinutes'),
        FilledButton.icon(
          onPressed: onConnectNocoDB,
          icon: const Icon(Icons.cloud_sync_rounded),
          label: const Text('Connect NocoDB'),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
}

class _NocoDBSettingsDialog extends StatefulWidget {
  const _NocoDBSettingsDialog();

  @override
  State<_NocoDBSettingsDialog> createState() => _NocoDBSettingsDialogState();
}

class _NocoDBSettingsDialogState extends State<_NocoDBSettingsDialog> {
  final TextEditingController _baseUrlController = TextEditingController(
    text: _readInitialBaseUrl(),
  );
  final TextEditingController _apiTokenController = TextEditingController(
    text: _readInitialApiToken(),
  );

  NocoDBWorkspaceConfig? _workspace;
  String? _statusMessage;
  bool _isBusy = false;
  bool _canInitialize = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('NocoDB app connection'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('nocodbBaseUrl'),
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'NocoDB Base URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('nocodbApiToken'),
                controller: _apiTokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Personal access token',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'FlowTomato will look for a FlowTomato base with Tasks, Pomodoro, and DailySummary tables. If it cannot find them, you can initialize them after confirmation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isBusy ? null : _findOrValidateWorkspace,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Find NocoDB workspace'),
              ),
              if (_canInitialize) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _confirmAndInitializeWorkspace,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Initialize FlowTomato tables'),
                ),
              ],
              if (_workspace != null) ...[
                const SizedBox(height: 12),
                _NocoDBWorkspaceSummary(workspace: _workspace!),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  ({String baseUrl, String apiToken})? _readConnectionConfig() {
    final baseUrl = _baseUrlController.text.trim();
    final apiToken = _apiTokenController.text.trim();
    if (baseUrl.isEmpty || apiToken.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill in the NocoDB URL and token.';
        _canInitialize = false;
      });
      return null;
    }
    return (baseUrl: baseUrl, apiToken: apiToken);
  }

  Future<void> _findOrValidateWorkspace() async {
    final config = _readConnectionConfig();
    if (config == null) {
      return;
    }
    setState(() {
      _isBusy = true;
      _canInitialize = false;
      _statusMessage = 'Looking for FlowTomato workspace...';
    });
    try {
      final cached = await NocoDBWorkspaceCache().read();
      final httpClient = HttpNocoDBHttpClient(
        baseUri: Uri.parse(config.baseUrl),
      );
      final setup = NocoDBSetupService(
        apiClient: NocoDBApiClient(http: httpClient),
      );
      final workspace =
          cached != null &&
              cached.baseUrl == config.baseUrl &&
              cached.apiToken == config.apiToken
          ? await setup.validateWorkspace(cached)
          : await setup.findWorkspace(
              baseUrl: config.baseUrl,
              apiToken: config.apiToken,
            );
      if (!mounted) {
        return;
      }
      if (workspace == null) {
        setState(() {
          _workspace = null;
          _canInitialize = true;
          _statusMessage =
              'No complete FlowTomato workspace was found. Initialize it?';
        });
        return;
      }
      await NocoDBWorkspaceCache().write(workspace);
      setState(() {
        _workspace = workspace;
        _canInitialize = false;
        _statusMessage = 'NocoDB workspace is ready and cached.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'NocoDB app connection failed: $error';
        _canInitialize = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _confirmAndInitializeWorkspace() async {
    final config = _readConnectionConfig();
    if (config == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize NocoDB tables?'),
        content: const Text(
          'FlowTomato will create a FlowTomato base with Tasks, Pomodoro, and DailySummary tables.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Initialize'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _isBusy = true;
      _statusMessage = 'Initializing FlowTomato tables...';
    });
    try {
      final httpClient = HttpNocoDBHttpClient(
        baseUri: Uri.parse(config.baseUrl),
      );
      final setup = NocoDBSetupService(
        apiClient: NocoDBApiClient(http: httpClient),
      );
      final workspace = await setup.initializeWorkspace(
        baseUrl: config.baseUrl,
        apiToken: config.apiToken,
      );
      await NocoDBWorkspaceCache().write(workspace);
      if (!mounted) {
        return;
      }
      setState(() {
        _workspace = workspace;
        _canInitialize = false;
        _statusMessage = 'NocoDB workspace initialized and cached.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'NocoDB initialization failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
}

String _readInitialBaseUrl() {
  const dartDefine = String.fromEnvironment('NOCO_BASE_URL');
  if (dartDefine.isNotEmpty) {
    return dartDefine;
  }
  const legacyDartDefine = String.fromEnvironment('NOCODB_BASE_URL');
  if (legacyDartDefine.isNotEmpty) {
    return legacyDartDefine;
  }
  return Platform.environment['NOCO_BASE_URL'] ??
      Platform.environment['NOCODB_BASE_URL'] ??
      'http://127.0.0.1:8080';
}

String _readInitialApiToken() {
  const dartDefine = String.fromEnvironment('NOCO_TOKEN');
  if (dartDefine.isNotEmpty) {
    return dartDefine;
  }
  const legacyDartDefine = String.fromEnvironment('NOCODB_API_TOKEN');
  if (legacyDartDefine.isNotEmpty) {
    return legacyDartDefine;
  }
  return Platform.environment['NOCO_TOKEN'] ??
      Platform.environment['NOCODB_API_TOKEN'] ??
      '';
}

class _NocoDBWorkspaceSummary extends StatelessWidget {
  const _NocoDBWorkspaceSummary({required this.workspace});

  final NocoDBWorkspaceConfig workspace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected workspace',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('Base URL: ${workspace.baseUrl}'),
            Text('Base ID: ${workspace.baseId}'),
            Text('Tasks table: ${workspace.tasksTableId}'),
            Text('Pomodoro table: ${workspace.pomodoroTableId}'),
            Text('DailySummary table: ${workspace.dailySummaryTableId}'),
          ],
        ),
      ),
    );
  }
}

class _NarrowWorkbench extends StatelessWidget {
  const _NarrowWorkbench({
    required this.taskBoard,
    required this.pomodoro,
    required this.newTaskController,
    required this.onAddTask,
    required this.onStartFocus,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  final TaskBoardController taskBoard;
  final PomodoroController pomodoro;
  final TextEditingController newTaskController;
  final VoidCallback onAddTask;
  final VoidCallback onStartFocus;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _PomodoroPanel(
            task: taskBoard.nowTask,
            pomodoro: pomodoro,
            onStartFocus: onStartFocus,
            onPause: onPause,
            onResume: onResume,
            onReset: onReset,
          ),
          const SizedBox(height: 16),
          _TaskWorkbench(
            taskBoard: taskBoard,
            newTaskController: newTaskController,
            onAddTask: onAddTask,
            onStartFocus: onStartFocus,
            scrollable: false,
          ),
        ],
      ),
    );
  }
}

class _TaskWorkbench extends StatelessWidget {
  const _TaskWorkbench({
    required this.taskBoard,
    required this.newTaskController,
    required this.onAddTask,
    required this.onStartFocus,
    this.scrollable = true,
  });

  final TaskBoardController taskBoard;
  final TextEditingController newTaskController;
  final VoidCallback onAddTask;
  final VoidCallback onStartFocus;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _NowSection(
          task: taskBoard.nowTask,
          onStartFocus: onStartFocus,
          onComplete: (task) => taskBoard.completeTask(task.id),
          onClear: (task) => taskBoard.restoreTask(task.id),
        ),
        const SizedBox(height: 14),
        _TodoSection(
          tasks: taskBoard.todoTasks,
          controller: newTaskController,
          onAddTask: onAddTask,
          onSetNow: taskBoard.setNow,
          onComplete: taskBoard.completeTask,
          onDelete: taskBoard.deleteTask,
        ),
        const SizedBox(height: 14),
        _DoneSection(
          tasks: taskBoard.doneTasks,
          onRestore: taskBoard.restoreTask,
        ),
      ],
    );
    if (!scrollable) {
      return content;
    }
    return SingleChildScrollView(child: content);
  }
}

class _NowSection extends StatelessWidget {
  const _NowSection({
    required this.task,
    required this.onStartFocus,
    required this.onComplete,
    required this.onClear,
  });

  final FlowTask? task;
  final VoidCallback onStartFocus;
  final ValueChanged<FlowTask> onComplete;
  final ValueChanged<FlowTask> onClear;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Now',
      trailing: task == null ? null : const _StateChip(label: '正在做'),
      child: task == null
          ? _EmptyState(
              icon: Icons.radio_button_checked,
              text: 'Pick a task from Todo to begin.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (task!.note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    task!.note!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PriorityBadge(priority: task!.priority),
                    _StateChip(
                      label:
                          '${task!.completedPomodoros}/${task!.plannedPomodoros} tomatoes',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onStartFocus,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => onComplete(task!),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Move back to Todo',
                      onPressed: () => onClear(task!),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TodoSection extends StatelessWidget {
  const _TodoSection({
    required this.tasks,
    required this.controller,
    required this.onAddTask,
    required this.onSetNow,
    required this.onComplete,
    required this.onDelete,
  });

  final List<FlowTask> tasks;
  final TextEditingController controller;
  final VoidCallback onAddTask;
  final ValueChanged<String> onSetNow;
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Todo',
      trailing: _StateChip(label: '${tasks.length} open'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAddTask(),
                  decoration: const InputDecoration(
                    hintText: 'Add a task for today',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add task',
                onPressed: onAddTask,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const _EmptyState(
              icon: Icons.task_alt_rounded,
              text: 'No todo tasks left.',
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TaskTile(
                  task: task,
                  onSetNow: () => onSetNow(task.id),
                  onComplete: () => onComplete(task.id),
                  onDelete: () => onDelete(task.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DoneSection extends StatelessWidget {
  const _DoneSection({required this.tasks, required this.onRestore});

  final List<FlowTask> tasks;
  final ValueChanged<String> onRestore;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Done',
      trailing: _StateChip(label: '${tasks.length} finished'),
      child: tasks.isEmpty
          ? const _EmptyState(
              icon: Icons.done_all_rounded,
              text: 'Completed work will land here.',
            )
          : Column(
              children: tasks
                  .map(
                    (task) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_rounded),
                      title: Text(task.title),
                      subtitle: Text('${task.completedPomodoros} tomatoes'),
                      trailing: TextButton(
                        onPressed: () => onRestore(task.id),
                        child: const Text('Restore'),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _PomodoroPanel extends StatelessWidget {
  const _PomodoroPanel({
    required this.task,
    required this.pomodoro,
    required this.onStartFocus,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  final FlowTask? task;
  final PomodoroController pomodoro;
  final VoidCallback onStartFocus;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final state = pomodoro.state;
    final progress = state.total.inSeconds == 0
        ? 0.0
        : 1 - (state.remaining.inSeconds / state.total.inSeconds);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pomodoro',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    _StateChip(label: _statusLabel(state.status)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 188,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0, 1),
                          strokeWidth: 11,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(state.remaining),
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.taskTitle ?? task?.title ?? 'No task linked',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: state.status == PomodoroStatus.running
                            ? onPause
                            : state.status == PomodoroStatus.paused
                            ? onResume
                            : onStartFocus,
                        icon: Icon(
                          state.status == PomodoroStatus.running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          state.status == PomodoroStatus.running
                              ? 'Pause'
                              : state.status == PomodoroStatus.paused
                              ? 'Resume'
                              : 'Start',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Reset timer',
                      onPressed: onReset,
                      icon: const Icon(Icons.replay_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '25 min focus · 5 min short break · 15 min long break',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _statusLabel(PomodoroStatus status) {
    return switch (status) {
      PomodoroStatus.idle => 'Idle',
      PomodoroStatus.running => 'Running',
      PomodoroStatus.paused => 'Paused',
      PomodoroStatus.completed => 'Complete',
    };
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onSetNow,
    required this.onComplete,
    required this.onDelete,
  });

  final FlowTask task;
  final VoidCallback onSetNow;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_priorityLabel(task.priority)} · ${task.completedPomodoros}/${task.plannedPomodoros} tomatoes',
        ),
        leading: IconButton(
          tooltip: 'Complete task',
          onPressed: onComplete,
          icon: const Icon(Icons.check_circle_outline_rounded),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            TextButton(onPressed: onSetNow, child: const Text('Focus')),
            IconButton(
              tooltip: 'Delete task',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 5),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high => const Color(0xFFCC4A3D),
      TaskPriority.medium => const Color(0xFFB0832E),
      TaskPriority.low => const Color(0xFF4C8D7F),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _priorityLabel(priority),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _priorityLabel(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => 'High',
    TaskPriority.medium => 'Medium',
    TaskPriority.low => 'Low',
  };
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
