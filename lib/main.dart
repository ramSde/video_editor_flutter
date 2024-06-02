import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
      ],
      child: MaterialApp(
        title: 'Video Editor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: EditorScreen(),
      ),
    );
  }
}


class VideoProvider with ChangeNotifier {
  List<String> _selectedVideos = [];
  String _selectedAudio = '';
  double _playbackSpeed = 1.0;

  List<String> get selectedVideos => _selectedVideos;
  String get selectedAudio => _selectedAudio;
  double get playbackSpeed => _playbackSpeed;

  Future<void> requestPermission(BuildContext context) async {
    var status = await Permission.storage.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (await Permission.storage.request().isGranted) {
        // Permission granted
        return;
      } else if (status.isPermanentlyDenied) {
        // Open app settings so the user can enable the permission manually
        _showPermissionDialog(context);
      }
    } else if (status.isRestricted) {
      // Handle restricted permission case if needed
      _showPermissionDialog(context);
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Permission Required'),
        content: Text('This app needs storage access to select videos and audio. Please grant storage permission in the app settings.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void selectVideos(BuildContext context) async {
    await requestPermission(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result != null) {
      _selectedVideos = result.paths.whereType<String>().toList();
      notifyListeners();
    }
  }

  void selectAudio(BuildContext context) async {
    await requestPermission(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      _selectedAudio = result.files.single.path!;
      notifyListeners();
    }
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  Future<void> mergeVideos() async {
    if (_selectedVideos.isEmpty) return;

    String inputs = _selectedVideos.map((path) => "-i $path").join(" ");
    String filterComplex = _selectedVideos
        .asMap()
        .entries
        .map((entry) => "[${entry.key}:v:0] [${entry.key}:a:0]")
        .join(" ");
    String outputFile = "/storage/emulated/0/Download/output.mp4";

    String ffmpegCommand =
        "$inputs -filter_complex \"$filterComplex concat=n=${_selectedVideos.length}:v=1:a=1 [v] [a]\" -map \"[v]\" -map \"[a]\" $outputFile";

    await FFmpegKit.execute(ffmpegCommand);
  }

  Future<void> changeAudio() async {
    if (_selectedVideos.isEmpty || _selectedAudio.isEmpty) return;

    String video = _selectedVideos.first;
    String outputFile = "/storage/emulated/0/Download/output_with_audio.mp4";

    String ffmpegCommand =
        "-i $video -i $_selectedAudio -c:v copy -map 0:v:0 -map 1:a:0 $outputFile";

    await FFmpegKit.execute(ffmpegCommand);
  }

  Future<void> changeSpeed() async {
    if (_selectedVideos.isEmpty) return;

    String video = _selectedVideos.first;
    String outputFile = "/storage/emulated/0/Download/output_speed.mp4";

    String ffmpegCommand =
        "-i $video -filter:v \"setpts=${1 / _playbackSpeed}*PTS\" $outputFile";

    await FFmpegKit.execute(ffmpegCommand);
  }
}



class EditorScreen extends StatefulWidget {
  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Editor'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => videoProvider.selectVideos(context),
            child: Text('Select Videos'),
          ),
          ElevatedButton(
            onPressed: () => videoProvider.selectAudio(context),
            child: Text('Select Audio'),
          ),
          ElevatedButton(
            onPressed: () => videoProvider.mergeVideos(),
            child: Text('Merge Videos'),
          ),
          ElevatedButton(
            onPressed: () => videoProvider.changeAudio(),
            child: Text('Change Audio'),
          ),
          ElevatedButton(
            onPressed: () => videoProvider.changeSpeed(),
            child: Text('Change Speed'),
          ),
          Slider(
            value: videoProvider.playbackSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 3,
            label: '${videoProvider.playbackSpeed}x',
            onChanged: (value) {
              videoProvider.setPlaybackSpeed(value);
            },
          ),
          Expanded(
            child: videoProvider.selectedVideos.isNotEmpty
                ? FutureBuilder(
                    future: _initializeVideoPlayer(videoProvider.selectedVideos.first),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Chewie(
                          controller: _chewieController!,
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  )
                : Center(child: Text('No video selected')),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeVideoPlayer(String videoPath) async {
    _videoPlayerController = VideoPlayerController.file(File(videoPath));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}