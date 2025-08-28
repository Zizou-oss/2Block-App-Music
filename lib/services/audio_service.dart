import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Function(bool)? onPlayerStateChanged;
  Function(String)? onError;
  Function(Duration)? onPositionChanged;
  Function(Duration)? onDurationChanged;
  VoidCallback? onComplete;

  AudioService() {
    // Synchronisation de l'état de lecture
    _audioPlayer.playingStream.listen((isPlaying) {
      onPlayerStateChanged?.call(isPlaying);
    });

    // Synchronisation de la position
    _audioPlayer.positionStream.listen((position) {
      onPositionChanged?.call(position);
    });

    // Synchronisation de la durée
    _audioPlayer.durationStream.listen((duration) {
      onDurationChanged?.call(duration ?? Duration.zero);
    });

    // Gestion de la fin de lecture
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onComplete?.call();
      }
    });

    // Gestion des erreurs
    _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      onError?.call(e.toString());
    });
  }

  Future<void> play(String source) async {
    try {
      if (source.isEmpty) {
        throw Exception('Source audio vide');
      }
      if (kDebugMode) {
        print('Playing source: $source');
      }
      if (source.startsWith('http://') || source.startsWith('https://')) {
        await _audioPlayer.setUrl(source);
      } else {
        await _audioPlayer.setFilePath(source);
      }
      await _audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('AudioService error: $e');
      }
      onError?.call(e.toString());
      rethrow;
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  bool isPlaying() => _audioPlayer.playing;

  Duration? getCurrentPosition() => _audioPlayer.position;

  Duration? getDuration() => _audioPlayer.duration;

  void dispose() {
    _audioPlayer.dispose();
  }
}