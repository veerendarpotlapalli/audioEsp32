import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../Bluetooth BLE  Websocket/ble_connection.dart';
import '../../Bluetooth BLE  Websocket/webSocketStreamSave.dart';

class BluetoothBLeSettings extends StatefulWidget {


  @override
  _BluetoothBLeSettingsState createState() => _BluetoothBLeSettingsState();
}

class _BluetoothBLeSettingsState extends State<BluetoothBLeSettings> {

  TextEditingController password=TextEditingController();

  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  late String TARGET_DEVICE_NAME;

  FlutterBluePlus  flutterBluePlus = FlutterBluePlus .instance;
  late List<BluetoothDevice> pairedDevices = [];
  late List<BluetoothDevice> connectedDevice = [];
  List<String> wifiList=[];
  final info = NetworkInfo();

  late String wifiName ;

  String ch='';
  String wifiConnection = "";

  var passcode = "";
  var ipAdd = '';



  StreamSubscription<ScanResult>? scanSubscription;

  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;

  String connectionText = "";

  int mtuSize = 64;

  @override
  void initState() {
    super.initState();

    deviceConnection();
    // dataReceive();

    // startScan();

  }

  deviceConnection() async {

    pairedDevices = await flutterBluePlus.bondedDevices;
    connectedDevice = await flutterBluePlus.connectedDevices;

  }

  startScan() {
    setState(() {
      connectionText = "Start Scanning";
    });

    // scanSubscription = flutterBluePlus.scan().listen((scanResult) {
    //   print(scanResult.device.name);
    //   if (scanResult.device.name.contains(TARGET_DEVICE_NAME)) {
    //     stopScan();
    //
    //     setState(() {
    //       connectionText = "Found Target Device";
    //     });
    //
    //     targetDevice = scanResult.device;
    //     connectToDevice();
    //   }
    // }, onDone: () => stopScan());

    print('------------------------------${targetDevice}------------------------)');

  }


  stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
    setState(() {});

  }


  connectToDevice() async {
    if (targetDevice == null) {
      return;
    }

    setState(() {
      connectionText = "Device Connecting";
    });

    StreamSubscription<BluetoothDeviceState> subscription;

    subscription = targetDevice!.state.listen((state) async {

      if (state == BluetoothDeviceState.connected) {
        discoverServices();
      } else {
        await targetDevice!.connect();
      }
    });

    setState(() {
      // targetDevice!.requestMtu(mtuSize);
      connectionText = "Device Connected";
    });

    // discoverServices();
  }


  disconnectFromDeivce() {
    if (targetDevice == null) {
      return;
    }

    targetDevice!.disconnect();

    setState(() {
      connectionText = "Device Disconnected";
    });
  }


  discoverServices() async {
    if (targetDevice == null) {
      return;
    }
    List<BluetoothService> services = await targetDevice!.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristics) {
          if (characteristics.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristics;
            setState(() {
              connectionText = "All Ready with ${targetDevice!.name}";
            });
          }
        });
      }
    });

    print('====================${targetDevice!.name}===========================');
    writeData('OKAY');



  }

  writeData(String data) async {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic!.write(bytes);

    List<int> value = await targetCharacteristic!.read();
    String message = String.fromCharCodes(value);

    print('^^^^^^^^^^^^^^^^^^^^^^^^^${message}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

    // Stream<List<int>> stream = targetCharacteristic!.setNotifyValue(true) as Stream<List<int>>;
    // stream.listen((value) {
    //   print('<<<<<<<<<<<<<<<<<<<<<<<<<$value<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
    // });

    setState(() {});

  }


  dataReceive() async {

    setState(() {});

    List<int> value = await targetCharacteristic!.read();
    print('^^^^^^^^^^^^^^^^^^^^^^^^^$value^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

    Stream<List<int>> stream = targetCharacteristic!.setNotifyValue(true) as Stream<List<int>>;
    stream.listen((value) {
      print('<<<<<<<<<<<<<<<<<<<<<<<<<$value<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
    });

    setState(() {});

  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   stopScan();
  //   disconnectFromDeivce();
  // }

  submitAction() {
    var wifiData = '${wifiNameController.text},${wifiPasswordController.text}';
    writeData(wifiData);
  }

  TextEditingController wifiNameController = TextEditingController();
  TextEditingController wifiPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32 Voice Recorder"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            // SwitchListTile(
            //   title: Text('Enable Bluetooth'),
            //   value: _bluetoothState.isEnabled,
            //   onChanged: (bool value) {
            //     future() async {
            //       if (value) {
            //         await FlutterBluetoothSerial.instance.requestEnable();
            //       } else {
            //         await FlutterBluetoothSerial.instance.requestDisable();
            //       }
            //       future().then((_) {
            //         setState(() {});
            //       });
            //     }
            //   },
            // ),
            ListTile(
              leading: IconButton(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: Icon(Icons.refresh)),
              title: Text("Bluetooth STATUS"),
              subtitle: Text('hello'),
              trailing: ElevatedButton(
                child: Text("Settings"),
                onPressed: () async {

                  AppSettings.openBluetoothSettings();

                  setState(() {});

                },
              ),
            ),

            Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    deviceConnection();
                  },
                  child: ListView.builder(
                    itemCount: pairedDevices.length,
                    itemBuilder: (BuildContext context, int index) {
                      final device = pairedDevices[index];
                      TARGET_DEVICE_NAME = device.name;
                      return ListTile(
                        title: Text(device.name),
                        subtitle: Text(device.id.toString()),
                        onTap: () {

                          print('+++++++++++++++${TARGET_DEVICE_NAME}+++++++++++++++++++++');
                          targetDevice = device;
                          targetDevice!.requestMtu(mtuSize);

                          print('((((((($mtuSize(((((((');

                          // connectToDevice();

                          startConnection(context,device);

                          // targetDevice = device;
                          // print('^^^^^^^^^^^^^^^^^^^${targetDevice}^^^^^^^^^^^^^^^^^^^^^^^^^');

                          // connectToDevice();

                          // writeData('OKAY');

                          // print('........................okay.........................');
                          // Do something when the user taps on a device
                        },
                        onLongPress: () {
                          StreamSubscription<BluetoothDeviceState> subscriptions;

                          subscriptions = targetDevice!.state.listen((state) async {

                            if (state == BluetoothDeviceState.connected) {
                              await targetDevice!.disconnect();
                            } else {
                              setState(() {});
                            }
                          });
                          Fluttertoast.showToast(msg: 'Device Disconnected...');
                        },
                      );
                    },
                  ),
                )

            )



            // Expanded(
            //   child: ListView(
            //     children: devices
            //         .map((_device) =>
            //         BluetoothDeviceListEntry(
            //           device: _device,
            //           enabled: true,
            //           onTap: () {
            //             print("Item");
            //             _startCameraConnect(context, _device);
            //           },
            //         ))
            //         .toList(),
            //   ),
            // )



          ],
        ),
      ),
    );
  }


  ConnecttoWifiPopUp(int index){

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
                                    writeData("PWD:$passcode");
                                    writeData("IP:$ipAdd");
                                    print("****************####################@@@@@@@@@@@@@@@");
                                    print(InternetAddress.loopbackIPv4);
                                    // Navigator.of(context).pop();
                                    // wifiConnection == "WIFI:CONNECTED" ?
                                    Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WebSocketStreamSave()));
                                    // CircularProgressIndicator();
                                    // _showWIFIRecordingDialog();
                                    // _showRecordingDialog();
                                    setState(() {
                                      // wifiName.text=InternetAddress.loopbackIPv4.address;
                                    });

                                    // var url = Uri.parse('http://192.168.4.1/');
                                    // await launchUrl(url);

                                  },
                                  child:Text('Connect',style: TextStyle(color: Colors.white),)),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width*0.4,
                              child: TextButton(
                                  style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                                  onPressed: () async {
                                    // ws.add('STOP');
                                    writeData("BACK");
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

  void startConnection(BuildContext context, BluetoothDevice server){
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return BLEConnection(device: server);   // smart config , bluetooth Connection , websocket
      // return DetailPage(server: server);   // blutooth EDR

    }));
  }

}