import 'package:flutter/material.dart';
import 'package:flutter_minimalist_audio_player/flutter_minimalist_audio_player.dart';

const radios = {
  "Europe 2": "https://europe2.lmn.fm/europe2.mp3",
  "RTS": "https://sc.creacast.com/rts-national.mp3",
  "Skyrock": "https://icecast8.play.cz/skyrock128.mp3",
};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MiniPlayer? _currentPlayer;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MinimalistAudioPlayer'),
        ),
        body: Center(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: radios.length,
            itemExtent: 50,
            itemBuilder: (context, index) {
              return DefaultTextStyle(
                  style: TextStyle().copyWith(fontSize: 25, color: Colors.amber),
                  child: radioWidget(radios.keys.elementAt(index), radios.values.elementAt(index)));
            },
          ),
        ),
      ),
    );
  }

  Widget radioWidget(String name, String url) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.radio,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 5),
        Text(name),
        const SizedBox(width: 5),
        MinimalistAudioPlayer(
          media: url,
          onStart: (p) {
            _currentPlayer?.stop();
            _currentPlayer = p;
          },
          onStop: (p) {
            if (_currentPlayer == p) _currentPlayer = null;
          },
        ),
      ],
    );
  }
}
