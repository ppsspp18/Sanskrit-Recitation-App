import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/audio_provider.dart';

class GlobalAudioPlayerWidget extends StatefulWidget {
  const GlobalAudioPlayerWidget({Key? key}) : super(key: key);

  @override
  State<GlobalAudioPlayerWidget> createState() => _GlobalAudioPlayerWidgetState();
}

class _GlobalAudioPlayerWidgetState extends State<GlobalAudioPlayerWidget> {
  Offset offset = const Offset(20, 80);
  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<GlobalAudioProvider>(context);
    if (audio.currentSource == null) return const SizedBox.shrink();
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Draggable(
        feedback: _buildPlayer(context, audio),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            offset = details.offset;
          });
        },
        child: _buildPlayer(context, audio),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, GlobalAudioProvider audio) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(audio.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: audio.isLoading
                  ? null
                  : () {
                      audio.isPlaying ? audio.pause() : audio.play();
                    },
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: audio.position.inSeconds.toDouble(),
                    max: audio.duration.inSeconds.toDouble() > 0 ? audio.duration.inSeconds.toDouble() : 1,
                    onChanged: audio.isLoading
                        ? null
                        : (v) => audio.seek(Duration(seconds: v.toInt())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(audio.position), style: const TextStyle(fontSize: 12)),
                      Text(_formatTime(audio.duration), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            if (audio.isLoading) const CircularProgressIndicator(strokeWidth: 2),
            if (audio.error != null)
              Icon(Icons.error, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
