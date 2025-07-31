import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'file_download_stub.dart'
  if (dart.library.html) 'file_download_web.dart'
  if (dart.library.io) 'file_download_mobile.dart';

import 'file_picker_stub.dart'
  if (dart.library.html) 'file_picker_web.dart'
  if (dart.library.io) 'file_picker_mobile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroForge Flashcards',
      home: Scaffold(
        appBar: AppBar(title: const Text('NeuroForge Study Pack Generator')),
        body: const FlashcardUploader(),
      ),
    );
  }
}

class FlashcardUploader extends StatefulWidget {
  const FlashcardUploader({super.key});

  @override
  _FlashcardUploaderState createState() => _FlashcardUploaderState();
}

class _FlashcardUploaderState extends State<FlashcardUploader> {
  String status = "No file selected.";
  Uint8List? fileBytes;
  String? fileName;
  double uploadProgress = 0.0;
  bool showDownloadButton = false;

  void selectAndLoadFile() async {
    print("📥 Attempting to pick file...");
    try {
      final result = await pickPdfFile();
      if (result != null) {
        print("✅ File picked: ${result['name']}, size: ${result['bytes']?.length ?? 0} bytes");
        setState(() {
          fileBytes = result['bytes'];
          fileName = result['name'];
          status = "Selected: $fileName";
          showDownloadButton = false;
        });
      } else {
        print("⚠️ No file selected");
      }
    } catch (e) {
      setState(() => status = "❌ File pick failed");
      print("❌ File pick error: $e");
    }
  }

  Uri getBackendUri() {
    if (kIsWeb) {
      return Uri.parse('http://127.0.0.1:8000/generate-study-pack');
    } else if (Platform.isAndroid) {
      return Uri.parse('http://10.0.2.2:8000/generate-study-pack');
    } else {
      return Uri.parse('http://127.0.0.1:8000/generate-study-pack');
    }
  }

  Future<void> generateZip() async {
    print("🧠 generateZip() called");

    if (fileBytes == null) {
      print("🚫 No file loaded – skipping upload");
      return;
    }

    final uri = getBackendUri();
    print("📡 Sending request to: $uri");

    setState(() {
      status = "Uploading...";
      uploadProgress = 0.0;
    });

    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        if (uploadProgress < 0.95) {
          uploadProgress += 0.01;
        }
      });
    });

    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes!, filename: fileName));

    try {
      final streamedRequest = await request.send();
      final data = await streamedRequest.stream.toBytes();

      progressTimer.cancel();
      setState(() => uploadProgress = 1.0);

      print("📬 Response status: ${streamedRequest.statusCode}");

      if (streamedRequest.statusCode == 200) {
        print("✅ ZIP received");
        await handleFileDownload(data);

        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          status = "✅ Study pack ready!";
          uploadProgress = 0.0;
          showDownloadButton = true;
        });
      } else {
        setState(() {
          status = "❌ Failed to generate.";
          uploadProgress = 0.0;
        });
        print("❌ Server returned error status");
      }
    } catch (e) {
      progressTimer.cancel();
      setState(() {
        status = "❌ Error during upload";
        uploadProgress = 0.0;
      });
      print("❌ Upload failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(status),
          if (uploadProgress > 0.0 && uploadProgress < 1.0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: LinearProgressIndicator(value: uploadProgress),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: selectAndLoadFile,
            child: const Text('Select PDF'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: generateZip,
            child: const Text('Generate Study Pack (.zip)'),
          ),
        ],
      ),
    );
  }
}
