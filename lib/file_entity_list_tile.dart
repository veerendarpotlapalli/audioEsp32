import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileEntityListTile extends ListTile {
  FileEntityListTile({
    @required String? filePath,
    int? fileSize,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
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

              await Share.shareFiles([file]);
            },
            icon: Icon(Icons.share)
          ),
        ],
      ));

  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory!.path;
  }

}