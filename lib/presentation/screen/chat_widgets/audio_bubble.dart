import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioBubble extends StatefulWidget {
  final String audioUrl;
  final double duration;

  const AudioBubble({required this.audioUrl, required this.duration, super.key});

  @override
  State<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.audioUrl);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void togglePlay() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: togglePlay,
        ),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (_, snapshot) {
              final pos = snapshot.data?.inSeconds ?? 0;
              return Slider(
                min: 0,
                max: widget.duration,
                value: pos.toDouble().clamp(0, widget.duration),
                onChanged: (val) => _player.seek(Duration(seconds: val.toInt())),
              );
            },
          ),
        ),
      ],
    );
  }
}
