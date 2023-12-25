import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http2/http2.dart';
import 'package:http2_worker/src/utils.dart';
import 'package:http_worker/http_worker.dart';

class Http2Worker extends HttpWorker<int> {
  late final ClientTransportConnection? _connection;

  @override
  Future init({Uri? baseUrl}) async {
    if (baseUrl == null) return;

    Socket socket = (baseUrl.isScheme('https'))
        ? await SecureSocket.connect(
      baseUrl.host,
      baseUrl.port,
      supportedProtocols: ['h2'],
    ) : await Socket.connect(
        baseUrl.host,
        baseUrl.port
    );

    _connection = ClientTransportConnection.viaSocket(socket);
  }

  @override
  (Completer<Response<T>>, {Object? meta}) processRequest<T>({
    required int id,
    required RequestMethod method,
    required Uri url,
    Map<String, String>? header,
    Object? body,
    Parser<T>? parser,
    Map<String, Object?>? meta}) {
    Completer<Response<T>> completer = Completer<Response<T>>();

    final ClientTransportStream stream = _connection!.makeRequest([
        Header.ascii(':method', method.toString().split('.').last.toUpperCase()),
        Header.ascii(':scheme', url.scheme),
        Header.ascii(':authority', url.host),
        Header.ascii(':path', url.path),
        Header.ascii('user-agent', 'dart-http2'),
        Header.ascii('accept-encoding', 'gzip, deflate, br'),
        Header.ascii('accept', '*/*'),
        Header.ascii('connection', 'keep-alive'),
        Header.ascii('host', url.host),
        Header.ascii('content-type', header?['content-type'] ?? 'text/plain'),
      ],
      endStream: true,
    );

    final Completer responseCompleter = Completer();
    final ByteConversionSink sink = ByteConversionSink.withCallback((bytes) {
      responseCompleter.complete(bytes);
    });
    String? charset;
    stream.incomingMessages.listen((message) {
      if (message is HeadersStreamMessage) {
        for (Header header in message.headers) {
          if (utf8.decode(header.name).toLowerCase() == 'content-type') {
            List<String> values = utf8.decode(header.value).toLowerCase().split(
                ';');
            for (String value in values) {
              if (value.contains('charset')) {
                charset = value.split('=')[1];
              }
            }
          }
        }
      } else if (message is DataStreamMessage) {
        sink.add(message.bytes);
      }
    }, onError: responseCompleter.completeError, onDone: sink.close);
    Encoding encoding = encodingForCharset(charset);
    responseCompleter.future.then((bytes) {
      try {
        final String responseBody = encoding.decode(bytes);
        final parsedBody = parser?.parse(responseBody);
        completer.complete(Response<T>(status: 0, data: parsedBody ?? responseBody as T));
      } catch (e) {
        completer.complete(Response<T>(status: -1, error: e));
      }
    }).onError((error, stackTrace) { completer.completeError(error!); });

    return (completer, meta: null);
  }

  @override
  Future killRequest(int id) async {
    // TODO: implement killRequest
  }

  @override
  destroy() {
    _connection?.finish();
  }
}
