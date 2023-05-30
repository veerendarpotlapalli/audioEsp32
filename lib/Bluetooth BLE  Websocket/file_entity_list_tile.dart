
// This class will specify the audio File Properties which we are storing/saving in the app

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FileEntityListTile extends ListTile {
  FileEntityListTile({
    @required String? filePath, // the path of the file [in phone storage]
    int? fileSize, // Size of the file [size of Streaming audio]
    GestureTapCallback? onTap, // when we on tap the file in pebbl app [Play/Pause]
     GestureLongPressCallback? onLongPress, // when we Long press the file in pebbl app [Delete]
  }) : super(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Icon(Icons.insert_drive_file),
      title: Text(filePath!),
      subtitle: Text("$fileSize byte"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () async {

              final file = filePath;

              // final temp = file

              await Share.shareFiles([file]); // the file of the given path
            },
            icon: Icon(Icons.share) // to share the file via whatsapp,telegram etc..
          ),
        ],
      ));
}