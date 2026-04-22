import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class FileViewerDialog extends StatefulWidget {
  final String fileUrl;

  const FileViewerDialog({super.key, required this.fileUrl});

  @override
  State<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<FileViewerDialog> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    if (widget.fileUrl.endsWith('.mp4')) {
      _videoController = VideoPlayerController.network(widget.fileUrl)
        ..initialize().then((_) => setState(() {}));
    } else if (widget.fileUrl.endsWith('.mp3')) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setUrl(widget.fileUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.fileUrl;

    return Dialog(
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            AppBar(title: const Text("File Viewer")),
            Expanded(child: _buildContent(url)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String url) {
    if (url.endsWith('.jpg') || url.endsWith('.png')) {
      return Image.network(url);
    }

    if (url.endsWith('.mp4') && _videoController != null && _videoController!.value.isInitialized) {
      return Column(
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          ElevatedButton(
            onPressed: () => _videoController!.play(),
            child: const Text("Play"),
          ),
        ],
      );
    }

    if (url.endsWith('.mp3')) {
      return Center(
        child: ElevatedButton(
          onPressed: () => _audioPlayer?.play(),
          child: const Text("Play Audio"),
        ),
      );
    }

    return Center(
      child: ElevatedButton(
        onPressed: () async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
},
        child: const Text("Open File"),
      ),
    );
  }
}