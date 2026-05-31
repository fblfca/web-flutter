# Разработка и запуск

## Требования

- Windows 10/11;
- Flutter SDK 3.44.0 или совместимый;
- Dart SDK из состава Flutter;
- Visual Studio Community с workload `Desktop development with C++`;
- доступ к интернету для RUZ API.

Android SDK и Chrome не обязательны для сдачи Windows-приложения, но могут быть полезны для дополнительных запусков.

## Проверка окружения

```powershell
flutter doctor -v
```

Для Windows-сборки важны зеленые пункты:

- Flutter;
- Windows Version;
- Visual Studio;
- Connected device: Windows.

## Установка зависимостей

```powershell
flutter pub get
```

## Запуск Windows-приложения

```powershell
run -d windows
```

Если команда `run` не находится, можно использовать полный вариант:

```powershell
G:\Flutter_SDK\flutter\bin\flutter.bat run -d windows
```

Или из папки проекта:

```powershell
.\run.bat -d windows
```

## Сборка

Debug-сборка:

```powershell
flutter build windows --debug
```

Release-сборка:

```powershell
flutter build windows --release
```

Готовый exe после release-сборки:

```text
build/windows/x64/runner/Release/fa_schedule_windows.exe
```

## Анализ и тесты

```powershell
flutter analyze
flutter test
```

Тестовая модель находится в:

```text
test/schedule_lesson_test.dart
```

Она проверяет, что JSON занятия корректно превращается в `ScheduleLesson`.

## Прокси

Запуск:

```powershell
dart run tool/ruz_proxy_server.dart
```

После запуска в приложении:

```text
Настройки API -> Использовать localhost:3000
```

## Типичные проблемы

### `Visual Studio not installed`

Установить Visual Studio Community и workload:

```text
Desktop development with C++
```

### `Unable to generate build files`

Обычно проблема в CMake/Visual Studio или в старом build-кэше.

Можно удалить:

```powershell
Remove-Item -Recurse -Force build\windows
```

Потом снова:

```powershell
run -d windows
```

### Приложение собралось, но не запускается

Проверить, что рядом с exe есть:

```text
flutter_windows.dll
data/
```

Если их нет, удалить `build/windows` и пересобрать.

## Что коммитить в Git

Коммитить:

- `lib/`;
- `tool/`;
- `docs/`;
- `windows/`;
- `pubspec.yaml`;
- `pubspec.lock`;
- `README.md`;
- `.gitignore`;
- `analysis_options.yaml`;
- `run.bat`;
- `test/`.

Не коммитить:

- `build/`;
- `.dart_tool/`;
- `windows/flutter/ephemeral/`;
- `.idea/`;
- `.vscode/`.
