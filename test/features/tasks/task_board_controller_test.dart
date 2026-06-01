import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tomato/features/tasks/application/task_board_controller.dart';
import 'package:flow_tomato/features/tasks/domain/task.dart';

void main() {
  group('TaskBoardController', () {
    test('setting a task as now moves any existing now task back to todo', () {
      final controller = TaskBoardController(
        initialTasks: [
          FlowTask.create(title: 'Write PRD').copyWith(status: TaskStatus.now),
          FlowTask.create(title: 'Build Flutter UI'),
        ],
      );

      final nextNowId = controller.tasks
          .firstWhere((task) => task.title == 'Build Flutter UI')
          .id;

      controller.setNow(nextNowId);

      expect(controller.nowTask?.title, 'Build Flutter UI');
      expect(
        controller.tasks.firstWhere((task) => task.title == 'Write PRD').status,
        TaskStatus.todo,
      );
    });

    test('completing the now task moves it to done and clears now', () {
      final task = FlowTask.create(title: 'Ship MVP');
      final controller = TaskBoardController(initialTasks: [task]);

      controller.setNow(task.id);
      controller.completeTask(task.id);

      expect(controller.nowTask, isNull);
      expect(controller.doneTasks.single.title, 'Ship MVP');
      expect(controller.todoTasks, isEmpty);
    });

    test('recording a focus session increments the task pomodoro count', () {
      final task = FlowTask.create(title: 'Design timer');
      final controller = TaskBoardController(initialTasks: [task]);

      controller.recordCompletedPomodoro(task.id);

      expect(controller.tasks.single.completedPomodoros, 1);
    });
  });
}
