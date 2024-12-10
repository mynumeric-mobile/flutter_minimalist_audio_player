import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum FadingType { none, fadeIn, fadeOut }

///
/// MinimalistAudioPlayer Widget
///
class MinimalistAudioPlayer extends StatefulWidget {
  const MinimalistAudioPlayer({super.key, required this.media, this.beforeStart, this.onStart, this.onStop});
  final dynamic media;

  ///
  /// allow job before start buffering source
  /// for fade out for exemple
  ///
  final Future<void> Function(MiniPlayer)? beforeStart;

  ///
  /// call when user click play before buffering start and play
  ///
  final Function(MiniPlayer)? onStart;

  ///
  /// call when player stop playing
  ///
  final Function(MiniPlayer)? onStop;

  @override
  State<MinimalistAudioPlayer> createState() => _MinimalistAudioPlayerState();
}

class _MinimalistAudioPlayerState extends State<MinimalistAudioPlayer> {
  late StreamSubscription<PlayerState> _stream;
  PlayerState _state = PlayerState.stopped;
  bool _waiting = false;
  final _player = MiniPlayer();
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
                  _player.fadeOut(duration: const Duration(seconds: 3));
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
                    await _player
                        .fadeIn(
                            source: UrlSource(widget.media, mimeType: "audio/mpeg"),
                            beforeStart: widget.beforeStart,
                            mode: PlayerMode.mediaPlayer)
                        .then((value) async {
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

///
/// Enum Player state helper class
///

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

///
/// Fade mode
///
enum FadeMode { fadeIn, fadeOut }

///
/// Extende audio player
///
class MiniPlayer extends AudioPlayer {
  double? _refVolume;
  Duration? _fadeRemaining;

  ///
  /// Default fade duration
  ///
  Duration defaultFadeDuration = const Duration(seconds: 1);

  ///
  /// update fade loop duration
  ///
  final Duration fadeLoopDuration = const Duration(milliseconds: 50);

  ///
  /// play override
  /// handle before start function
  ///
  @override
  Future<void> play(Source source,
      {double? volume,
      double? balance,
      AudioContext? ctx,
      Duration? position,
      PlayerMode? mode,
      Function(MiniPlayer)? beforePlay}) async {
    if (beforePlay != null) await beforePlay.call(this);
    return super.play(
      source,
      volume: volume,
      ctx: ctx,
      position: position,
      mode: mode,
    );
  }

  ///
  /// fade out audio file
  ///
  Future<void> fadeOut({Duration? duration}) async {
    if (state != PlayerState.playing) return;
    _fadeRemaining = null;
    return _fade(duration: duration ?? defaultFadeDuration, fadeMode: FadeMode.fadeOut);
  }

  ///
  /// fade in audio file
  ///
  Future<void> fadeIn(
      {Duration? duration,
      required Source source,
      double? volume,
      double? balance,
      AudioContext? ctx,
      Duration? position,
      PlayerMode? mode,
      Function(MiniPlayer)? beforeStart}) async {
    return play(source, volume: volume, balance: balance, ctx: ctx, position: position, mode: mode, beforePlay: beforeStart)
      ..then((value) {
        _fadeRemaining == null;
        _fade(
          duration: duration ?? defaultFadeDuration,
          fadeMode: FadeMode.fadeIn,
        );
      });
  }

  ///
  /// internal fade audio file
  ///
  Future<void> _fade({required Duration duration, required FadeMode fadeMode, Function? onEnd}) async {
    if (_fadeRemaining == null) {
      _fadeRemaining = Duration(milliseconds: duration.inMilliseconds);
      if (fadeMode == FadeMode.fadeOut || _refVolume == null) _refVolume = volume;
    }

    _fadeRemaining = Duration(milliseconds: max(0, _fadeRemaining!.inMilliseconds - fadeLoopDuration.inMilliseconds));

    final p = _fadeRemaining!.inMilliseconds / duration.inMilliseconds;

    setVolume((fadeMode == FadeMode.fadeIn ? 1 - p : p) * _refVolume!);

    if (p == 0) {
      _fadeRemaining = null;
      if (fadeMode == FadeMode.fadeOut) {
        await stop();
        onEnd?.call();
      } else {
        onEnd?.call();
      }
    } else {
      Future.delayed(fadeLoopDuration, () {
        _fade(duration: duration, fadeMode: fadeMode);
      });
    }
  }
}
