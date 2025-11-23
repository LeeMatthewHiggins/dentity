import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
