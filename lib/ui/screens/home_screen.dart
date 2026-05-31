import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_target.dart';
import '../../state/schedule_controller.dart';
import '../widgets/api_settings_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/target_search_panel.dart';

/// Главный экран приложения.
///
/// Его задача - дать пользователю найти объект расписания: учебную группу или
/// преподавателя. Сам экран не знает, как выполняется HTTP-запрос; он показывает
/// `TargetSearchPanel`, а тот общается с `ScheduleController` через Provider.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FA Schedule'),
        actions: [
          IconButton(
            tooltip: 'Настройки API',
            onPressed: () => showApiSettingsSheet(context),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // На широком Windows-экране поиск остается слева, а справа остается
          // свободная рабочая область. На узком экране показывается только
          // панель поиска, чтобы интерфейс не сжимался и текст не налезал.
          final wide = constraints.maxWidth >= 960;

          if (!wide) {
            return TargetSearchPanel(
              onTargetSelected: (target) => _openSchedule(context, target),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 420,
                child: TargetSearchPanel(
                  onTargetSelected: (target) => _openSchedule(context, target),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: EmptyState(
                  icon: Icons.calendar_month,
                  title: controller.searchResults.isEmpty
                      ? 'Найдите группу или преподавателя'
                      : 'Выберите результат слева',
                  message:
                      'После выбора откроется недельный календарь занятий. '
                      'Данные загружаются напрямую из RUZ API.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Открывает экран календаря для выбранной группы или преподавателя.
  ///
  /// В URL попадают `kind` и `id`, чтобы маршрут был воспроизводимым, а полный
  /// объект передается через `extra`, чтобы на следующем экране сразу были
  /// красивый заголовок и описание без повторного поиска.
  void _openSchedule(BuildContext context, ScheduleTarget target) {
    context.goNamed(
      'schedule',
      pathParameters: target.toRouteParameters(),
      queryParameters: {'title': target.title},
      extra: target,
    );
  }
}
