import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Небольшой локальный прокси для RUZ API.
///
/// В Windows-приложении Flutter CORS обычно не мешает, но этот файл оставлен
/// как запасной маршрут из задания: если сеть или окружение блокирует прямые
/// запросы к `ruz.fa.ru`, можно запустить `dart run tool/ruz_proxy_server.dart`
/// и в приложении переключить базовый адрес на `http://localhost:3000/api`.
/// Прокси принимает любой путь после `/api`, переносит query-параметры без
/// изменений и добавляет CORS-заголовки, чтобы тот же код можно было временно
/// запустить в Chrome.
Future<void> main() async {
  Future<Response> handler(Request request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok(
        '',
        headers: _corsHeaders,
      );
    }

    final path = request.url.path;
    final query = request.url.hasQuery ? '?${request.url.query}' : '';
    final target = Uri.parse('https://ruz.fa.ru/$path$query');

    try {
      final response = await http.get(target);
      return Response(
        response.statusCode,
        body: response.body,
        headers: {
          ..._corsHeaders,
          'content-type': response.headers['content-type'] ?? 'application/json',
        },
      );
    } catch (error) {
      return Response.internalServerError(
        body: '{"error":"Proxy request failed: $error"}',
        headers: _corsHeaders,
      );
    }
  }

  final server = await io.serve(handler, 'localhost', 3000);
  // ignore: avoid_print
  print('RUZ proxy is running on http://${server.address.host}:${server.port}');
}

const _corsHeaders = <String, String>{
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};
