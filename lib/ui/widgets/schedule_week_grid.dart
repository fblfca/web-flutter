import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_lesson.dart';
import '../../services/date_range.dart';
import 'lesson_card.dart';

/// Недельная календарная сетка.
///
/// Виджет получает готовый `DateRange` и функцию `lessonsForDay`. Это важно:
/// фильтрация занятий остается в контроллере состояния, а сетка отвечает только
/// за раскладку дней и карточек на экране.
class ScheduleWeekGrid extends StatelessWidget {
  const ScheduleWeekGrid({
    required this.week,
    required this.lessonsForDay,
    super.key,
  });

  final DateRange week;
  final List<ScheduleLesson> Function(DateTime day) lessonsForDay;

  @override
  Widget build(BuildContext context) {
    final days = week.days;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 860;

          if (narrow) {
            // На узких окнах семь колонок стали бы слишком тесными, поэтому
            // календарь превращается в вертикальный список дней.
            return ListView.separated(
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _DayColumn(
                  day: days[index],
                  lessons: lessonsForDay(days[index]),
                  fillHeight: false,
                );
              },
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final day in days) ...[
                Expanded(
                  child: _DayColumn(
                    day: day,
                    lessons: lessonsForDay(day),
                    fillHeight: true,
                  ),
                ),
                if (day != days.last) const SizedBox(width: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.lessons,
    required this.fillHeight,
  });

  final DateTime day;
  final List<ScheduleLesson> lessons;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('EEE', 'ru_RU');
    final dateFormat = DateFormat('d MMM', 'ru_RU');
    final isToday = _sameDate(day, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    final content = Card(
      color: isToday ? const Color(0xFFF0FAF7) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? colorScheme.primary : const Color(0xFFF0F4F0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayFormat.format(day).toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isToday ? colorScheme.onPrimary : colorScheme.primary,
                      ),
                ),
                Text(
                  dateFormat.format(day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isToday ? colorScheme.onPrimary : null,
                      ),
                ),
              ],
            ),
          ),
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Нет занятий'),
            )
          else
            Expanded(
              // В каждой колонке свой ListView: если в один день много пар,
              // прокручивается только этот день, а не вся недельная сетка.
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return LessonCard(lesson: lessons[index]);
                },
              ),
            ),
        ],
      ),
    );

    if (fillHeight) {
      return content;
    }

    return SizedBox(
      height: lessons.isEmpty ? 124 : 340,
      child: content,
    );
  }
}

/// Сравнение дат без учета часов, минут и секунд.
bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
