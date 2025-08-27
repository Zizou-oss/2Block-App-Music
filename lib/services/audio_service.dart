import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Function(bool)? onPlayerStateChanged;
  Function(String)? onError;
  Function(Duration)? onPositionChanged;
  Function(Duration)? onDurationChanged;
  VoidCallback? onComplete;
  
  // Gestion des tentatives de reconnexion
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  Timer? _retryTimer;
  
  // Cache de l'URL actuelle pour la récupération
  String? _currentUrl;
  bool _isDisposed = false;

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

  Future<void> play(String source, {bool retry = true}) async {
    if (_isDisposed) return;
    
    try {
      if (source.isEmpty) {
        throw ArgumentError('Source audio vide');
      }
      
      _currentUrl = source;
      _retryCount = 0;
      
      if (kDebugMode) {
        print('Playing source: $source');
      }
      
      await _loadAndPlay(source);
      
    } catch (e) {
      if (kDebugMode) {
        print('AudioService error: $e');
      }
      
      if (retry && _retryCount < _maxRetries) {
        await _retryPlay(source);
      } else {
        onError?.call(e.toString());
        rethrow;
      }
    }
  }
  
  Future<void> _loadAndPlay(String source) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await _audioPlayer.setUrl(source);
    } else {
      await _audioPlayer.setFilePath(source);
    }
    await _audioPlayer.play();
  }
  
  Future<void> _retryPlay(String source) async {
    _retryCount++;
    if (kDebugMode) {
      print('Tentative de reconnexion ${_retryCount}/$_maxRetries pour: $source');
    }
    
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () async {
      if (!_isDisposed) {
        try {
          await _loadAndPlay(source);
        } catch (e) {
          if (_retryCount < _maxRetries) {
            await _retryPlay(source);
          } else {
            onError?.call('Échec après $_maxRetries tentatives: ${e.toString()}');
          }
        }
      }
    });
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
    _isDisposed = true;
    _retryTimer?.cancel();
    _audioPlayer.dispose();
  }
  
  // Méthode pour vérifier la connectivité réseau
  Future<bool> checkConnectivity() async {
    try {
      final uri = Uri.parse('https://www.google.com');
      final response = await Future.any([
        Future.delayed(const Duration(seconds: 5), () => null),
        // Simple test de connectivité
        Future.value(true), // Placeholder - nécessiterait package connectivity_plus
      ]);
      return response == true;
    } catch (e) {
      return false;
    }
  }
  
  // Récupération après erreur réseau
  Future<void> retryCurrentTrack() async {
    if (_currentUrl != null && !_isDisposed) {
      await play(_currentUrl!, retry: true);
    }
  }
}