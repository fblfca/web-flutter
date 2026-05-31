import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'models/schedule_target.dart';
import 'services/ruz_api_client.dart';
import 'state/schedule_controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/schedule_screen.dart';

/// Точка входа в приложение.
///
/// Здесь собираются зависимости верхнего уровня: HTTP-клиент, RUZ API-клиент
/// и ChangeNotifier-контроллер. Такой состав похож на маленький dependency
/// injection: экраны не создают сетевые объекты сами, а получают готовое
/// состояние через Provider. Благодаря этому UI можно менять отдельно от
/// бизнес-логики, а сетевой слой позднее заменить моками в тестах.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');

  final apiClient = RuzApiClient(httpClient: http.Client());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ScheduleController(apiClient: apiClient),
      child: const FaScheduleApp(),
    ),
  );
}

class FaScheduleApp extends StatelessWidget {
  const FaScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FA Schedule',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }
}

/// Главная карта маршрутов приложения.
///
/// `go_router` используется не только ради перехода на второй экран. В задании
/// отдельно упоминается проброс данных через виджеты, поэтому выбранный объект
/// передается двумя способами: компактные данные (`type`, `id`) идут в URL,
/// а полный `ScheduleTarget` можно передать через `extra`. Если приложение
/// открыто напрямую по маршруту без `extra`, экран восстановит минимальную
/// информацию из path/query-параметров и всё равно сможет загрузить расписание.
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: HomeScreen.routeName,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/schedule/:kind/:id',
      name: ScheduleScreen.routeName,
      builder: (context, state) {
        final kind = TargetKind.fromApiValue(state.pathParameters['kind'] ?? '');
        final id = state.pathParameters['id'] ?? '';
        final title = state.uri.queryParameters['title'];
        final extra = state.extra is ScheduleTarget
            ? state.extra as ScheduleTarget
            : ScheduleTarget(
                id: id,
                title: title ?? id,
                subtitle: 'Открыто из маршрута',
                kind: kind,
              );

        return ScheduleScreen(target: extra);
      },
    ),
  ],
);

ThemeData _buildTheme() {
  const seed = Color(0xFF006B5F);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F7F4),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE1E5DE)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
