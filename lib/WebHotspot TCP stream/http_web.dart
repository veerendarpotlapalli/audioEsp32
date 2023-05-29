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
          children: [

            ElevatedButton(
                onPressed: (){
                  playAudio();
                },
                child: Text("inApp PLAY")
            ),

            SizedBox(height: 40,),

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

    /*   here the audio will play within the app with the help of Audio Player library
         where the Audio Player method can able to Play the audio of url's
         we are taking the TCP IP as a url and giving it to the Audio Player   */

    await audioPlayer.play(UrlSource('http://192.168.4.1/'));

  }

  urlAudio () async {

    /*   Here we are giving the IP as the url to the URLlauncher so that it can
         Launch the url where we can able to listen the audio which is coming
         from the pebbl device   */

      var url = Uri.parse('http://192.168.4.1/');
      await launchUrl (url);

  }


}
