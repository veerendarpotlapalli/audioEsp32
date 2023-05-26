import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'ble_connection.dart';

class BluetoothBLE extends StatefulWidget {


  @override
  _BluetoothBLEState createState() => _BluetoothBLEState();
}

class _BluetoothBLEState extends State<BluetoothBLE> {

  TextEditingController password=TextEditingController();
  FlutterBluePlus  flutterBluePlus = FlutterBluePlus .instance;
  late List<BluetoothDevice> pairedDevices = [];
  late List<BluetoothDevice> connectedDevice = [];
  late List<BluetoothDevice>  bluetoothList = [];
  final info = NetworkInfo();
  StreamSubscription<ScanResult>? scanSubscription;
  String connectionText = "";
  int mtuSize = 512;
  String device = "Get Devices";

  @override
  void initState() {
    super.initState();
    deviceConnection();
    startScan();

  }

  deviceConnection() async {

    pairedDevices = await flutterBluePlus.bondedDevices;
    setState(() {});
    connectedDevice = await flutterBluePlus.connectedDevices;

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
            ListTile(
              leading: IconButton(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: Icon(Icons.radar)),
              title: Text("Connect to Bluetooth"),
              trailing: ElevatedButton(
                child: Text(device),
                onPressed: () async {
                  setState(() {
                    if(bluetoothList.isEmpty) {
                      startScan();
                    }
                  });
                },
              ),
            ),

            Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      itemCount: bluetoothList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final device = bluetoothList[index];
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(device.id.toString()),
                          onTap: () async {
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

                            child: RefreshIndicator(
                              onRefresh: () async {
                                setState(() {

                                });
                              },
                              child: ListView.builder(
                                itemCount: bluetoothList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final device = bluetoothList[index];
                                  return ListTile(
                                    title: Text(device.name),
                                    subtitle: Text(device.id.toString()),
                                    onTap: () {
                                      device.connect();
                                      print('______________________________${connectedDevice}________________________________');
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

 void startConnection(BuildContext context, BluetoothDevice server) async {

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return BLEConnection(device: server);   // smart config , bluetooth Connection , websocket
    }));

 }

}
