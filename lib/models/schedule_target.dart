enum TargetKind {
  group,
  person;

  /// Значение, которое ожидает RUZ API в query-параметре `type` и в URL.
  String get apiValue => switch (this) {
        TargetKind.group => 'group',
        TargetKind.person => 'person',
      };

  /// Человекочитаемая подпись для интерфейса.
  String get label => switch (this) {
        TargetKind.group => 'Группа',
        TargetKind.person => 'Преподаватель',
      };

  /// Переводит строку из API или URL обратно в enum.
  ///
  /// RUZ иногда обозначает преподавателей как `person`, а иногда как
  /// `lecturer`, поэтому оба варианта сводятся к `TargetKind.person`.
  static TargetKind fromApiValue(String? value) {
    return value == 'person' || value == 'lecturer'
        ? TargetKind.person
        : TargetKind.group;
  }
}

/// Модель элемента, который пользователь выбирает перед просмотром расписания.
///
/// RUZ API возвращает результаты поиска в достаточно свободном JSON-формате:
/// у групп и преподавателей могут отличаться `type`, описание и даже тип `id`.
/// Модель нормализует эти поля один раз на границе приложения, чтобы UI и
/// контроллер дальше работали с понятными Dart-свойствами, а не с `Map`.
class ScheduleTarget {
  const ScheduleTarget({
    required this.id,
    required this.title,
    required this.kind,
    this.subtitle = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final TargetKind kind;

  /// Создает объект выбора из сырого результата `/api/search`.
  ///
  /// Для защиты важно понимать: после этой точки приложение больше не работает
  /// с `Map<String, dynamic>` результата поиска. UI получает нормальную модель
  /// с понятными полями `id`, `title`, `subtitle`, `kind`.
  factory ScheduleTarget.fromSearchJson(
    Map<String, dynamic> json,
    TargetKind requestedKind,
  ) {
    final rawType = json['type']?.toString();

    return ScheduleTarget(
      id: json['id']?.toString() ?? '',
      title: json['label']?.toString() ??
          json['title']?.toString() ??
          json['name']?.toString() ??
          'Без названия',
      subtitle: json['description']?.toString() ?? '',
      kind: rawType == null ? requestedKind : TargetKind.fromApiValue(rawType),
    );
  }

  /// Готовит параметры для `go_router`.
  ///
  /// Благодаря этому `HomeScreen` не собирает строки маршрута вручную, а берет
  /// уже согласованные значения из модели.
  Map<String, String> toRouteParameters() {
    return {
      'kind': kind.apiValue,
      'id': id,
    };
  }
}
