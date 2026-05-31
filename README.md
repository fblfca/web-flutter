# FA Schedule Windows

Windows-приложение на Flutter для поиска групп и преподавателей Финансового университета и просмотра расписания занятий через RUZ API.

Проект сделан как самостоятельная реализация задания: код разделен на сетевой слой, модели данных, состояние приложения и UI. Референс из задания использовался только для понимания API и требований.

## Возможности

- поиск учебных групп;
- поиск преподавателей;
- открытие расписания выбранной группы или преподавателя;
- недельный календарь занятий;
- переключение недель назад/вперед;
- возврат к текущей неделе;
- обновление расписания;
- отображение времени, дисциплины, типа занятия, аудитории, корпуса, преподавателя и группы;
- переключение между прямым `https://ruz.fa.ru/api` и локальным прокси `http://localhost:3000/api`;
- запуск как Windows-приложение.

## Соответствие ТЗ

| Требование | Где реализовано |
| --- | --- |
| Приложение запускается как Windows-приложение | `windows/`, `run.bat`, команда `run -d windows` |
| Выводит список преподавателей или групп | `lib/ui/widgets/target_search_panel.dart` |
| По ссылке/выбору открывает расписание | `lib/ui/screens/home_screen.dart`, маршрут `/schedule/:kind/:id` |
| Расписание отображается как календарь | `lib/ui/widgets/schedule_week_grid.dart` |
| Формирует расписание по выбранному преподавателю | `TargetKind.person`, `RuzApiClient.loadSchedule()` |
| Данные загружаются с `ruz.fa.ru` | `lib/services/ruz_api_client.dart` |
| Есть обход через прокси | `tool/ruz_proxy_server.dart`, `ApiSettingsSheet` |
| Используется состояние между виджетами | `provider`, `lib/state/schedule_controller.dart` |
| Есть навигация между экранами | `go_router`, `lib/main.dart` |
| Есть поиск | `TargetSearchPanel` с debounce |

## Структура проекта

```text
lib/
  main.dart                         # вход в приложение, тема, маршруты
  models/
    schedule_target.dart            # группа/преподаватель из поиска
    schedule_lesson.dart            # одно занятие из расписания
  services/
    ruz_api_client.dart             # все HTTP-запросы к RUZ API
    date_range.dart                 # неделя и формат дат для API
  state/
    schedule_controller.dart        # Provider-состояние поиска и расписания
  ui/
    screens/
      home_screen.dart              # главный экран поиска
      schedule_screen.dart          # экран расписания
    widgets/
      target_search_panel.dart      # поиск и список результатов
      schedule_week_grid.dart       # недельный календарь
      lesson_card.dart              # карточка занятия
      api_settings_sheet.dart       # переключатель API/прокси
      empty_state.dart              # пустые состояния и ошибки
tool/
  ruz_proxy_server.dart             # локальный прокси на localhost:3000
docs/
  ARCHITECTURE.md                   # архитектура и поток данных
  API.md                            # структура запросов RUZ API
  DEVELOPMENT.md                    # запуск, сборка, диагностика
  DEFENSE_GUIDE.md                  # подробная шпаргалка для защиты проекта
```

## Быстрый запуск

Требования:

- Flutter SDK;
- Visual Studio с компонентом `Desktop development with C++`;
- Windows 10/11.

Команды:

```powershell
cd G:\vscode\web-flutter
flutter pub get
run -d windows
```

`run.bat` — локальная удобная команда. Она вызывает:

```powershell
G:\Flutter_SDK\flutter\bin\flutter.bat run -d windows
```

Если Flutter установлен в другое место, обновите путь внутри `run.bat`.

## Запуск через прокси

Обычно Windows-приложение может обращаться к `https://ruz.fa.ru/api` напрямую. Если сеть блокирует запросы или нужен режим из задания, запустите локальный прокси:

```powershell
dart run tool/ruz_proxy_server.dart
```

Потом в приложении откройте настройки API и включите `Использовать localhost:3000`.

## Основные команды разработки

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --debug
flutter build windows --release
```

## Документация

- [Архитектура](docs/ARCHITECTURE.md)
- [RUZ API](docs/API.md)
- [Разработка и запуск](docs/DEVELOPMENT.md)
- [Подготовка к защите](docs/DEFENSE_GUIDE.md)

## Что показать на защите

1. Запустить `run -d windows`.
2. Найти группу, например `ПИ21`.
3. Открыть расписание группы.
4. Переключить неделю вперед/назад.
5. Вернуться кнопкой `Сегодня`.
6. Переключиться на поиск преподавателей.
7. Найти преподавателя, например `Андропов`.
8. Открыть расписание преподавателя.
9. Показать настройки API и объяснить прямой режим/прокси.
10. Открыть код `RuzApiClient`, `ScheduleController`, `ScheduleLesson`.

## Ключевая идея архитектуры

UI не делает HTTP-запросы напрямую. Экран вызывает метод контроллера, контроллер вызывает API-клиент, API-клиент получает JSON и превращает его в модели. Потом контроллер уведомляет UI, и Flutter перерисовывает экран.

```text
Пользователь
  -> UI
  -> ScheduleController
  -> RuzApiClient
  -> RUZ API
  -> ScheduleTarget / ScheduleLesson
  -> ScheduleController
  -> UI
```
