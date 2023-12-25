library http2_worker;

export 'package:http2_worker/src/stub_http2_worker.dart'
  if (dart.library.io) 'package:http2_worker/src/io_http2_worker.dart'
  if (dart.library.html) 'package:http2_worker/src/web_http2_worker.dart';

