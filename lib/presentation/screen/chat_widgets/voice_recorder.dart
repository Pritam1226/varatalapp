import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(String audioUrl, double duration) onSend;

  const VoiceRecorder({required this.onSend, super.key});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final recorder = FlutterSoundRecorder();
  final stopwatch = Stopwatch();
  bool isRecording = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await recorder.openRecorder();
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

    await recorder.startRecorder(toFile: path);
    stopwatch.reset();
    stopwatch.start();

    setState(() {
      isRecording = true;
      audioPath = path;
    });
  }

  Future<void> stopRecording() async {
    final result = await recorder.stopRecorder();
    stopwatch.stop();
    final seconds = stopwatch.elapsedMilliseconds / 1000.0;

    setState(() => isRecording = false);

    if (result == null) return;

    final file = File(result);
    final ref = FirebaseStorage.instance
        .ref('voice_messages/${DateTime.now().millisecondsSinceEpoch}.aac');

    await ref.putFile(file);
    final audioUrl = await ref.getDownloadURL();

    widget.onSend(audioUrl, seconds);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isRecording ? Icons.stop : Icons.mic),
      color: isRecording ? Colors.red : Colors.black,
      onPressed: isRecording ? stopRecording : startRecording,
    );
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }
}
