# RUZ API

Документ описывает, как приложение работает с API `ruz.fa.ru`.

## Базовые адреса

Прямой режим:

```text
https://ruz.fa.ru/api
```

Прокси-режим:

```text
http://localhost:3000/api
```

Переключение выполняется в приложении через настройки API. Код переключения находится в:

- `lib/ui/widgets/api_settings_sheet.dart`;
- `lib/state/schedule_controller.dart`;
- `lib/services/ruz_api_client.dart`.

## Поиск групп и преподавателей

Endpoint:

```http
GET /api/search?term=<query>&type=<group|person>
```

Пример поиска группы:

```text
https://ruz.fa.ru/api/search?term=ПИ21&type=group
```

Пример поиска преподавателя:

```text
https://ruz.fa.ru/api/search?term=Андропов&type=person
```

Типичный ответ:

```json
[
  {
    "id": "137271",
    "label": "ПИ21-5",
    "description": "Факультет информационных технологий...",
    "type": "group"
  }
]
```

Как обрабатывается:

1. `RuzApiClient.searchTargets()` отправляет запрос.
2. `_getJsonList()` проверяет HTTP-код и тип JSON.
3. Каждый элемент превращается в `ScheduleTarget.fromSearchJson()`.
4. UI получает не JSON, а список `ScheduleTarget`.

## Загрузка расписания группы

Endpoint:

```http
GET /api/schedule/group/<groupId>?start=yyyy.MM.dd&finish=yyyy.MM.dd
```

Пример:

```text
https://ruz.fa.ru/api/schedule/group/137271?start=2026.05.25&finish=2026.05.31
```

## Загрузка расписания преподавателя

Endpoint:

```http
GET /api/schedule/person/<personId>?start=yyyy.MM.dd&finish=yyyy.MM.dd
```

Пример:

```text
https://ruz.fa.ru/api/schedule/person/38635?start=2026.05.25&finish=2026.05.31
```

## Формат даты

RUZ API ожидает даты в формате:

```text
yyyy.MM.dd
```

За формат отвечает `DateRange`:

```dart
String get apiStart => _apiFormat.format(start);
String get apiFinish => _apiFormat.format(finish);
```

Файл:

```text
lib/services/date_range.dart
```

## Типичный объект занятия

RUZ возвращает большой JSON. Приложение использует только нужные поля:

```json
{
  "lessonOid": 1324753,
  "date": "2026.05.31",
  "beginLesson": "14:00",
  "endLesson": "15:30",
  "discipline": "Кроссплатформенная разработка",
  "kindOfWork": "Практические занятия",
  "auditorium": "В4/ауд.3212",
  "building": "4-й Вешняковский проезд, 4",
  "lecturer_title": "Андропов Владимир Викторович",
  "group": "ПИ21-5"
}
```

Преобразование выполняется в:

```text
lib/models/schedule_lesson.dart
```

## Почему JSON не используется прямо в UI

Сырой JSON неудобен и небезопасен:

- поля могут быть `null`;
- некоторые поля могут отсутствовать;
- у группы и преподавателя немного разная структура;
- UI становится сложнее читать.

Поэтому API-ответ сразу переводится в модели:

- `ScheduleTarget` для результата поиска;
- `ScheduleLesson` для занятия.

## Обработка ошибок

Если API вернул ошибочный HTTP-код или не список JSON, `RuzApiClient` бросает `RuzApiException`.

Контроллер ловит ошибку:

```dart
catch (error) {
  lessons = [];
  scheduleStatus = LoadStatus.error;
  errorMessage = 'Не удалось загрузить расписание: $error';
}
```

UI показывает понятное сообщение через `EmptyState`.

## Локальный прокси

Файл:

```text
tool/ruz_proxy_server.dart
```

Запуск:

```powershell
dart run tool/ruz_proxy_server.dart
```

Прокси принимает запрос:

```text
http://localhost:3000/api/search?term=ПИ21&type=group
```

и пересылает его на:

```text
https://ruz.fa.ru/api/search?term=ПИ21&type=group
```

Это нужно для случаев, когда прямой доступ к RUZ нестабилен или приложение временно запускается в Chrome.
