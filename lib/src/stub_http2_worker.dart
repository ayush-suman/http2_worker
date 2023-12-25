import 'dart:async';

import 'package:http_worker/http_worker.dart';


class Http2Worker extends HttpWorker<int> {
  Http2Worker({this.debug = true}) : super();

  final bool debug;

  @override
  Future init({Uri? baseUrl}) async {
    throw UnimplementedError('Unidentified platform');
  }

  @override
  (Completer<Response<T>>, {Object? meta}) processRequest<T>({
    required int id,
    required RequestMethod method,
    required Uri url,
    Map<String, String>? header,
    Object? body,
    Parser<T>? parser,
    Map<String, Object?>? meta,
  }) {
    throw UnimplementedError('Unidentified platform');
  }

  @override
  Future killRequest(int id) async {
    throw UnimplementedError('Unidentified platform');
  }

  @override
  destroy() {
    throw UnimplementedError('Unidentified platform');
  }
}