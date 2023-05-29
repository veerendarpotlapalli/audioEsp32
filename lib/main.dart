import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'Bluetooth BLE  Websocket/webSocketStreamSave.dart';
import 'Bluetooth Classic/Bluetooth EDR/Home.dart';
import 'Bluetooth Classic/Websocket/Home.dart';
import 'DummyCode/Functionalities/bluetoothBLESettings.dart';
import 'DummyCode/Functionalities/webSocketCheckSums.dart';
import 'WebHotspot TCP stream/http_web.dart';

import 'Bluetooth BLE  Websocket/blutoothBLE.dart';


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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(


      // home: HomePage(),
      /*   bluetooth Classic,websocket,smartConfig [Streaming and Saving]
          Bluetooth Classic --> Websocket --> Home.dart   */


      // home: HomePageEDR(),
      /*    bluetooth Classic EDR [Streaming and Saving]
            Bluetooth Classic --> Bluetooth EDR --> Home.dart   */


      // home: WebSocketStreamSave(),
      /*   websocket stream and save only
           Bluetooth BLE Websocket --> webSocketStreamSave.dart   */


      // home: httpWeb(),
      /*   http,web [Streaming Creating Hotspot]
           WebHotpot TCP stream --> http_web   */


      // home: WebSocketCheckSums(),
      /*   web socket stream and save with check sums
           DummyCode --> Functionalities --> webSocketCheckSums.dart   */


      // home: BluetoothBLeSettings(),
      /*   Bluetooth ble in settings connectivity
           DummyCode --> Functionalities --> bluetoothBLESettings   */


      home: BluetoothBLE(),
      /*   Bluetooth ble in app connectivity,SmartConfig,Streaming,Saving using webSocket [FINAL]
           Bluetooth BLE Websocket --> bluetoothBLE.dart   */


      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black38,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}
