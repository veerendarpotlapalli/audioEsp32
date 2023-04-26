// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart';


import 'package:audioplayers/audioplayers.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsaudio/BluetoothDeviceListEntry.dart';
import 'package:vsaudio/blutoothBLE.dart';
import 'package:vsaudio/webSocketStreamSave.dart';
import 'package:vsaudio/detailPageSample.dart';
import 'package:vsaudio/http_web.dart';
import 'package:vsaudio/webSocketCheckSums.dart';
// import 'demodetail.dart';
import 'detailpage.dart';
import 'package:flutter/material.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';

import 'package:ffmpeg_kit_flutter/level.dart';
import 'package:ffmpeg_kit_flutter/log.dart';

void main() {

  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   statusBarColor: Colors.lightBlueAccent,
  //   systemNavigationBarColor: Colors.lightBlueAccent,
  // ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

final wifiName = "okay";



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: HomePage(), //bluetooth,websocket,smartConfig
      // home: WebSocketStreamSave(), //websocket stream and save
      // home: httpWeb(), //http,web
      // home: WebSocketCheckSums(), //web socket stream and save with check sums
      home: BluetoothBLE(), // Bluetooth ble connectivity


      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black38,
        ),
        scaffoldBackgroundColor: Colors.white,
        // buttonColor: Colors.waggon,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;


  List<BluetoothDevice> devices = <BluetoothDevice>[];
  DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH_mm_ss");


  AudioPlayer audioPlayer = AudioPlayer();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getBTState();
    _stateChangeListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state.index == 0) {
      //resume
      if (_bluetoothState.isEnabled) {
        _listBondedDevices();
      }
    }
  }

  _getBTState() {
    FlutterBluetoothSerial.instance.state.then((state) {
      _bluetoothState = state;
      if (_bluetoothState.isEnabled) {
        _listBondedDevices();
      }
      setState(() {});
    });
  }

  _stateChangeListener() {
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      _bluetoothState = state;
      if (_bluetoothState.isEnabled) {
        _listBondedDevices();
      } else {
        devices.clear();
      }
      print("State isEnabled: ${state.isEnabled}");
      setState(() {});
    });
  }

  _listBondedDevices() {
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      devices = bondedDevices;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32 Voice Recorder"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            SwitchListTile(
              title: Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                future() async {
                  if (value) {
                    await FlutterBluetoothSerial.instance.requestEnable();
                  } else {
                    await FlutterBluetoothSerial.instance.requestDisable();
                  }
                  future().then((_) {
                    setState(() {});
                  });
                }
              },
            ),
            ListTile(
              title: Text("Bluetooth STATUS"),
              subtitle: Text(_bluetoothState.toString()),
              trailing: ElevatedButton(
                child: Text("Settings"),
                onPressed: () async {

                  // final url = "tcp://192.168.4.1:80";
                  // final directory = await getExternalStorageDirectory();
                  // final path = directory!.path;
                  // final fileName = dateFormat.format(DateTime.now());
                  // final outputFile = '$path/$fileName.wav';
                  //
                  // saveAudioStream(url, outputFile);

                  // var url = Uri.parse('http://192.168.4.1/');
                  // await launchUrl(url);

                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),
            Expanded(
              child: ListView(
                children: devices
                    .map((_device) =>
                    BluetoothDeviceListEntry(
                      device: _device,
                      enabled: true,
                      onTap: () {
                        print("Item");
                        _startCameraConnect(context, _device);
                      },
                    ))
                    .toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _startCameraConnect(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return DetailPageSample(server: server);   // smart config , bluetooth Connection , websocket
      // return DetailPage(server: server);   // blutooth EDR

    }));
  }


  // void saveAudioStream(String url, String outputFile) async {
  //
  //   print("***************##########@@@@@@@@@@@@@@@#$outputFile");
  //   print("***************##########@@@@@@@@@@@@@@@#$url");
  //
  //   final arguments = ['-i', url, '-c', 'copy', outputFile];
  //
  //   await FFmpegKit.execute(arguments.toString()).then((session) async {
  //     final returnCode = await session.getReturnCode();
  //     if(ReturnCode.isSuccess(returnCode)) {
  //       print('ewwwwwwwwwwwwwwwwwwwwww');
  //     } else if(ReturnCode.isCancel(returnCode)) {
  //       print('*************canceled**************');
  //     } else {
  //       print('###########error#############');
  //     }
  //   });
  //
  // }



}
