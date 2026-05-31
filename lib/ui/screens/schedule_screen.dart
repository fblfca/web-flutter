import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_target.dart';
import '../../state/schedule_controller.dart';
import '../widgets/api_settings_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_card.dart';
import '../widgets/schedule_week_grid.dart';

/// Экран расписания выбранной группы или преподавателя.
///
/// `target` приходит из маршрута `go_router`: на главном экране пользователь
/// нажимает на результат поиска, `HomeScreen` передает `ScheduleTarget`, а этот
/// экран просит `ScheduleController` загрузить занятия за текущую неделю.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    required this.target,
    super.key,
  });

  static const routeName = 'schedule';

  final ScheduleTarget target;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loadedInitialTarget = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadedInitialTarget) {
      return;
    }

    _loadedInitialTarget = true;
    // Загрузка запускается после первого кадра, потому что во время build /
    // didChangeDependencies нельзя безопасно менять ChangeNotifier, от которого
    // зависит текущий виджет. Post-frame callback откладывает запрос на момент,
    // когда дерево виджетов уже построено.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleController>().loadScheduleFor(widget.target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();
    final dateFormat = DateFormat('d MMM', 'ru_RU');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.target.title),
        actions: [
          IconButton(
            tooltip: 'Предыдущая неделя',
            onPressed: controller.scheduleStatus == LoadStatus.loading
                ? null
                : controller.showPreviousWeek,
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton.icon(
            onPressed: controller.scheduleStatus == LoadStatus.loading
                ? null
                : controller.showCurrentWeek,
            icon: const Icon(Icons.today),
            label: const Text('Сегодня'),
          ),
          IconButton(
            tooltip: 'Следующая неделя',
            onPressed: controller.scheduleStatus == LoadStatus.loading
                ? null
                : controller.showNextWeek,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Обновить расписание',
            onPressed: controller.scheduleStatus == LoadStatus.loading
                ? null
                : controller.reloadSelectedSchedule,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Настройки API',
            onPressed: () => showApiSettingsSheet(context),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          _ScheduleHeader(
            target: widget.target,
            weekTitle:
                '${dateFormat.format(controller.week.start)} - '
                '${dateFormat.format(controller.week.finish)}',
            totalLessons: controller.totalLessons,
            occupiedDays: controller.occupiedDays,
          ),
          Expanded(
            child: switch (controller.scheduleStatus) {
              // Все состояния загрузки расписания отображаются здесь. Это
              // делает экран предсказуемым: loading -> индикатор, error ->
              // сообщение, пустой список -> пустое состояние, успех -> календарь.
              LoadStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              LoadStatus.error => EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Расписание не загрузилось',
                  message: controller.errorMessage,
                ),
              _ when controller.lessons.isEmpty => const EmptyState(
                  icon: Icons.event_busy,
                  title: 'На этой неделе занятий нет',
                  message: 'Можно переключить неделю стрелками в верхней панели.',
                ),
              _ => LayoutBuilder(
                  builder: (context, constraints) {
                    // На очень широком экране показываем две формы просмотра:
                    // календарную сетку и линейный список справа. Это удобно
                    // именно для Windows-приложения, где много места по ширине.
                    final showList = constraints.maxWidth >= 1180;

                    if (!showList) {
                      return ScheduleWeekGrid(
                        week: controller.week,
                        lessonsForDay: controller.lessonsForDay,
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ScheduleWeekGrid(
                            week: controller.week,
                            lessonsForDay: controller.lessonsForDay,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 380,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.lessons.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return LessonCard(
                                lesson: controller.lessons[index],
                                compact: false,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
            },
          ),
        ],
      ),
    );
  }
}

/// Верхняя информационная панель расписания.
///
/// Она не загружает данные сама, а только отображает уже вычисленные значения:
/// выбранный объект, диапазон недели, количество пар и количество учебных дней.
class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.target,
    required this.weekTitle,
    required this.totalLessons,
    required this.occupiedDays,
  });

  final ScheduleTarget target;
  final String weekTitle;
  final int totalLessons;
  final int occupiedDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE1E5DE)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              target.kind == TargetKind.group ? Icons.groups : Icons.school,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.kind.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                ),
                Text(
                  target.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (target.subtitle.isNotEmpty)
                  Text(
                    target.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _Metric(label: 'Неделя', value: weekTitle),
          const SizedBox(width: 12),
          _Metric(label: 'Пар', value: '$totalLessons'),
          const SizedBox(width: 12),
          _Metric(label: 'Учебных дней', value: '$occupiedDays'),
        ],
      ),
    );
  }
}

/// Небольшой блок метрики в шапке расписания.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
