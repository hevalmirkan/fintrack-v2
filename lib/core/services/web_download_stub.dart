/// Stub for non-web platforms
/// This file is used on mobile/desktop platforms

void downloadFileWeb(String fileName, String content, String mimeType) {
  // No-op on non-web platforms
  throw UnsupportedError('downloadFileWeb is only available on web');
}
