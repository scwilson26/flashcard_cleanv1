// file_download_web.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';


Future<void> handleFileDownload(Uint8List data) async {
  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "study_pack.zip")
    ..click();
  html.Url.revokeObjectUrl(url);
}