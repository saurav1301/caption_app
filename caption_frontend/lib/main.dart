import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() => runApp(const CaptionApp());

class CaptionApp extends StatelessWidget {
  const CaptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Caption App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const CaptionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CaptionScreen extends StatefulWidget {
  const CaptionScreen({super.key});

  @override
  State<CaptionScreen> createState() => _CaptionScreenState();
}

class _CaptionScreenState extends State<CaptionScreen> {
  File? videoFile;
  String scriptText = '';
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  Future<void> pickVideoFile() async {
    const typeGroup = XTypeGroup(label: 'videos', extensions: ['mp4']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        videoFile = File(file.path);
      });
    }
  }

  Future<void> uploadAndProcess() async {
    if (videoFile == null || scriptText.trim().isEmpty) return;
    setState(() => isLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final scriptFile = File('${tempDir.path}/script.txt');
      await scriptFile.writeAsString(scriptText);

      final uri = Uri.parse('http://127.0.0.1:5000/process');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('video', videoFile!.path))
        ..files.add(await http.MultipartFile.fromPath('script', scriptFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getExternalStorageDirectory();
        final outputFile = File('${dir!.path}/captioned_output.mp4');
        await outputFile.writeAsBytes(bytes);

        // Delete input files from backend after success
        await http.get(Uri.parse('http://127.0.0.1:5000/cleanup'));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Captioned video saved successfully!')),
          );
          OpenFile.open(outputFile.path);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed to process video: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error occurred: $e')),
        );
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Caption Generator')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: pickVideoFile,
                icon: const Icon(Icons.video_file),
                label: Text(videoFile == null ? 'Select Video' : 'Video Selected'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Paste Hinglish Script Here',
                ),
                onChanged: (value) => scriptText = value,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: isLoading ? null : uploadAndProcess,
                icon: const Icon(Icons.upload),
                label: const Text('Generate Captions'),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
            ],
          ),
        ),
      ),
    );
  }
}
