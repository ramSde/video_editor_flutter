// // lib/screens/home_screen.dart

// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'edit_screen.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<File> _videoFiles = [];

//   _pickVideos() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.video,
//       allowMultiple: true,
//     );

//     if (result != null) {
//       setState(() {
//         _videoFiles = result.paths.map((path) => File(path!)).toList();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Editor'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: _pickVideos,
//               child: Text('Pick Videos'),
//             ),
//             if (_videoFiles.isNotEmpty)
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           VideoEditScreen(),
//                     ),
//                   );
//                 },
//                 child: Text('Edit Videos'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
