import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class httpWeb extends StatefulWidget {
  const httpWeb({Key? key}) : super(key: key);

  @override
  State<httpWeb> createState() => _httpWebState();
}

class _httpWebState extends State<httpWeb> {

  AudioPlayer audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: (){
                  playAudio();
                },
                child: Text("inApp PLAY")
            ),

            SizedBox(height: 50,),

            ElevatedButton(
                onPressed: (){
                  urlAudio();
                },
                child: Text("browser PLAY")
            ),

          ],
        ),
      ),
    );
  }

  playAudio () async {

    await audioPlayer.play(UrlSource('http://192.168.4.1/'));

  }

  urlAudio () async {

    var url = Uri.parse('http://192.168.4.1/');
      await launchUrl (url);

  }

  ipWebView (){

    return Scaffold(
      body: WebViewWidget(controller: WebViewController()
        ..loadRequest(Uri.parse('https://amazon.com')),
      ),
    );

  }


}
