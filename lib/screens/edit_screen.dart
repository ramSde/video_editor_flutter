// lib/screens/edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_video_editor/screens/trimmer_view.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';


class EditScreen extends StatefulWidget {
  final File videoFile;

  EditScreen({required this.videoFile});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final Trimmer _trimmer = Trimmer();
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.videoFile);
  }

  void _addMusic(String audioPath) async {
    final videoPath = widget.videoFile.path;
    final outputPath = videoPath.replaceAll(".mp4", "_with_audio.mp4");

    final command = [
      '-i',
      videoPath,
      '-i',
      audioPath,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      outputPath
    ];

    await _flutterFFmpeg.executeWithArguments(command).then((rc) {
      print("FFmpeg process exited with rc $rc");
      if (rc == 0) {
        print("Audio added successfully");
      } else {
        print("Error in adding audio");
      }
    });
  }

  void _changeSpeed(double speed) async {
    final videoPath = widget.videoFile.path;
    final outputPath = videoPath.replaceAll(".mp4", "_speed_$speed.mp4");

    final command = [
      '-i',
      videoPath,
      '-filter_complex',
      '[0:v]setpts=${1 / speed}*PTS[v];[0:a]atempo=$speed[a]',
      '-map',
      '[v]',
      '-map',
      '[a]',
      outputPath
    ];

    await _flutterFFmpeg.executeWithArguments(command).then((rc) {
      print("FFmpeg process exited with rc $rc");
      if (rc == 0) {
        print("Speed changed successfully");
      } else {
        print("Error in changing speed");
      }
    });
  }

  void _setAspectRatio(double aspectRatio) async {
    final videoPath = widget.videoFile.path;
    final outputPath = videoPath.replaceAll(".mp4", "_aspect_$aspectRatio.mp4");

    final command = [
      '-i',
      videoPath,
      '-vf',
      'scale=w=iw:h=ih*(1/${aspectRatio})',
      outputPath
    ];

    await _flutterFFmpeg.executeWithArguments(command).then((rc) {
      print("FFmpeg process exited with rc $rc");
      if (rc == 0) {
        print("Aspect ratio changed successfully");
      } else {
        print("Error in changing aspect ratio");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Video'),
      ),
      body: TrimmerView(widget.videoFile),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _addMusic("/path/to/audio.mp3");
            },
            tooltip: 'Add Music',
            child: Icon(Icons.music_note),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _changeSpeed(1.5);
            },
            tooltip: 'Change Speed',
            child: Icon(Icons.speed),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _setAspectRatio(16 / 9);
            },
            tooltip: 'Change Aspect Ratio',
            child: Icon(Icons.aspect_ratio),
          ),
        ],
      ),
    );
  }
}
