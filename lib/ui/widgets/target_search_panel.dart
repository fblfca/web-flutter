import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_target.dart';
import '../../state/schedule_controller.dart';

/// Панель поиска групп и преподавателей.
///
/// Виджет содержит поле ввода, переключатель типа поиска и список результатов.
/// Он не выполняет HTTP-запросы напрямую: вместо этого вызывает методы
/// `ScheduleController`, а результаты получает обратно через `context.watch`.
class TargetSearchPanel extends StatefulWidget {
  const TargetSearchPanel({
    required this.onTargetSelected,
    super.key,
  });

  final ValueChanged<ScheduleTarget> onTargetSelected;

  @override
  State<TargetSearchPanel> createState() => _TargetSearchPanelState();
}

class _TargetSearchPanelState extends State<TargetSearchPanel> {
  final _textController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    // Таймер обязательно отменяется, чтобы после закрытия экрана он не попытался
    // обратиться к уже удаленному BuildContext.
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  /// Запускает поиск с небольшой задержкой после ввода.
  ///
  /// Без debounce приложение отправляло бы запрос на каждый символ. Для RUZ API
  /// это лишняя нагрузка, а для пользователя - прыгающий список результатов.
  /// Таймер сбрасывается при каждом новом вводе и вызывает Provider-контроллер
  /// только тогда, когда пользователь на мгновение остановился.
  void _queueSearch(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      context.read<ScheduleController>().search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          color: colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Поиск расписания',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<TargetKind>(
                // `TargetKind` - общий enum для UI, маршрутов и API-клиента.
                // Поэтому переключатель сразу работает с доменной моделью,
                // а не со строками `group` / `person`.
                segments: const [
                  ButtonSegment(
                    value: TargetKind.group,
                    label: Text('Группы'),
                    icon: Icon(Icons.groups),
                  ),
                  ButtonSegment(
                    value: TargetKind.person,
                    label: Text('Преподаватели'),
                    icon: Icon(Icons.school),
                  ),
                ],
                selected: {controller.searchKind},
                onSelectionChanged: (selection) {
                  controller.changeSearchKind(selection.first);
                  _queueSearch(_textController.text);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _textController,
                onChanged: (value) {
                  setState(() {});
                  _queueSearch(value);
                },
                onSubmitted: controller.search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _textController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистить',
                          onPressed: () {
                            _textController.clear();
                            controller.search('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  hintText: controller.searchKind == TargetKind.group
                      ? 'Например: ПИ21'
                      : 'Например: Андропов',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (controller.searchStatus) {
            // Статусы приходят из Provider-контроллера. Виджет только решает,
            // как визуально показать каждое состояние.
            LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
            LoadStatus.error => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  controller.errorMessage,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            LoadStatus.loaded when controller.searchResults.isEmpty => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Ничего не найдено'),
                ),
              ),
            _ when controller.searchResults.isEmpty => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Введите минимум два символа'),
                ),
              ),
            _ => ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: controller.searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final target = controller.searchResults[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          target.kind == TargetKind.group
                              ? Icons.groups
                              : Icons.school,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(target.title),
                      subtitle: target.subtitle.isEmpty
                          ? Text(target.kind.label)
                          : Text(target.subtitle),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => widget.onTargetSelected(target),
                    ),
                  );
                },
              ),
          },
        ),
      ],
    );
  }
}
