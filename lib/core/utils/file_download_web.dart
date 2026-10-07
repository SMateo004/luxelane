// Web-only implementation — loaded via conditional import.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

/// Saves [content] as a file through the browser. Returns true on success.
bool downloadTextFile(String filename, String content,
    {String mimeType = 'text/csv'}) {
  // BOM so Excel opens accented names (é, ñ, ç) as UTF-8.
  final bytes = utf8.encode('﻿$content');
  final blob = html.Blob([bytes], '$mimeType;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
