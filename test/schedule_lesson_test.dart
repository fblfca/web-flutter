import 'package:fa_schedule_windows/models/schedule_lesson.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('ru_RU');

  test('ScheduleLesson normalizes core RUZ fields', () {
    final lesson = ScheduleLesson.fromJson({
      'lessonOid': 123,
      'date': '2026.05.31',
      'beginLesson': '10:10',
      'endLesson': '11:40',
      'discipline': 'Кроссплатформенная разработка',
      'kindOfWork': 'Практические занятия',
      'auditorium': 'В4/ауд.3212',
      'building': '4-й Вешняковский проезд, 4',
      'lecturer_title': 'Андропов Владимир Викторович',
      'group': 'ПИ21-5',
    });

    expect(lesson.id, '123');
    expect(lesson.timeRange, '10:10-11:40');
    expect(lesson.date.year, 2026);
    expect(lesson.discipline, contains('Кроссплатформенная'));
  });
}
