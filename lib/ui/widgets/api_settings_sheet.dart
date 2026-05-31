import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/schedule_controller.dart';

/// Открывает нижнюю панель настроек API.
///
/// Функция вынесена отдельно, чтобы `HomeScreen` и `ScheduleScreen` могли
/// открывать один и тот же UI настроек, не дублируя код `showModalBottomSheet`.
Future<void> showApiSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ApiSettingsSheet(),
  );
}

/// Содержимое панели настроек API.
///
/// Сейчас настройка одна: прямой RUZ API или локальный прокси. Она связана с
/// `ScheduleController.proxyEnabled`, а контроллер уже переключает базовый URL
/// внутри `RuzApiClient`.
class _ApiSettingsSheet extends StatelessWidget {
  const _ApiSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ScheduleController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Источник данных',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            controller.activeBaseUrl,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Использовать localhost:3000'),
            subtitle: const Text(
              'Включайте, если запущен dart run tool/ruz_proxy_server.dart',
            ),
            value: controller.proxyEnabled,
            onChanged: controller.setProxyEnabled,
          ),
        ],
      ),
    );
  }
}
