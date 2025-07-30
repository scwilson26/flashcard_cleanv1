import 'dart:async'; // ✅ THIS IS MISSING
import 'dart:html' as html;
import 'dart:typed_data';

Future<Map<String, dynamic>?> pickPdfFile() async {
  final uploadInput = html.FileUploadInputElement()..accept = '.pdf';
  uploadInput.click();

  final completer = Completer<Map<String, dynamic>?>();
  uploadInput.onChange.listen((event) {
    final file = uploadInput.files!.first;
    final reader = html.FileReader();

    reader.onLoadEnd.listen((e) {
      final data = reader.result as Uint8List;
      completer.complete({'bytes': data, 'name': file.name});
    });

    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
