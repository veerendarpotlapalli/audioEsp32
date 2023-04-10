import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:vsaudio/wav_header.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slide_popup_dialog_null_safety/slide_popup_dialog.dart' as slideDialog;
import 'file_entity_list_tile.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'detailpage.dart';
import 'detailPageSample.dart';



enum ConnectionState { connected, disconnected }


class ConnectToWifi extends StatefulWidget {

  final name = NetworkInfo();

  late String wifiName = name.getWifiName() as String;


  ConnectToWifi({super.key, required this.wifiName});

  @override
  State<ConnectToWifi> createState() => _ConnectToWifiState();
}

class _ConnectToWifiState extends State<ConnectToWifi> {
  TextEditingController password=TextEditingController();

  late WebSocket ws;



  BluetoothConnection? connection;

  bool get isConnected => connection != null && connection!.isConnected;

  bool isDisconnecting = false;
  bool isConnecting = true;

  List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  Uint8List? _bytes;
  // PlayerController controller = PlayerController();// Initialise

  RestartableTimer? _timer;

  final DetailPageSample detailPageSample = new DetailPageSample();

  ConnectionState _connectionState = ConnectionState.connected  ;

  RecordState _recordState = RecordState.stopped;

  DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH_mm_ss");
  Uint8List? dataStream;

  List<FileSystemEntity> files = <FileSystemEntity>[];
  String? selectedFilePath;
  final player = FlutterSoundPlayer(voiceProcessing: true);
  final streamPlayer = FlutterSoundPlayer();

  final info=NetworkInfo();


