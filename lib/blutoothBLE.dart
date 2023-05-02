import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsaudio/ble_connection.dart';
import 'package:vsaudio/webSocketStreamSave.dart';

class BluetoothBLE extends StatefulWidget {


  @override
  _BluetoothBLEState createState() => _BluetoothBLEState();
}

class _BluetoothBLEState extends State<BluetoothBLE> {

  TextEditingController password=TextEditingController();

  // final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  // final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  // late String TARGET_DEVICE_NAME;

  FlutterBluePlus  flutterBluePlus = FlutterBluePlus .instance;
  late List<BluetoothDevice> pairedDevices = [];
  late List<BluetoothDevice> connectedDevice = [];

  // List<String> wifiList=[];

  late List<BluetoothDevice>  bluetoothList = [];
  final info = NetworkInfo();

  StreamSubscription<ScanResult>? scanSubscription;

  // BluetoothDevice? targetDevice;
  // BluetoothCharacteristic? targetCharacteristic;

  String connectionText = "";

  int mtuSize = 512;

  String device = "Get Devices";

  @override
  void initState() {
    super.initState();

    // deviceConnection();
    // dataReceive();



    startScan();

  }

  deviceConnection() async {

    pairedDevices = await flutterBluePlus.bondedDevices;
    setState(() {});
    // connectedDevice = await flutterBluePlus.connectedDevices;

  }

  startScan() {

    FlutterBluePlus.instance.scan(timeout: Duration(seconds: 5)).listen((scanResult) {
      // Print the name and ID of each discovered device
      print('*********************');

      print('*********************Device Name: ${scanResult.device.name}');
      print('**********************Device ID: ${scanResult.device.id}');


      if(scanResult.device.name.isNotEmpty) {
        bluetoothList.add(scanResult.device);
      }

      // bluetoothList.add(scanResult.device);


      // scanResult.device.connect();
    });

    // scanSubscription = flutterBluePlus.scan().listen((scanResult) {
    //   print("********************************${scanResult.device.name}");
    //
    //
    //
    //
    //   // if (scanResult.device.name.contains(TARGET_DEVICE_NAME)) {
    //   //   stopScan();
    //   //
    //   //   setState(() {
    //   //     connectionText = "Found Target Device";
    //   //   });
    //   //
    //   //   targetDevice = scanResult.device;
    //   //
    //   // }
    //
    // });

  }


  stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
    setState(() {});

  }


  // disconnectFromDeivce() {
  //   if (targetDevice == null) {
  //     return;
  //   }
  //
  //   targetDevice!.disconnect();
  //
  //   setState(() {
  //     connectionText = "Device Disconnected";
  //   });
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  //   stopScan();
  //   // disconnectFromDeivce();
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32 Voice Recorder"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: IconButton(
                  onPressed: () {
                    // startScan();
                    // Future.delayed(Duration(seconds: 3), () {
                    //   getDevices();
                    // });
                  },
                  icon: Icon(Icons.radar)),
              title: Text("Connect to Bluetooth"),
              // subtitle: Text('Drag to refresh'),
              trailing: ElevatedButton(
                child: Text(device),
                onPressed: () async {
                  setState(() {
                    if(bluetoothList.isEmpty) {
                      startScan();
                    }
                  });
                  // Future.delayed(Duration(seconds: 3), () {
                  //   getDevices();
                  // });
                },
              ),
            ),

            Expanded(

                  // child: ListView.builder(
                  //   itemCount: pairedDevices.length,
                  //   itemBuilder: (BuildContext context, int index) {
                  //     final device = pairedDevices[index];
                  //     TARGET_DEVICE_NAME = device.name;
                  //     return ListTile(
                  //       title: Text(device.name),
                  //       subtitle: Text(device.id.toString()),
                  //       onTap: () {
                  //
                  //         print('+++++++++++++++${TARGET_DEVICE_NAME}+++++++++++++++++++++');
                  //         targetDevice = device;
                  //         targetDevice!.requestMtu(mtuSize);
                  //
                  //         print('((((((($mtuSize(((((((');
                  //
                  //         // connectToDevice();
                  //
                  //         startConnection(context,device);
                  //
                  //       },
                  //       onLongPress: () {
                  //         StreamSubscription<BluetoothDeviceState> subscriptions;
                  //
                  //         subscriptions = targetDevice!.state.listen((state) async {
                  //
                  //           if (state == BluetoothDeviceState.connected) {
                  //             await targetDevice!.disconnect();
                  //             setState(() {
                  //             });
                  //           } else {
                  //             setState(() {});
                  //           }
                  //         });
                  //         Fluttertoast.showToast(msg: 'Device Disconnected...');
                  //       },
                  //     );
                  //   },
                  // ),

                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {

                      });
                    },
                    child: ListView.builder(
                      itemCount: bluetoothList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final device = bluetoothList[index];
                        // TARGET_DEVICE_NAME = device.name;
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(device.id.toString()),
                          onTap: () async {

                            // print('+++++++++++++++${TARGET_DEVICE_NAME}+++++++++++++++++++++');

                            // connectToDevice();

                            device.connect();
                              await device.requestMtu(mtuSize);
                            startConnection(context,device);

                          },
                          onLongPress: () {
                            Fluttertoast.showToast(msg: 'Device Disconnected...');
                          },
                        );
                      },
                    ),
                  ),

            )

          ],
        ),
      ),
    );
  }

  getDevices() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context,setStateForDialog) {
              return AlertDialog(
                contentPadding: EdgeInsets.zero,
                content: Stack(
                  clipBehavior: Clip.none, children: [
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width*0.8,

                            // child: ListView.builder(
                            //   itemCount: pairedDevices.length,
                            //   itemBuilder: (BuildContext context, int index) {
                            //     final device = pairedDevices[index];
                            //     TARGET_DEVICE_NAME = device.name;
                            //     return ListTile(
                            //       title: Text(device.name),
                            //       subtitle: Text(device.id.toString()),
                            //       onTap: () {
                            //
                            //         print('+++++++++++++++${TARGET_DEVICE_NAME}+++++++++++++++++++++');
                            //         targetDevice = device;
                            //         targetDevice!.requestMtu(mtuSize);
                            //
                            //         print('((((((($mtuSize(((((((');
                            //
                            //         // connectToDevice();
                            //
                            //         startConnection(context,device);
                            //
                            //       },
                            //       onLongPress: () {
                            //         StreamSubscription<BluetoothDeviceState> subscriptions;
                            //
                            //         subscriptions = targetDevice!.state.listen((state) async {
                            //
                            //           if (state == BluetoothDeviceState.connected) {
                            //             await targetDevice!.disconnect();
                            //             setState(() {
                            //             });
                            //           } else {
                            //             setState(() {});
                            //           }
                            //         });
                            //         Fluttertoast.showToast(msg: 'Device Disconnected...');
                            //       },
                            //     );
                            //   },
                            // ),

                            child: RefreshIndicator(
                              onRefresh: () async {
                                setState(() {

                                });
                              },
                              child: ListView.builder(
                                itemCount: bluetoothList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final device = bluetoothList[index];
                                  // TARGET_DEVICE_NAME = device.name;
                                  return ListTile(
                                    title: Text(device.name),
                                    subtitle: Text(device.id.toString()),
                                    onTap: () {

                                      // print('+++++++++++++++${TARGET_DEVICE_NAME}+++++++++++++++++++++');

                                      // connectToDevice();

                                      device.connect();
                                      // device.requestMtu(mtuSize);
                                      startConnection(context,device);

                                    },
                                    onLongPress: () {
                                      Fluttertoast.showToast(msg: 'Device Disconnected...');
                                    },
                                  );
                                },
                              ),
                            ),

                      ),

                    ),
                ],
                ),
              );
            }
        );
      },
    );

  }

  // ConnecttoWifiPopUp(int index){
  //
  //   showDialog(
  //       context: context,
  //       builder: (BuildContext context){
  //         return StatefulBuilder(
  //             builder: (context,setStateForDialog){
  //               return AlertDialog(
  //                 contentPadding: EdgeInsets.zero,
  //                 content: Stack(
  //                   clipBehavior: Clip.none, children: <Widget>[
  //                   Padding(
  //                     padding: const EdgeInsets.all(0),
  //                     child: SizedBox(
  //                       height: MediaQuery.of(context).size.height,
  //                       width: MediaQuery.of(context).size.width,
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         crossAxisAlignment: CrossAxisAlignment.center,
  //                         children: [
  //                           Padding(
  //                             padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
  //                             child: SizedBox(
  //                                 width: MediaQuery.of(context).size.width*0.8,
  //                                 child:Row(
  //                                   mainAxisAlignment: MainAxisAlignment.start,
  //                                   children: [
  //                                     SizedBox(width: 10,),
  //                                     Icon(Icons.wifi),
  //                                     SizedBox(width: 10,),
  //                                     Text(wifiList[index].toString(),style: TextStyle(color: Colors.black,fontSize: 16),),
  //                                   ],
  //                                 )
  //                             ),
  //                           ),
  //                           Padding(
  //                             padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
  //                             child: SizedBox(
  //                               width: MediaQuery.of(context).size.width*0.8,
  //                               child: TextField(
  //                                 controller: password,
  //                                 decoration: InputDecoration(
  //                                     hoverColor: Colors.black,
  //                                     prefixIcon: Icon(Icons.key),
  //                                     hintText: 'Enter Password'
  //                                 ),
  //                                 style: TextStyle(color: Colors.black),
  //                                 keyboardType: TextInputType.text,
  //                               ),
  //                             ),
  //                           ),
  //                           SizedBox(
  //                             height: 20,
  //                           ),
  //                           SizedBox(
  //                             width: MediaQuery.of(context).size.width*0.4,
  //                             child: TextButton(
  //                                 style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
  //                                 onPressed: () async {
  //                                   // ws.add('START') ;
  //                                   passcode = password.text.toString();
  //                                   // ipAdd = await info.getWifiIP().toString();
  //                                   writeData("PWD:$passcode");
  //                                   writeData("IP:$ipAdd");
  //                                   print("****************####################@@@@@@@@@@@@@@@");
  //                                   print(InternetAddress.loopbackIPv4);
  //                                   // Navigator.of(context).pop();
  //                                   // wifiConnection == "WIFI:CONNECTED" ?
  //                                   Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WebSocketStreamSave()));
  //                                   // CircularProgressIndicator();
  //                                   // _showWIFIRecordingDialog();
  //                                   // _showRecordingDialog();
  //                                   setState(() {
  //                                     // wifiName.text=InternetAddress.loopbackIPv4.address;
  //                                   });
  //
  //                                   // var url = Uri.parse('http://192.168.4.1/');
  //                                   // await launchUrl(url);
  //
  //                                 },
  //                                 child:Text('Connect',style: TextStyle(color: Colors.white),)),
  //                           ),
  //                           SizedBox(
  //                             width: MediaQuery.of(context).size.width*0.4,
  //                             child: TextButton(
  //                                 style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
  //                                 onPressed: () async {
  //                                   // ws.add('STOP');
  //                                   writeData("BACK");
  //                                   print(InternetAddress.loopbackIPv4);
  //                                   setState(() {
  //                                     // wifiName.text=InternetAddress.loopbackIPv4.address;
  //                                   });
  //
  //
  //                                 },
  //                                 child:Text('Stop',style: TextStyle(color: Colors.white),)),
  //                           ),
  //
  //                           SizedBox(
  //                             width: MediaQuery.of(context).size.width,
  //                             height: 10,
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //                 ),
  //               );
  //             });
  //       });
  //
  // }

 void startConnection(BuildContext context, BluetoothDevice server){
   Navigator.of(context).push(MaterialPageRoute(builder: (context) {
     return BLEConnection(device: server);   // smart config , bluetooth Connection , websocket
     // return DetailPage(server: server);   // blutooth EDR

   }));
 }

}
