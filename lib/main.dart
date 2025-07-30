import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async';

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
    try {
      final result = await pickPdfFile();
      if (result != null) {
        setState(() {
          fileBytes = result['bytes'];
          fileName = result['name'];
          status = "Selected: $fileName";
          showDownloadButton = false;
        });
      }
    } catch (e) {
      setState(() => status = "❌ File pick failed");
      print("File pick error: $e");
    }
  }

  Future<void> generateZip() async {
    if (fileBytes == null) return;

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

    final uri = Uri.parse('http://127.0.0.1:8000/generate-study-pack');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes!, filename: fileName));

    try {
      final streamedRequest = await request.send();
      final data = await streamedRequest.stream.toBytes();

      progressTimer.cancel();
      setState(() => uploadProgress = 1.0);

      if (streamedRequest.statusCode == 200) {
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