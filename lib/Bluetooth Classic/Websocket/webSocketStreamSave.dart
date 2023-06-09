import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsaudio/Bluetooth%20Classic/file_entity_list_tile.dart';
import 'package:vsaudio/Bluetooth%20Classic/wav_header.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:toggle_switch/toggle_switch.dart';


class WebSocketStreamSave extends StatefulWidget {
  late String wifiName;

  WebSocketStreamSave({super.key});

  @override
  State<WebSocketStreamSave> createState() => _WebSocketStreamSaveState();
}

class _WebSocketStreamSaveState extends State<WebSocketStreamSave> {
  TextEditingController password=TextEditingController();
  late WebSocket webSocket;
  bool isConnecting = true;
  bool isDisconnecting = false;
  List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  Uint8List? _bytes;
  RestartableTimer? _timer;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH_mm_ss");
  Uint8List? dataStream;
  List<FileSystemEntity> files = <FileSystemEntity>[];
  String? selectedFilePath;
  final player = FlutterSoundPlayer(voiceProcessing: true);
  final streamPlayer = FlutterSoundPlayer(voiceProcessing: true);
  final info=NetworkInfo();
  String stopBtn = "Start";


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


  void createChannel()async{
    password.text= (await info.getWifiIP())!;
    print(await info.getWifiIP());
    final server2 = await HttpServer.bind(InternetAddress.anyIPv4,8080);
    print('Server running on port ${server2.port}');

    await for (HttpRequest request in server2) {
      webSocket = await WebSocketTransformer.upgrade(request);
      print('WebSocket request received');
      webSocket.listen((message) {
        print('========================Received message: $message =============================');

        if(message is String) {
          String wsdata = message;
          if(wsdata == "WS_CONNECTED") {
            Fluttertoast.showToast(msg: "WEB SOCKET CONNECTED...");
          }
        } else {

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

    streamPlayer.setSubscriptionDuration(Duration(milliseconds: 300));
    streamPlayer.setVolume(1.0);
  }
  @override
  void initState() {
    createChannel();
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
    super.dispose();
    webSocket.add("WS_EXIT");
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
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                    onPressed: () async {

                      stopBtn = "Recording...";
                      webSocket.add('STARTREC');
                      print(InternetAddress.loopbackIPv4);
                      setState(() {});
                    },
                    child:Text(stopBtn,style: TextStyle(color: Colors.white),)),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                    onPressed: (){
                      stopBtn = "Start";
                      webSocket.add('STOPREC');
                      print(InternetAddress.loopbackIPv4);
                      setState(() {});
                    },
                    child:Text('Stop',style: TextStyle(color: Colors.white),)),
              ),

              SizedBox(height: 50,),

              Center(
                child: ToggleSwitch(
                  minWidth: 100,
                  minHeight: 40,
                  cornerRadius: 20,
                  fontSize: 17,
                  activeBgColor: [Colors.black38],
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.white38,
                  inactiveFgColor: Colors.grey,
                  totalSwitches: 3,
                  labels: ['OFF','LP_250','LP_2500'],
                  onToggle: (index) {
                    if(index == 0) {
                      webSocket.add("LP_OFF");
                      print('======================  LP_OFF ========================');
                      Fluttertoast.showToast(msg: 'LP_OFF');
                    } else if (index == 1) {
                      webSocket.add("LP_250");
                      print('======================  LP_250 ========================');
                      Fluttertoast.showToast(msg: 'LP_250');

                    } else if (index == 2) {
                      webSocket.add('LP_2500');
                      print('======================  LP_2500 ========================');
                      Fluttertoast.showToast(msg: 'LP_2500');

                    }
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                      IconButton(
                          onPressed: (){
                        webSocket.add("VOL+");

                      },
                          icon: Icon(Icons.volume_up)),
                    SizedBox(width: 50,),

                    IconButton(
                          onPressed: (){
                            webSocket.add("VOL-");
                          },
                          icon: Icon(Icons.volume_down)),
                  ],
                ),
              ),


              Expanded(
                child: ListView(
                  children: files.map((_file) => FileEntityListTile(
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
                        print("++++++++++++++++++@@@@@@@@@@@***********${_file.path}");
                        await player.stopPlayer();
                        selectedFilePath = '';
                        return;
                      }

                      if (await File(_file.path).exists()) {
                        selectedFilePath = _file.path;
                        // controller.startPlayer(finishMode: FinishMode.stop);


                        player.startPlayer(fromURI: _file.path,codec: Codec.pcm16WAV);

                        print("***************${_file.path}");

                        print("***************${_file.path}");

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