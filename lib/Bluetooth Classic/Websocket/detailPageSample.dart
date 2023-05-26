import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsaudio/Bluetooth%20Classic/wav_header.dart';
import 'webSocketStreamSave.dart';

enum ScanningState {stopped,scanning}

enum Connstate {connect}

class DetailPageSample extends StatefulWidget {
  final BluetoothDevice? server;
  DetailPageSample({this.server});

  @override
  _DetailPageSampleState createState() => _DetailPageSampleState();

}

class _DetailPageSampleState extends State<DetailPageSample> {

  TextEditingController password=TextEditingController();
  BluetoothDevice? server;
  BluetoothConnection? connection;
  bool isConnecting = true;
  List<String> wifiList=[];
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;
  List<List<int>> chunks = <List<int>>[];
  int contentLength = 0;
  Uint8List? _bytes;
  RestartableTimer? _timer;
  ScanningState _scanState = ScanningState.stopped;
  Connstate _connstate = Connstate.connect;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH_mm_ss");
  Uint8List? dataStream;
  List<FileSystemEntity> files = <FileSystemEntity>[];
  String? selectedFilePath;
  final player = FlutterSoundPlayer(voiceProcessing: true);
  final streamPlayer = FlutterSoundPlayer();
  final info=NetworkInfo();
  late String wifiName ;
  String ch='';
  String wifiConnection = "";
  var passcode = "";
  var ipAdd = '';

  @override
  void initState() {
    player.openPlayer();
    createChannel();
    streamPlayer.openPlayer(enableVoiceProcessing: true);
    _getBTConnection();
    _timer = RestartableTimer(const Duration(seconds: 1), _completeByte);
    _listofFiles();
    selectedFilePath = '';
    initStreamPlayer();
    super.initState();

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
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;

    }
    _timer!.cancel();
    super.dispose();
  }

  void createChannel()async{

    wifiName = (await info.getWifiName())!;
    ipAdd = (await info.getWifiIP())!;
    print(await info.getWifiIP());

  }


  _getBTConnection() {
    BluetoothConnection.toAddress(widget.server!.address).then((_connection) {
      setState(() {
        connection = _connection;
      });
      isConnecting = false;
      isDisconnecting = false;
      setState(() {});
      _connection.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally');
        } else {
          print('Disconnecting remotely');
        }
        if (this.mounted) {
          setState(() {});
        }
        Navigator.of(context).pop();
      });
    }).catchError((error) {
      Navigator.of(context).pop();
    });
  }

  _completeByte() async {
    if (chunks.isEmpty || contentLength == 0) return;
    SVProgressHUD.dismiss();
    print("CompleteByte length : $contentLength");
    _bytes = Uint8List(contentLength);
    int offset = 0;
    for (final List<int> chunk in chunks) {
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
    if (data.isNotEmpty) {
      chunks.add(data);
      wifiConnection = new String.fromCharCodes(data);
      // var arr = _bytes!.buffer.asUint8List(data as int);
      setState(() {
        // wifiList=utf8.decode(data);
        print('${wifiConnection}@@@@@@@@@@@@@@@@@@@@@@@@@@@@###');
      });
      data.forEach((element) {
        if(element!=10) {
          ch += String.fromCharCode(element);
        }else{
          setState(() {
            wifiList.add(ch);
            ch='';
          });
        }
      });
    }

    print("Content Length: ${contentLength}, chunks: ${chunks.length}");
  }

  void _sendMessage(String text) async {
    text = text.trim();
    if (text.isNotEmpty) {
      try {
        List<int> list = utf8.encode(text);
        Uint8List bytes = Uint8List.fromList(list);

        connection!.output.add(bytes);
        await connection!.output.allSent;

        if (text == "SCAN") {
          _scanState = ScanningState.scanning;
        } else if (text == "STOP") {
          _scanState = ScanningState.stopped;
        } else if (text == "GO") {
          _connstate = Connstate.connect;
        } else if (text == "BACK") {
          _connstate = Connstate.connect;
        }
        setState(() {});
      } catch (e) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ${widget.server!.name} ...')
              : isConnected
              ? Text('Connected with ${widget.server!.name}')
              : Text('Disconnected with ${widget.server!.name}')),
        ),
        body: SafeArea(
          child: isConnected
              ? Column(
            children: <Widget>[
              shotButton(),
              Expanded(
                child: ListView.builder(
                  itemCount: wifiList.length,
                  itemBuilder: (context,index){
                    return SafeArea(
                      child: ListTile(
                        title: Text(wifiList[index]),
                        leading: Icon(Icons.wifi),
                        onTap: (){
                          ConnecttoWifiPopUp(index);

                          _sendMessage("SSID:${wifiList[index].toString()}");

                          // Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ConnectToWifi(wifiName: e,)));
                        },

                      ),
                    );
                  },

                ),
              ),

            ],
          )
              : const Center(
            child: Text(
              "Connecting...",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ));
  }

  Widget shotButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.red)
                )
            )
        ),
        onPressed: () async {

          streamPlayer.startPlayer(fromDataBuffer: dataStream,codec: Codec.pcm16);
          if (_scanState == ScanningState.stopped) {
            _sendMessage("SCAN");
            // _showRecordingDialog();
          } else {
            _sendMessage("STOP");
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _scanState == ScanningState.stopped ? "Scan" : "${wifiList.isNotEmpty? wifiList[0]:'Loading..'}",
            style: const TextStyle(fontSize: 24),
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


  ConnecttoWifiPopUp(int index){

    print("******************##################${wifiList[index].characters}");

    showDialog(
        context: context,
        builder: (BuildContext context){
          return StatefulBuilder(
              builder: (context,setStateForDialog){
                return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  content: Stack(
                      clipBehavior: Clip.none, children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(0),
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
                                      Text(wifiList[index].toString(),style: TextStyle(color: Colors.black,fontSize: 16),),
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
                                  onPressed: () async {
                                    // ws.add('START') ;
                                    passcode = password.text.toString();
                                    // ipAdd = await info.getWifiIP().toString();
                                    _sendMessage("PWD:$passcode");
                                    _sendMessage("IP:$ipAdd");
                                    print("****************####################@@@@@@@@@@@@@@@");
                                    print(InternetAddress.loopbackIPv4);
                                    Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WebSocketStreamSave()));
                                    setState(() {});
                                  },
                                  child:Text('Connect',style: TextStyle(color: Colors.white),)),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width*0.4,
                              child: TextButton(
                                  style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                                  onPressed: () async {
                                    _sendMessage("BACK");
                                    print(InternetAddress.loopbackIPv4);
                                    setState(() {
                                    });


                                  },
                                  child:Text('Stop',style: TextStyle(color: Colors.white),)),
                            ),

                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ),
                );
              });
        });

  }


}

