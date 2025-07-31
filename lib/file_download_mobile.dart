import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> handleFileDownload(Uint8List data) async {
  print("📥 Attempting to save file...");

  // Use app's internal documents directory (no permission required)
  final directory = await getApplicationDocumentsDirectory();
  if (directory == null) {
    print("❌ Could not find directory");
    return;
  }

  final filePath = '${directory.path}/neuroforge_study_pack.zip';
  final file = File(filePath);

  try {
    await file.writeAsBytes(data);
    print("✅ File saved to: $filePath");

    // Automatically open the native share dialog
    final xfile = XFile(filePath);
    await Share.shareXFiles([xfile], text: '📚 Here’s your NeuroForge Study Pack!');
  } catch (e) {
    print("❌ Failed to save file: $e");
  }
}