  @override
  void initState() {
    createChannel();
    // _getBTConnection();
    player.openPlayer();
    streamPlayer.openPlayer(enableVoiceProcessing: true);
    _timer = RestartableTimer(const Duration(seconds: 1), _completeByte);
    _listofFiles();
    selectedFilePath = '';
    initStreamPlayer();

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;

    }
    _timer!.cancel();
    super.dispose();
  }


  // _getBTConnection() {
  //   BluetoothConnection.toAddress(widget.server!.address).then((_connection) {
  //     setState(() {
  //       connection = _connection;
  //     });
  //     isConnecting = false;
  //     isDisconnecting = false;
  //     setState(() {});
  //     _connection.input!.listen(_onDataReceived).onDone(() {
  //       if (isDisconnecting) {
  //         print('Disconnecting locally');
  //       } else {
  //         print('Disconnecting remotely');
  //       }
  //       if (this.mounted) {
  //         setState(() {});
  //       }
  //       Navigator.of(context).pop();
  //     });
  //   }).catchError((error) {
  //     Navigator.of(context).pop();
  //   });
  // }



  // void _sendMessage(String text) async {
  //   text = text.trim();
  //   if (text.length > 0) {
  //     try {
  //       List<int> list = utf8.encode(text);
  //       Uint8List bytes = Uint8List.fromList(list);
  //
  //       connection!.output.add(bytes);
  //       await connection!.output.allSent;
  //
  //       if (text == "START") {
  //         _connectionState = ConnectionState.connected;
  //       } else if (text == "STOP") {
  //         _connectionState = ConnectionState.disconnected;
  //       }
  //       setState(() {});
  //     } catch (e) {
  //       setState(() {});
  //     }
  //   }
  // }



  _completeByte() async {
    if (chunks.isEmpty || contentLength == 0) return;
    SVProgressHUD.dismiss();
    print("CompleteByte length : $contentLength");
    _bytes = Uint8List(contentLength);
    int offset = 0;
    for (final List<int> chunk in chunks) {
      // streamPlayer.feedFromStream(Unit8List.fromList(chunk));
      _bytes!.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    final file = await _makeNewFile;
    var headerList = WavHeader.createWavHeader(contentLength);

    setState(() {
      print("${headerList.length}***");
    });
    file.writeAsBytesSync(headerList, mode: FileMode.write);
    file.writeAsBytesSync(_bytes!, mode: FileMode.append);

    print(await file.length());

    _listofFiles();

    contentLength = 0;
    chunks.clear();
  }

  void _onDataReceived(Uint8List data) async {

  }

  void createChannel()async{
    password.text= (await info.getWifiIP())!;
    print(await info.getWifiIP());
    // final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 8080);
    // server.listen((event) {
    //   event.listen((data) {
    //
    //   });
    // });
    final server2 = await HttpServer.bind(InternetAddress.anyIPv4,8080);
    print('Server running on port ${server2.port}');

    await for (HttpRequest request in server2) {
      ws = await WebSocketTransformer.upgrade(request);
      print('WebSocket request received');
      ws.listen((message) {
        print('Received message: $message');
        Uint8List data=message as Uint8List;
        if (data.isNotEmpty) {
          chunks.add(data);
          // var arr = _bytes!.buffer.asUint8List(data as int);
          streamPlayer.foodSink!.add(FoodData(data));

          setState(() {
            contentLength += data.length;
            _timer!.reset();

            // streamData.add(data);
          });
        }

        print("Content Length: ${contentLength}, chunks: ${chunks.length}");
      });
    }

  }
  void initStreamPlayer()async{
    await streamPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100
    );

    streamPlayer.setSubscriptionDuration(Duration(milliseconds: 500));
    streamPlayer.setVolume(1.0);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wifi-Connection',style: TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
                child: SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 10,),
                        Icon(Icons.wifi),
                        SizedBox(width: 10,),
                        Text(widget.wifiName,style: TextStyle(color: Colors.black,fontSize: 16),),
                      ],
                    )
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width*0.8,
                  child: TextField(
                    controller: password,
                    decoration: InputDecoration(
                        hoverColor: Colors.black,
                        prefixIcon: Icon(Icons.key),
                        hintText: 'Enter Password'
                    ),
                    style: TextStyle(color: Colors.black),
                    keyboardType: TextInputType.text,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                    onPressed: (){
                      // ws.add('START');
                      // detailPageSample._sendMessage("GO");
                      print(InternetAddress.loopbackIPv4);
                      setState(() {
                        // wifiName.text=InternetAddress.loopbackIPv4.address;
                      });
                    },
                    child:Text('Connect',style: TextStyle(color: Colors.white),)),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                    onPressed: (){
                      ws.add('STOP');
                      print(InternetAddress.loopbackIPv4);
                      setState(() {
                        // wifiName.text=InternetAddress.loopbackIPv4.address;
                      });
                    },
                    child:Text('Stop',style: TextStyle(color: Colors.white),)),
              ),

              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 10,
              ),

              Expanded(
                child: ListView(
                  children: files
                      .map((_file) => FileEntityListTile(
                    filePath: _file.path,
                    fileSize: _file.statSync().size,
                    onLongPress: () async {
                      print("onLongPress item");
                      if (await File(_file.path).exists()) {
                        File(_file.path).deleteSync();
                        files.remove(_file);
                        setState(() {});
                      }
                    },
                    onTap: () async {
                      print("onTap item");
                      player.startPlayer(fromURI: _file.path);
                      if (_file.path == selectedFilePath) {
                        print("++++++++++++++++++@@@@@@@@@@@***${_file.path}");
                        await player.stopPlayer();
                        selectedFilePath = '';
                        return;
                      }

                      if (await File(_file.path).exists()) {
                        selectedFilePath = _file.path;
                        // controller.startPlayer(finishMode: FinishMode.stop);


                        player.startPlayer(fromURI: _file.path,codec: Codec.pcm16);

                        print("***${_file.path}");

                        print("***${_file.path}");

                      } else {
                        selectedFilePath = '';
                      }


                      setState(() {});
                    },
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  Future<File> get _makeNewFile async {
    final path = await _localPath;
    String newFileName = dateFormat.format(DateTime.now());
    return File('$path/$newFileName.wav');
  }

  void _listofFiles() async {
    final path = await _localPath;
    var fileList = Directory(path).list();
    files.clear();
    fileList.forEach((element) {
      if (element.path.contains("wav")) {
        files.insert(0, element);

        print("PATH: ${element.path} Size: ${element.statSync().size}");
      }
    });

    setState(() {});
  }


}