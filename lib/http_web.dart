import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: (){
                  playAudio();
                },
                child: Text("httpWeb PLAY")
            ),
          ],
        ),
      ),
    );
  }

  playAudio () async {

    var url = Uri.parse('http://192.168.4.1/');

    await audioPlayer.play(UrlSource('http://192.168.4.1/'));

    // await launchUrl(url);


  }

}
