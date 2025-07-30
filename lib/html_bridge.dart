// lib/html_bridge.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

FileUploadInputElement createFileInput() => FileUploadInputElement();
FileReader createFileReader() => FileReader();
Blob createBlob(List<dynamic> data) => Blob(data);
String createObjectUrl(Blob blob) => Url.createObjectUrlFromBlob(blob);
void revokeObjectUrl(String url) => Url.revokeObjectUrl(url);
AnchorElement createAnchor(String href) => AnchorElement(href: href);
