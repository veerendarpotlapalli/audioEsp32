

         /*
               Here we are getting wifi list from pebbl device and
               making pebbl device to connect to the particular wifi network and
               if pebbl device connected to wifi we will navigate to streaming Screen

         */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'webSocketStreamSave.dart';


class BLEConnection extends StatefulWidget {

  final BluetoothDevice? device;

  BLEConnection({this.device});

  @override
  _BLEConnectionState createState() => _BLEConnectionState();

}

class _BLEConnectionState extends State<BLEConnection> {

  List<String> wifiList=[];  // storing all the wifi networks in list type
  TextEditingController password = TextEditingController();
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  late String TARGET_DEVICE_NAME;
  final info = NetworkInfo();
  var passcode = "";
  var ipAdd = '';
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String connectionText = "";

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  // connecting to the specific device which we onTap in previous screen
  connectToDevice() async {

    try{
      ipAdd = (await info.getWifiIP())!;
      print('############################$ipAdd################################');
    }catch (e) {
      print('.......................................Wifi is disabled...');
    }

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
        targetDevice!.connect();
        discoverServices();
      }
    });

    setState(() {
      connectionText = "Device Connected";
    });

    // discoverServices();
  }


  // getting / reciving data from pebbl device

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

              print("*************************${targetCharacteristic}****************************");


              targetCharacteristic!.setNotifyValue(true);
              targetCharacteristic!.value.listen((value) {
                // handle incoming data

                List<int> charCodes = value;

                String data = new String.fromCharCodes(charCodes);

                print("***********************Data received: ${data}**********************");

                if(data == "WIFI_CONNECTED") {
                  writeData("IP:$ipAdd");
                  showWebSocketConformation();
                } else if (data == "WIFI_NOT_CONNECTED") {
                  Fluttertoast.showToast(msg: 'wifi not connected');
                } else {
                  CircularProgressIndicator();
                }

              });


            } else {
              print('............................SORRY............................');
            }
          }
        });
      }
    });

    print('====================${targetDevice!.name}===========================');


  }

  // sending data to pebbl device
  writeData(String data) async {

    if (targetCharacteristic == null) return;
    if(data == "SCAN") {

      if(wifiList.isEmpty) {

        List<int> bytes = utf8.encode(data);
        await targetCharacteristic!.write(bytes,withoutResponse: true);

        if(targetCharacteristic!.properties.notify) {

          targetCharacteristic!.setNotifyValue(true);
          targetCharacteristic!.value.listen((value) {
            // handle incoming data

            List<int> charCodes = value;

            String list = new String.fromCharCodes(charCodes);

            print("______________ Data received: ${list} ___________________");

            dataReceive(list);

          });


        } else {
          print('............................SORRY............................');
        }

      } else {
        Fluttertoast.showToast(msg: "These are the Scanned devices...");
      }


    } else if(data == "PWD:$passcode") {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes,withoutResponse: true);
      // writeData("IP:$ipAdd");

    } else if(data =='WS_INIT') {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes,withoutResponse: true);

      Navigator.of(context).push(MaterialPageRoute(builder: (context)=>WebSocketStreamSave()));

    } else if(data == "IP:$ipAdd") {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes,withoutResponse: true);
    } else if(data == "BACK") {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes,withoutResponse: true);
    } else {
      List<int> bytes = utf8.encode(data);
      await targetCharacteristic!.write(bytes,withoutResponse: true);
    }

    setState(() {});

  }


  // received data from pebbl device
  dataReceive(String data) async {
    setState(() {});
    print('^^^^^^^^^^^^^^^^^^^^^^^^^$data^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
    if(data.isNotEmpty) {
      wifiList.add(data);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              shotButton(),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
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
                        writeData("LP_OFF");

                      } else if (index == 1) {
                        writeData("LP_250");

                      } else if (index == 2) {
                        writeData('LP_2500');

                      }
                    },
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: (){
                          writeData("VOL+");

                        },
                        icon: Icon(Icons.volume_up)),
                    SizedBox(width: 50,),

                    IconButton(
                        onPressed: (){
                          writeData("VOL-");
                        },
                        icon: Icon(Icons.volume_down)),
                  ],
                ),
              ),

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


  /*
     connecting to wifi network by sending wifi network name and password.
     After wifi connected we are sending IP addres of mobile device
  */

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
                                    passcode = password.text.toString();

                                    writeData("PWD:$passcode");
                                    print("****************####### $ipAdd #############@@@@@@@@@@@@@@@");

                                    print(InternetAddress.loopbackIPv4);

                                    discoverServices();

                                    setState(() {});

                                  },
                                  child:Text('Connect',style: TextStyle(color: Colors.white),)),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width*0.4,
                              child: TextButton(
                                  style: ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(Colors.blue)),
                                  onPressed: () async {
                                    writeData("BACK");
                                    print(InternetAddress.loopbackIPv4);
                                    setState(() {});
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


  // asking pebbl device to connect to the web socket
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
