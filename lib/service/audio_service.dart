// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

// Project imports:
import 'app_state_service.dart';

class AudioService extends GetxService {
  static const LAN_CODE_JP = 'ja';

  /// Main audio player we use
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// State of main player
  final Rx<AudioPlayerState> playerState = AudioPlayerState.STOPPED.obs;

  /// State indicate player is occupied
  final List<AudioPlayerState> _playerOccupiedState = [
    AudioPlayerState.PLAYING,
    AudioPlayerState.PAUSED
  ];

  /// If some worker is waiting for result of play
  Worker _playerListener;

  /// Key of client using this service, one can observe this key
  /// to know if they still connected to the service
  final RxString clientKey = ''.obs;

  @override
  Future<void> onInit() async {
    if (AppStateService.isDebug) {
      AudioPlayer.logEnabled = true;
    }
    // make playerState subscribe to AudioPlayerState change
    _audioPlayer.onPlayerStateChanged.listen((event) => playerState.value = event);
    ever(playerState, (state) {
      // If a play is stopped, related worker will be disposed.
      // Any callback it has will also be disposed
      if (state == AudioPlayerState.STOPPED) {
        _playerListener?.dispose();
      }
      // When play complete, clientKey is cleared
      if (!_playerOccupiedState.contains(state)) {
        clientKey.value = '';
      }
    });
    super.onInit();
  }

  /// Play byte provided, if other thing is playing, stop it and play the new audio.
  /// If void callback is provided, it will get called after play completed.
  ///
  /// WARN: If play was stopped (other audio want to play etc.), the callback will not be called.
  Future<void> play(Uint8List data, {Function callback, String key = ''}) async {
    clientKey.value = key;
    // Always cache the audio
    await _audioPlayer.playBytes(data, position: 0.seconds);
    if (callback != null) {
      _playerListener = once(playerState, (_) async => await callback(),
          condition: () => playerState.value == AudioPlayerState.COMPLETED);
    }
  }

  Future<void> pause() async {
    if (playerState.value == AudioPlayerState.PLAYING) {
      await _audioPlayer.pause();
    }
  }

  Future<void> resume() async {
    if (playerState.value == AudioPlayerState.PAUSED) {
      await _audioPlayer.resume();
    }
  }

  Future<void> stop() async {
    if (_playerOccupiedState.contains(playerState.value)) {
      await _audioPlayer.stop();
    }
  }

  @override
  void onClose() {
    if (_audioPlayer != null) {
      _audioPlayer.dispose();
    }
    if (_playerListener != null) {
      _playerListener.dispose();
    }
    super.onClose();
  }
}
