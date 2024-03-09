import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MinimalistAudioPlayer extends StatefulWidget {
  const MinimalistAudioPlayer({super.key, required this.media, this.onStart, this.onStop});
  final dynamic media;
  final Function(Player)? onStart;
  final Function(Player)? onStop;

  @override
  State<MinimalistAudioPlayer> createState() => _MinimalistAudioPlayerState();
}

class _MinimalistAudioPlayerState extends State<MinimalistAudioPlayer> {
  late StreamSubscription<PlayerState> _stream;
  PlayerState _state = PlayerState.stopped;
  bool _waiting = false;
  final _player = Player();
  bool _error = false;
  Duration? _duration;
  double? _percent;

  @override
  void initState() {
    _stream = _player.onPlayerStateChanged.listen((it) {
      switch (it) {
        default:
          _state = it;
          setState(() {});
          break;
      }
    });
    _player.onPositionChanged.listen((value) {
      if (_duration == null || _duration!.inSeconds == 0) return;

      _percent = value.inSeconds / _duration!.inSeconds;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _stream.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 40,
        width: 40,
        child: IconButton(
            onPressed: () async {
              switch (_state) {
                case PlayerState.playing:
                  _player.stop();
                  _percent = null;
                  _duration = null;
                  widget.onStop?.call(_player);
                  break;
                default:
                  widget.onStart?.call(_player);
                  _waiting = true;
                  _error = false;
                  _percent = null;
                  setState(() {});
                  try {
                    await _player.play(UrlSource(widget.media)).then((value) async {
                      _duration = await _player.getDuration();
                    }).onError((error, stackTrace) {
                      _error = true;
                      setState(() {});
                    });
                  } catch (e) {
                    _error = true;

                    setState(() {});
                  }

                  _waiting = false;
                  setState(() {});
                  break;
              }
            },
            icon: _error
                ? Icon(Icons.error, color: Theme.of(context).colorScheme.error)
                : _waiting
                    ? Stack(children: [
                        const CircularProgressIndicator(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ])
                    : Stack(children: [
                        if (_state.icon == Icons.stop)
                          CircularProgressIndicator(
                            value: _percent,
                          ),
                        Icon(
                          _state.icon,
                          color: _state.color(Theme.of(context)),
                        ),
                      ])));
  }
}

extension PlayerStateExtension on PlayerState {
  IconData get icon {
    switch (this) {
      case PlayerState.stopped:
        return Icons.play_arrow;
      case PlayerState.playing:
        return Icons.stop;
      case PlayerState.paused:
        return Icons.play_arrow;
      case PlayerState.completed:
        return Icons.play_arrow;
      case PlayerState.disposed:
        return Icons.play_arrow;
    }
  }

  Color? color(ThemeData t) {
    switch (this) {
      case PlayerState.stopped:
        return null;
      case PlayerState.playing:
        return t.colorScheme.primary;
      case PlayerState.paused:
        return null;
      case PlayerState.completed:
        return null;
      case PlayerState.disposed:
        return null;
    }
  }
}

class Player extends AudioPlayer {}
