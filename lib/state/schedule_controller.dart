import 'package:flutter/foundation.dart';

import '../models/schedule_lesson.dart';
import '../models/schedule_target.dart';
import '../services/date_range.dart';
import '../services/ruz_api_client.dart';

enum LoadStatus {
  /// Действие еще не запускалось.
  idle,

  /// Запрос сейчас выполняется; UI показывает индикатор загрузки.
  loading,

  /// Запрос завершился успешно.
  loaded,

  /// Запрос завершился ошибкой; текст лежит в `errorMessage`.
  error,
}

/// Центральное состояние приложения.
///
/// Контроллер связывает UI и сетевой клиент: принимает поисковую строку,
/// хранит выбранный тип поиска, переключает неделю, загружает расписание и
/// сообщает виджетам о любом изменении через `notifyListeners()`. Такой слой
/// нужен, чтобы экраны оставались декларативными: они просто читают готовые
/// поля (`lessons`, `searchResults`, `scheduleStatus`) и вызывают методы вроде
/// `search()` или `loadScheduleFor()`, не занимаясь HTTP-запросами напрямую.
class ScheduleController extends ChangeNotifier {
  ScheduleController({
    required RuzApiClient apiClient,
  }) : _apiClient = apiClient;

  final RuzApiClient _apiClient;

  TargetKind searchKind = TargetKind.group;
  List<ScheduleTarget> searchResults = [];
  List<ScheduleLesson> lessons = [];
  ScheduleTarget? selectedTarget;
  DateRange week = DateRange.currentWeek();
  LoadStatus searchStatus = LoadStatus.idle;
  LoadStatus scheduleStatus = LoadStatus.idle;
  String errorMessage = '';
  bool proxyEnabled = false;

  String get activeBaseUrl => _apiClient.activeBaseUrl;

  /// Общее количество пар на выбранной неделе.
  ///
  /// Используется в шапке календаря как короткая метрика.
  int get totalLessons => lessons.length;

  /// Сколько разных дней недели содержат хотя бы одну пару.
  ///
  /// Это не отдельный запрос к API, а вычисление по уже загруженному списку
  /// `lessons`. Метрика помогает быстро понять плотность недели.
  int get occupiedDays {
    return lessons.map((lesson) => lesson.date.weekday).toSet().length;
  }

  /// Меняет режим поиска: группы или преподаватели.
  ///
  /// При переключении старые результаты очищаются, потому что список групп и
  /// список преподавателей приходят из одного endpoint'а, но с разным `type`.
  void changeSearchKind(TargetKind kind) {
    if (searchKind == kind) {
      return;
    }

    searchKind = kind;
    searchResults = [];
    errorMessage = '';
    searchStatus = LoadStatus.idle;
    notifyListeners();
  }

  /// Включает или выключает локальный прокси.
  ///
  /// UI хранит только булев флаг, а реальная смена адреса делегируется
  /// `RuzApiClient`, потому что только сетевой слой должен знать URL.
  void setProxyEnabled(bool enabled) {
    proxyEnabled = enabled;
    _apiClient.useProxy(enabled);
    notifyListeners();
  }

  /// Выполняет поиск по введенной строке.
  ///
  /// Метод вызывается из `TargetSearchPanel`: либо после debounce-паузы при
  /// вводе, либо сразу при нажатии Enter. Запросы короче двух символов не
  /// отправляются, чтобы не нагружать API и не получать слишком общий список.
  Future<void> search(String term) async {
    final normalized = term.trim();
    if (normalized.length < 2) {
      searchResults = [];
      searchStatus = LoadStatus.idle;
      errorMessage = '';
      notifyListeners();
      return;
    }

    searchStatus = LoadStatus.loading;
    errorMessage = '';
    notifyListeners();

    try {
      searchResults = await _apiClient.searchTargets(
        term: normalized,
        kind: searchKind,
      );
      searchStatus = LoadStatus.loaded;
    } catch (error) {
      searchResults = [];
      searchStatus = LoadStatus.error;
      errorMessage = 'Не удалось выполнить поиск: $error';
    }

    notifyListeners();
  }

  /// Загружает расписание для выбранного результата поиска.
  ///
  /// Этот метод вызывается при открытии `ScheduleScreen`. Он запоминает
  /// `selectedTarget`, чтобы кнопки "обновить", "следующая неделя" и
  /// "предыдущая неделя" могли повторить запрос для того же объекта.
  Future<void> loadScheduleFor(ScheduleTarget target) async {
    selectedTarget = target;
    scheduleStatus = LoadStatus.loading;
    errorMessage = '';
    notifyListeners();

    try {
      lessons = await _apiClient.loadSchedule(
        target: target,
        range: week,
      );
      scheduleStatus = LoadStatus.loaded;
    } catch (error) {
      lessons = [];
      scheduleStatus = LoadStatus.error;
      errorMessage = 'Не удалось загрузить расписание: $error';
    }

    notifyListeners();
  }

  /// Повторяет загрузку расписания для текущего выбранного объекта.
  ///
  /// Если пользователь еще никого не выбрал, метод ничего не делает. Поэтому
  /// его безопасно вызывать из кнопки обновления и после переключения недели.
  Future<void> reloadSelectedSchedule() async {
    final target = selectedTarget;
    if (target == null) {
      return;
    }

    await loadScheduleFor(target);
  }

  /// Сдвигает диапазон на неделю вперед и перезагружает расписание.
  Future<void> showNextWeek() async {
    week = week.nextWeek();
    notifyListeners();
    await reloadSelectedSchedule();
  }

  /// Сдвигает диапазон на неделю назад и перезагружает расписание.
  Future<void> showPreviousWeek() async {
    week = week.previousWeek();
    notifyListeners();
    await reloadSelectedSchedule();
  }

  /// Возвращает диапазон к текущей календарной неделе и перезагружает данные.
  Future<void> showCurrentWeek() async {
    week = DateRange.currentWeek();
    notifyListeners();
    await reloadSelectedSchedule();
  }

  /// Отдает пары только за конкретный день.
  ///
  /// Используется недельной сеткой: каждая колонка календаря вызывает этот
  /// метод для своего дня и получает уже отфильтрованный список занятий.
  List<ScheduleLesson> lessonsForDay(DateTime day) {
    return lessons.where((lesson) => lesson.occursOn(day)).toList();
  }
}
