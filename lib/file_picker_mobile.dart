import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

Future<Map<String, dynamic>?> pickPdfFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    return {'bytes': file.bytes, 'name': file.name};
  }

  return null;
}
