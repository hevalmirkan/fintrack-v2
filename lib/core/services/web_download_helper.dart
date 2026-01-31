/// Web download helper - Uses dart:html for browser downloads
/// This file is ONLY imported on web platform

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

/// Download a file in the browser
void downloadFileWeb(String fileName, String content, String mimeType) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Cleanup
  html.Url.revokeObjectUrl(url);
  print('[WEB] Download initiated: $fileName');
}
