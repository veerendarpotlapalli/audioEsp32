import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:binary_codec/binary_codec.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slide_popup_dialog_null_safety/slide_popup_dialog.dart' as slideDialog;
import 'package:vsaudio/wav_header.dart';
import 'file_entity_list_tile.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:crc32_checksum/crc32_checksum.dart';



class WebSocketCheckSums extends StatefulWidget {
  late String wifiName;

  WebSocketCheckSums({super.key});

  @override
  State<WebSocketCheckSums> createState() => _WebSocketCheckSumsState();
}

class _WebSocketCheckSumsState extends State<WebSocketCheckSums> {
  TextEditingController password=TextEditingController();
  late WebSocket webSocket;
  bool isConnecting = true;

  bool isDisconnecting = false;

  List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  Uint8List? _bytes;
  // PlayerController controller = PlayerController();// Initialise

  RestartableTimer? _timer;
  // RecordState _recordState = RecordState.stopped;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH_mm_ss");
  Uint8List? dataStream;

  List<FileSystemEntity> files = <FileSystemEntity>[];
  String? selectedFilePath;
  final player = FlutterSoundPlayer(voiceProcessing: true);
  final streamPlayer = FlutterSoundPlayer(voiceProcessing: true);

  final info=NetworkInfo();

  String stopBtn = "Start";

  String hashString ='';

  List<int> websockdata = [];
  var websockhash = '';

  _completeByte() async {
    if (chunks.isEmpty || contentLength == 0) return;
    SVProgressHUD.dismiss();
    print("+++++++++++++++++++++++++++++++++CompleteByte length : $contentLength");
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

    print('??????????????????????????????${_bytes}????????????????????????????????????');

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
      print('WebSocket request received.........................');
      webSocket.listen((message) {
          if(message.length == 512) {
            print('@@@@@@@@@@@@@@@Received message@@@@@@@@@@@@@@@: $message');
            Uint8List data=message as Uint8List;
            if (data.isNotEmpty) {
            chunks.add(data);

            websockdata = message;

            List<int> charCodes = websockdata;

            Digest hello256 = sha256.convert(charCodes);
            hashString = hello256.toString(); // convert hash to base64-encoded string
            print('------------${hashString}-------------');

            setState(() {});

          }

          setState(() {
            contentLength += data.length;
            _timer!.reset();
          });  //setState

         }

            else if(message.length == 64){
          websockhash = message.toString();
          print('<<<<<<<<<<<<$websockhash<<<<<<<<<<<<<<<<');


          String binYes = 'Y';
          String binNo = 'N';

          Uint8List encodeY = binaryCodec.encode(binYes);
          Uint8List encodeN = binaryCodec.encode(binNo);

          var decodeY = binaryCodec.decode(encodeY);
          var decodeN = binaryCodec.decode(encodeN);

          if(hashString == websockhash.toString()) {

            webSocket.add(decodeY);
            print('____________________oooooooooo${decodeY}ooooooooo______________________');

            Uint8List audiodata = websockdata as Uint8List;

            streamPlayer.foodSink!.add(FoodData(audiodata));

          } else {
            print('____________________nnnnnnnnnnnn${decodeN}nnnnnnnnnnnnnn______________________');
            webSocket.add(decodeN);
          }
          setState(() {});
        }

        print("===============================Content Length: ${contentLength}, chunks: ${chunks.length}");
      });

    }

  }
  void initStreamPlayer()async{
    await streamPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100
    );

    streamPlayer.setSubscriptionDuration(Duration(milliseconds: 400));
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
                      setState(() {
                        // wifiName.text=InternetAddress.loopbackIPv4.address;
                      });
                    },
                    child:Text(stopBtn,style: TextStyle(color: Colors.white),)),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.4,
                child: TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                    onPressed: (){
                      stopBtn = "Start";
                      // print(InternetAddress.loopbackIPv4);
                      // webSocket.add('STOPREC');
                      crcHash();
                      setState(() {
                        // wifiName.text=InternetAddress.loopbackIPv4.address;
                      });
                    },
                    child:Text('Stop',style: TextStyle(color: Colors.white),)),
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

  crcHash () {
    String input = "Hello, world!"; // String to calculate CRC32 checksum for

    var CRCchecksum = Crc32.calculate(input);

    print('00000000000000000000000000000....${CRCchecksum}....000000000000000000000000000000000000');
  }

}