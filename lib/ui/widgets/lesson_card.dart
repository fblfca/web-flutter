import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_lesson.dart';

/// Карточка одного занятия.
///
/// Используется в двух местах: внутри колонок недельного календаря и в правом
/// списке на широком экране. Флаг `compact` управляет плотностью карточки:
/// компактная версия экономит место в календарной колонке, расширенная
/// показывает дату и больше строк текста в списке.
class LessonCard extends StatelessWidget {
  const LessonCard({
    required this.lesson,
    this.compact = true,
    super.key,
  });

  final ScheduleLesson lesson;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEE, d MMM', 'ru_RU');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  // Время выделено отдельной плашкой, потому что это главный
                  // ориентир при чтении расписания.
                  width: compact ? 62 : 72,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.timeRange,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lesson.discipline,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.category,
              text: lesson.kindOfWork,
            ),
            _InfoLine(
              icon: Icons.meeting_room,
              text: lesson.building.isEmpty
                  ? lesson.auditorium
                  : '${lesson.auditorium}, ${lesson.building}',
            ),
            if (!compact)
              _InfoLine(
                icon: Icons.calendar_today,
                text: dateFormat.format(lesson.date),
              ),
            if (lesson.lecturer.isNotEmpty)
              _InfoLine(
                icon: Icons.school,
                text: lesson.lecturer,
              ),
            if (lesson.group.isNotEmpty)
              _InfoLine(
                icon: Icons.groups,
                text: lesson.group,
              ),
            if (lesson.note.isNotEmpty)
              _InfoLine(
                icon: Icons.notes,
                text: lesson.note,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Пустые строки не занимают место. Это важно, потому что RUZ API иногда не
    // присылает аудиторию, преподавателя или примечание.
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
