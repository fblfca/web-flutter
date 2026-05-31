import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/schedule_lesson.dart';
import '../models/schedule_target.dart';
import 'date_range.dart';

/// Сетевой клиент RUZ API.
///
/// Вся работа с `http`, URI и JSON находится здесь. Остальная часть приложения
/// не знает, как именно устроены URL и какие query-параметры нужны API. Это
/// намеренное разделение: если у RUZ изменится endpoint или понадобится всегда
/// ходить через прокси, правится один класс, а экраны и Provider остаются
/// прежними.
class RuzApiClient {
  /// Создает клиент с двумя возможными базовыми адресами.
  ///
  /// `directBaseUrl` используется по умолчанию и ведет прямо на официальный
  /// сервер RUZ. `proxyBaseUrl` нужен для обходного варианта из задания:
  /// локальный сервер из `tool/ruz_proxy_server.dart` принимает тот же путь
  /// `/api/...` и пересылает запрос на `ruz.fa.ru`.
  RuzApiClient({
    required http.Client httpClient,
    String directBaseUrl = 'https://ruz.fa.ru/api',
    String proxyBaseUrl = 'http://localhost:3000/api',
  })  : _httpClient = httpClient,
        _directBaseUrl = directBaseUrl,
        _proxyBaseUrl = proxyBaseUrl {
    _activeBaseUrl = directBaseUrl;
  }

  final http.Client _httpClient;
  final String _directBaseUrl;
  final String _proxyBaseUrl;

  late String _activeBaseUrl;

  /// Адрес, который сейчас используется для запросов.
  ///
  /// Его показывает окно настроек API, чтобы на защите было видно, работает
  /// приложение напрямую или через локальный прокси.
  String get activeBaseUrl => _activeBaseUrl;

  /// Переключает приложение между прямым RUZ API и локальным прокси.
  ///
  /// Метод вызывается из `ScheduleController.setProxyEnabled`, а тот, в свою
  /// очередь, вызывается переключателем в `ApiSettingsSheet`.
  void useProxy(bool enabled) {
    _activeBaseUrl = enabled ? _proxyBaseUrl : _directBaseUrl;
  }

  /// Ищет группы или преподавателей по строке пользователя.
  ///
  /// Запрос:
  /// `GET /api/search?term=<строка>&type=group|person`.
  ///
  /// Возвращаемый JSON сразу превращается в список `ScheduleTarget`, чтобы
  /// остальные слои приложения не зависели от сырой структуры ответа RUZ.
  Future<List<ScheduleTarget>> searchTargets({
    required String term,
    required TargetKind kind,
  }) async {
    final uri = _buildUri(
      '/search',
      query: {
        'term': term,
        'type': kind.apiValue,
      },
    );

    final json = await _getJsonList(uri);

    return json
        .whereType<Map<String, dynamic>>()
        .map((item) => ScheduleTarget.fromSearchJson(item, kind))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  /// Загружает расписание выбранной группы или преподавателя за неделю.
  ///
  /// Запрос для группы:
  /// `GET /api/schedule/group/<id>?start=yyyy.MM.dd&finish=yyyy.MM.dd`.
  ///
  /// Запрос для преподавателя:
  /// `GET /api/schedule/person/<id>?start=yyyy.MM.dd&finish=yyyy.MM.dd`.
  ///
  /// Метод получает `ScheduleTarget` из экрана и `DateRange` из контроллера,
  /// поэтому сам UI не собирает URL и не знает API-деталей.
  Future<List<ScheduleLesson>> loadSchedule({
    required ScheduleTarget target,
    required DateRange range,
  }) async {
    final uri = _buildUri(
      '/schedule/${target.kind.apiValue}/${target.id}',
      query: {
        'start': range.apiStart,
        'finish': range.apiFinish,
      },
    );

    final json = await _getJsonList(uri);

    final lessons = json
        .whereType<Map<String, dynamic>>()
        .map(ScheduleLesson.fromJson)
        .toList();

    lessons.sort((left, right) {
      final byDate = left.date.compareTo(right.date);
      if (byDate != 0) {
        return byDate;
      }

      return left.beginTime.compareTo(right.beginTime);
    });

    return lessons;
  }

  /// Собирает корректный `Uri` из активной базы, пути и query-параметров.
  ///
  /// Это небольшая, но важная защита от ошибок со слешами: базовый адрес может
  /// быть `https://ruz.fa.ru/api`, а путь приходит как `/search`; метод сведет
  /// это к одному нормальному URL.
  Uri _buildUri(String path, {Map<String, String>? query}) {
    final base = Uri.parse(_activeBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final fullPath = '${base.path}/$normalizedPath'.replaceAll('//', '/');

    return base.replace(
      path: fullPath,
      queryParameters: query,
    );
  }

  /// Выполняет GET-запрос и проверяет базовые условия корректного ответа.
  ///
  /// RUZ API в используемых endpoint'ах должен возвращать JSON-массив. Если
  /// пришел HTTP-код ошибки или JSON другого типа, бросается `RuzApiException`.
  /// Контроллер ловит это исключение и показывает понятное сообщение на экране.
  Future<List<dynamic>> _getJsonList(Uri uri) async {
    final response = await _httpClient.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RuzApiException(
        'RUZ API вернул код ${response.statusCode}',
        uri,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw RuzApiException('RUZ API вернул не список', uri);
    }

    return decoded;
  }
}

/// Собственное исключение сетевого слоя.
///
/// В нем хранится не только текст ошибки, но и URL запроса. Это удобно при
/// защите/отладке: можно сразу увидеть, какой endpoint не ответил.
class RuzApiException implements Exception {
  RuzApiException(this.message, this.uri);

  final String message;
  final Uri uri;

  @override
  String toString() => '$message: $uri';
}
