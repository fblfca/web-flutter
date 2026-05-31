import 'package:intl/intl.dart';

/// Одна пара из расписания RUZ.
///
/// API присылает большой объект: аудитория, корпус, дисциплина, преподаватели,
/// список групп, время начала и окончания. В приложении нужны только поля,
/// которые реально отображаются в календаре, поэтому модель выбирает их и
/// оставляет безопасные значения по умолчанию. Это защищает UI от `null`,
/// пустых строк и разных типов JSON-полей.
class ScheduleLesson {
  ScheduleLesson({
    required this.id,
    required this.date,
    required this.beginTime,
    required this.endTime,
    required this.discipline,
    required this.kindOfWork,
    required this.auditorium,
    required this.building,
    required this.lecturer,
    required this.group,
    required this.note,
  });

  final String id;
  final DateTime date;
  final String beginTime;
  final String endTime;
  final String discipline;
  final String kindOfWork;
  final String auditorium;
  final String building;
  final String lecturer;
  final String group;
  final String note;

  /// Создает занятие из одного элемента `/api/schedule/...`.
  ///
  /// Здесь собрана вся "адаптация" RUZ-ответа:
  /// - дата переводится из строки `yyyy.MM.dd` в `DateTime`;
  /// - `null` и пустые строки заменяются безопасными значениями;
  /// - преподаватели и группы могут браться как из плоских полей, так и из
  ///   вложенных списков `listOfLecturers` / `listGroups`.
  factory ScheduleLesson.fromJson(Map<String, dynamic> json) {
    return ScheduleLesson(
      id: json['lessonOid']?.toString() ??
          json['contentOfLoadOid']?.toString() ??
          '${json['date']}_${json['beginLesson']}_${json['discipline']}',
      date: _parseRuzDate(json['date']?.toString()),
      beginTime: json['beginLesson']?.toString() ?? '',
      endTime: json['endLesson']?.toString() ?? '',
      discipline: _clean(json['discipline']) ?? 'Без названия дисциплины',
      kindOfWork: _clean(json['kindOfWork']) ?? 'Занятие',
      auditorium: _clean(json['auditorium']) ?? 'Аудитория не указана',
      building: _clean(json['building']) ?? '',
      lecturer: _clean(json['lecturer_title']) ??
          _clean(json['lecturer']) ??
          _lecturersFromList(json['listOfLecturers']),
      group: _clean(json['group']) ?? _groupsFromList(json['listGroups']),
      note: _clean(json['note_description']) ?? _clean(json['note']) ?? '',
    );
  }

  /// Готовый текстовый диапазон времени для карточки занятия.
  ///
  /// UI не склеивает `beginTime` и `endTime` сам, поэтому формат времени легко
  /// изменить в одном месте.
  String get timeRange {
    if (beginTime.isEmpty && endTime.isEmpty) {
      return 'Время не указано';
    }

    return '$beginTime-$endTime';
  }

  /// Проверяет, относится ли занятие к указанному дню.
  ///
  /// Метод используется контроллером при раскладке занятий по колонкам
  /// недельного календаря.
  bool occursOn(DateTime day) {
    return date.year == day.year && date.month == day.month && date.day == day.day;
  }
}

/// Парсит дату RUZ.
///
/// Основной формат API - `yyyy.MM.dd`, но на всякий случай оставлен fallback
/// через `DateTime.tryParse`, чтобы приложение не падало при небольшом
/// изменении формата.
DateTime _parseRuzDate(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime.now();
  }

  try {
    return DateFormat('yyyy.MM.dd').parseStrict(value);
  } catch (_) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
}

/// Нормализует строковые поля API.
///
/// RUZ может вернуть `null`, пустую строку или даже строку `"null"`. Для UI это
/// все означает "значение отсутствует", поэтому функция возвращает настоящий
/// `null`, а вызывающий код подставляет дефолтный текст.
String? _clean(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

/// Собирает имена преподавателей из вложенного списка API.
String _lecturersFromList(Object? value) {
  if (value is! List) {
    return '';
  }

  final names = value
      .whereType<Map<String, dynamic>>()
      .map((item) => _clean(item['lecturer_title']) ?? _clean(item['lecturer']))
      .whereType<String>();

  return names.join(', ');
}

/// Собирает названия групп из вложенного списка API.
String _groupsFromList(Object? value) {
  if (value is! List) {
    return '';
  }

  final groups = value
      .whereType<Map<String, dynamic>>()
      .map((item) => _clean(item['group']))
      .whereType<String>();

  return groups.join(', ');
}
