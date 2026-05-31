import 'package:intl/intl.dart';

/// Недельный диапазон, который используется и для запроса к API, и для
/// построения календаря. В RUZ даты передаются строками `yyyy.MM.dd`, поэтому
/// форматирование держится здесь, а не размазывается по экранам и контроллеру.
class DateRange {
  DateRange({
    required this.start,
    required this.finish,
  });

  final DateTime start;
  final DateTime finish;

  /// Все семь дат недели, начиная с понедельника.
  ///
  /// `ScheduleWeekGrid` использует этот список, чтобы построить семь колонок
  /// календаря. Диапазон хранится как начало/конец, а список дней вычисляется
  /// по требованию, чтобы не держать дублирующее состояние.
  List<DateTime> get days {
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  /// Создает новый диапазон на неделю позже.
  ///
  /// Старый объект не изменяется. Такой immutable-подход снижает риск ошибок:
  /// контроллер просто заменяет `week` на новый `DateRange`.
  DateRange nextWeek() {
    return DateRange(
      start: start.add(const Duration(days: 7)),
      finish: finish.add(const Duration(days: 7)),
    );
  }

  /// Создает новый диапазон на неделю раньше.
  DateRange previousWeek() {
    return DateRange(
      start: start.subtract(const Duration(days: 7)),
      finish: finish.subtract(const Duration(days: 7)),
    );
  }

  /// Начало диапазона в формате, который ожидает RUZ API.
  String get apiStart => _apiFormat.format(start);

  /// Конец диапазона в формате, который ожидает RUZ API.
  String get apiFinish => _apiFormat.format(finish);

  /// Возвращает текущую календарную неделю с понедельника по воскресенье.
  ///
  /// Это стартовая неделя при первом открытии приложения и цель кнопки
  /// "Сегодня" на экране расписания.
  static DateRange currentWeek() {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));

    return DateRange(
      start: monday,
      finish: monday.add(const Duration(days: 6)),
    );
  }
}

final _apiFormat = DateFormat('yyyy.MM.dd');
