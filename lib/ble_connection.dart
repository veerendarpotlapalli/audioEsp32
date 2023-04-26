import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:vsaudio/webSocketStreamSave.dart';


class BLEConnection extends StatefulWidget {

  final BluetoothDevice? device;

  BLEConnection({this.device});

  @override
  _BLEConnectionState createState() => _BLEConnectionState();

}

class _BLEConnectionState extends State<BLEConnection> {

  bool isConnecting = true;
  List<String> wifiList=[];

  // bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;


  TextEditingController password=TextEditingController();

  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  late String TARGET_DEVICE_NAME;

  FlutterBluePlus  flutterBluePlus = FlutterBluePlus .instance;
  late List<BluetoothDevice> pairedDevices = [];
  late List<BluetoothDevice> connectedDevice = [];
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
    connectToDevice();

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

    ipAdd = (await info.getWifiIP())!;
    print('############################$ipAdd################################');


    targetDevice = widget.device;

    print('++++++++++++++++++++++++++$targetDevice+++++++++++++++++++++++++++++++++++++++');

    setState(() {
      connectionText = "Device Connecting";
    });

    StreamSubscription<BluetoothDeviceState> subscription;

    subscription = targetDevice!.state.listen((state) async {

      if (state == BluetoothDeviceState.connected) {
        discoverServices();
      } else {
        await targetDevice!.connect();
        discoverServices();
      }
    });

    setState(() {
      targetDevice!.requestMtu(mtuSize);
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
            if(targetCharacteristic!.properties.notify) {

              targetCharacteristic!.setNotifyValue(true);
              targetCharacteristic!.value.listen((value) {
                // handle incoming data

                List<int> charCodes = value;

                var list = new String.fromCharCodes(charCodes);

                print("***********************Data received: ${list}**********************");
              });


            } else {
              print('............................SORRY............................');
            }
            // setState(() {
            //   connectionText = "All Ready with ${targetDevice!.name}";
            // });
          }
        });
      }
    });

    print('====================${targetDevice!.name}===========================');


  }

  writeData(String data) async {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic!.write(bytes,withoutResponse: true);

    // List<int> value = await targetCharacteristic!.read();
    // String message = String.fromCharCodes(value);
    //
    // print('^^^^^^^^^^^^^^^^^^^^^^^^^${message}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

    if(data == "SCAN") {

      if(wifiList.isEmpty) {
        Uint8List? value = (await targetCharacteristic!.read()) as Uint8List?;

        dataReceive(value!);
      } else {
        Fluttertoast.showToast(msg: "...........");
      }


    }

    if(data == "PWD:$passcode") {
      return writeData("IP:$ipAdd");
    }

    if(data =='WS_INIT') {
      Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WebSocketStreamSave()));
    }

    setState(() {});

  }


  dataReceive(Uint8List data) async {

    setState(() {});

    // List<int> value = await targetCharacteristic!.read();
    print('^^^^^^^^^^^^^^^^^^^^^^^^^$data^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

    List<int> charCodes = data;
    print(new String.fromCharCodes(charCodes));

    data.forEach((element) {
      if(element!=10) {
        ch += String.fromCharCode(element);
      }else{
        setState(() {
          wifiList.add(ch);
          ch = '';
        });
      }
    });

  }

  @override
  void dispose() {
    super.dispose();
    stopScan();
    disconnectFromDeivce();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
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

                          writeData("SSID:${wifiList[index].toString()}");

                          // Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ConnectToWifi(wifiName: e,)));
                        },

                      ),
                    );
                  },

                ),
              ),

            ],
          )
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
                )
            )
        ),
        onPressed: () async {

            writeData("SCAN");

          // var url = Uri.parse('http://192.168.4.1/');
          // await launchUrl(url);

        },
        child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'SCAN',
          style: const TextStyle(fontSize: 24),
        ),
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
                                    print("****************####### $ipAdd #############@@@@@@@@@@@@@@@");
                                    print(InternetAddress.loopbackIPv4);
                                    // Navigator.of(context).pop();
                                    // wifiConnection == "WIFI:CONNECTED" ?

                                    // List<int> value = await targetCharacteristic!.read();
                                    // print('^^^^^^^^^^^^^^^^^^^^^^^^^$value^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
                                    // List<int> charCodes = value;
                                    // print(new String.fromCharCodes(charCodes));
                                    // print('^^^^^^^^^^^^^^^^^^^^^^^^^$value^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

                                    showWebSocketConformation();

                                    // Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WebSocketStreamSave()));
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


  showWebSocketConformation() {
    showCupertinoDialog<String>(
      context : context,
      builder: (BuildContext context) =>
          CupertinoAlertDialog(
            title: const Text("Confirm"),
            content: const Text("Are you sure you want to Stream.... "),
            actions: <Widget>[
              TextButton(onPressed: () async {
                // Fluttertoast.showToast(msg: "App");
                Navigator.pop(context);
              },
                child: const Text("No"),
              ),
              TextButton(onPressed: () async {
                writeData("WS_INIT");
              },
                child: const Text("Yes"),
              ),
            ],
          ),

    ); //showCupertinoDialog

  }


}
