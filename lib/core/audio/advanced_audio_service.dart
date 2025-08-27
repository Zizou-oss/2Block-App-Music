import 'dart:async';
import 'dart:math';
import '../../../services/audio_service.dart';
import 'equalizer_service.dart';

enum LoopMode { off, single, all }
enum CrossfadeMode { off, short, medium, long }

class AudioEffects {
  final double speed;           // Vitesse de lecture (0.5 - 2.0)
  final double pitch;           // Hauteur tonale (0.5 - 2.0)
  final double volume;          // Volume principal (0.0 - 1.0)
  final double balance;         // Balance gauche-droite (-1.0 à 1.0)
  final bool bassBoost;         // Amplification des basses
  final bool virtualSurround;   // Son surround virtuel
  final bool loudnessEnhancer;  // Amélioration du volume
  final double reverb;          // Effet de réverbération (0.0 - 1.0)
  final double echo;            // Effet d'écho (0.0 - 1.0)

  const AudioEffects({
    this.speed = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.balance = 0.0,
    this.bassBoost = false,
    this.virtualSurround = false,
    this.loudnessEnhancer = false,
    this.reverb = 0.0,
    this.echo = 0.0,
  });

  AudioEffects copyWith({
    double? speed,
    double? pitch,
    double? volume,
    double? balance,
    bool? bassBoost,
    bool? virtualSurround,
    bool? loudnessEnhancer,
    double? reverb,
    double? echo,
  }) {
    return AudioEffects(
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      balance: balance ?? this.balance,
      bassBoost: bassBoost ?? this.bassBoost,
      virtualSurround: virtualSurround ?? this.virtualSurround,
      loudnessEnhancer: loudnessEnhancer ?? this.loudnessEnhancer,
      reverb: reverb ?? this.reverb,
      echo: echo ?? this.echo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speed': speed,
      'pitch': pitch,
      'volume': volume,
      'balance': balance,
      'bassBoost': bassBoost,
      'virtualSurround': virtualSurround,
      'loudnessEnhancer': loudnessEnhancer,
      'reverb': reverb,
      'echo': echo,
    };
  }

  factory AudioEffects.fromJson(Map<String, dynamic> json) {
    return AudioEffects(
      speed: (json['speed'] ?? 1.0).toDouble(),
      pitch: (json['pitch'] ?? 1.0).toDouble(),
      volume: (json['volume'] ?? 1.0).toDouble(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      bassBoost: json['bassBoost'] ?? false,
      virtualSurround: json['virtualSurround'] ?? false,
      loudnessEnhancer: json['loudnessEnhancer'] ?? false,
      reverb: (json['reverb'] ?? 0.0).toDouble(),
      echo: (json['echo'] ?? 0.0).toDouble(),
    );
  }
}

class AdvancedAudioService extends AudioService {
  static final AdvancedAudioService _instance = AdvancedAudioService._internal();
  factory AdvancedAudioService() => _instance;
  AdvancedAudioService._internal();

  // États avancés
  AudioEffects _effects = const AudioEffects();
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleMode = false;
  CrossfadeMode _crossfadeMode = CrossfadeMode.off;
  bool _gaplessPlayback = true;
  double _fadeInDuration = 0.0;
  double _fadeOutDuration = 0.0;

  // Gestion de la queue
  List<String> _playQueue = [];
  int _currentIndex = 0;
  List<String> _shuffleQueue = [];
  int _shuffleIndex = 0;

  // Contrôleurs de stream
  final StreamController<AudioEffects> _effectsController = 
      StreamController<AudioEffects>.broadcast();
  final StreamController<LoopMode> _loopModeController = 
      StreamController<LoopMode>.broadcast();
  final StreamController<bool> _shuffleModeController = 
      StreamController<bool>.broadcast();
  final StreamController<List<String>> _queueController = 
      StreamController<List<String>>.broadcast();

  // Streams
  Stream<AudioEffects> get effectsStream => _effectsController.stream;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  Stream<bool> get shuffleModeStream => _shuffleModeController.stream;
  Stream<List<String>> get queueStream => _queueController.stream;

  // Getters
  AudioEffects get effects => _effects;
  LoopMode get loopMode => _loopMode;
  bool get shuffleMode => _shuffleMode;
  CrossfadeMode get crossfadeMode => _crossfadeMode;
  bool get gaplessPlayback => _gaplessPlayback;
  List<String> get playQueue => List.unmodifiable(_playQueue);
  int get currentIndex => _currentIndex;
  bool get hasNext => _getNextIndex() != null;
  bool get hasPrevious => _getPreviousIndex() != null;

  // Initialisation
  Future<void> initializeAdvanced() async {
    await _loadAdvancedSettings();
    _notifyListeners();
  }

  // Gestion des effets audio
  Future<void> setAudioEffects(AudioEffects newEffects) async {
    _effects = newEffects;
    await _applyAudioEffects();
    _effectsController.add(_effects);
    await _saveAdvancedSettings();
  }

  Future<void> setSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.25, 4.0);
    await setAudioEffects(_effects.copyWith(speed: clampedSpeed));
  }

  Future<void> setPitch(double pitch) async {
    final clampedPitch = pitch.clamp(0.25, 4.0);
    await setAudioEffects(_effects.copyWith(pitch: clampedPitch));
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await setAudioEffects(_effects.copyWith(volume: clampedVolume));
  }

  Future<void> setBalance(double balance) async {
    final clampedBalance = balance.clamp(-1.0, 1.0);
    await setAudioEffects(_effects.copyWith(balance: clampedBalance));
  }

  Future<void> toggleBassBoost() async {
    await setAudioEffects(_effects.copyWith(bassBoost: !_effects.bassBoost));
  }

  Future<void> toggleVirtualSurround() async {
    await setAudioEffects(_effects.copyWith(virtualSurround: !_effects.virtualSurround));
  }

  Future<void> toggleLoudnessEnhancer() async {
    await setAudioEffects(_effects.copyWith(loudnessEnhancer: !_effects.loudnessEnhancer));
  }

  Future<void> setReverb(double reverb) async {
    final clampedReverb = reverb.clamp(0.0, 1.0);
    await setAudioEffects(_effects.copyWith(reverb: clampedReverb));
  }

  Future<void> setEcho(double echo) async {
    final clampedEcho = echo.clamp(0.0, 1.0);
    await setAudioEffects(_effects.copyWith(echo: clampedEcho));
  }

  // Application des effets (simulation)
  Future<void> _applyAudioEffects() async {
    // Dans une vraie implémentation, ici on appliquerait les effets
    // à l'AudioPlayer ou à un plugin d'effets audio
    
    // Simulation de l'application des effets
    if (_effects.speed != 1.0) {
      // Appliquer la vitesse
    }
    
    if (_effects.pitch != 1.0) {
      // Appliquer le pitch
    }
    
    if (_effects.volume != 1.0) {
      // Appliquer le volume
    }
    
    // etc.
  }

  // Gestion de la lecture
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    _loopModeController.add(mode);
    await _saveAdvancedSettings();
  }

  Future<void> toggleLoopMode() async {
    final modes = LoopMode.values;
    final currentIndex = modes.indexOf(_loopMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setLoopMode(modes[nextIndex]);
  }

  Future<void> setShuffleMode(bool enabled) async {
    _shuffleMode = enabled;
    if (enabled) {
      _generateShuffleQueue();
    }
    _shuffleModeController.add(enabled);
    await _saveAdvancedSettings();
  }

  Future<void> toggleShuffleMode() async {
    await setShuffleMode(!_shuffleMode);
  }

  // Gestion de la queue
  Future<void> setPlayQueue(List<String> queue, {int startIndex = 0}) async {
    _playQueue = List.from(queue);
    _currentIndex = startIndex.clamp(0, queue.length - 1);
    
    if (_shuffleMode) {
      _generateShuffleQueue();
    }
    
    _queueController.add(_playQueue);
    await _saveAdvancedSettings();
  }

  Future<void> addToQueue(String source) async {
    _playQueue.add(source);
    if (_shuffleMode) {
      _generateShuffleQueue();
    }
    _queueController.add(_playQueue);
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _playQueue.length) {
      _playQueue.removeAt(index);
      
      // Ajuster l'index actuel si nécessaire
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex && _currentIndex >= _playQueue.length) {
        _currentIndex = _playQueue.length - 1;
      }
      
      if (_shuffleMode) {
        _generateShuffleQueue();
      }
      
      _queueController.add(_playQueue);
    }
  }

  Future<void> moveInQueue(int fromIndex, int toIndex) async {
    if (fromIndex >= 0 && fromIndex < _playQueue.length &&
        toIndex >= 0 && toIndex < _playQueue.length) {
      
      final item = _playQueue.removeAt(fromIndex);
      _playQueue.insert(toIndex, item);
      
      // Ajuster l'index actuel
      if (fromIndex == _currentIndex) {
        _currentIndex = toIndex;
      } else if (fromIndex < _currentIndex && toIndex >= _currentIndex) {
        _currentIndex--;
      } else if (fromIndex > _currentIndex && toIndex <= _currentIndex) {
        _currentIndex++;
      }
      
      if (_shuffleMode) {
        _generateShuffleQueue();
      }
      
      _queueController.add(_playQueue);
    }
  }

  // Navigation dans la queue
  Future<void> playNext() async {
    final nextIndex = _getNextIndex();
    if (nextIndex != null) {
      _currentIndex = nextIndex;
      await play(_getCurrentSource());
    }
  }

  Future<void> playPrevious() async {
    final previousIndex = _getPreviousIndex();
    if (previousIndex != null) {
      _currentIndex = previousIndex;
      await play(_getCurrentSource());
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _playQueue.length) {
      _currentIndex = index;
      await play(_getCurrentSource());
    }
  }

  int? _getNextIndex() {
    if (_playQueue.isEmpty) return null;
    
    if (_shuffleMode) {
      if (_shuffleIndex < _shuffleQueue.length - 1) {
        return _shuffleQueue[_shuffleIndex + 1];
      } else if (_loopMode == LoopMode.all) {
        return _shuffleQueue[0];
      }
    } else {
      if (_currentIndex < _playQueue.length - 1) {
        return _currentIndex + 1;
      } else if (_loopMode == LoopMode.all) {
        return 0;
      }
    }
    
    return _loopMode == LoopMode.single ? _currentIndex : null;
  }

  int? _getPreviousIndex() {
    if (_playQueue.isEmpty) return null;
    
    if (_shuffleMode) {
      if (_shuffleIndex > 0) {
        return _shuffleQueue[_shuffleIndex - 1];
      } else if (_loopMode == LoopMode.all) {
        return _shuffleQueue.last;
      }
    } else {
      if (_currentIndex > 0) {
        return _currentIndex - 1;
      } else if (_loopMode == LoopMode.all) {
        return _playQueue.length - 1;
      }
    }
    
    return null;
  }

  String _getCurrentSource() {
    if (_playQueue.isEmpty || _currentIndex >= _playQueue.length) {
      return '';
    }
    return _playQueue[_currentIndex];
  }

  void _generateShuffleQueue() {
    _shuffleQueue = List.generate(_playQueue.length, (index) => index);
    _shuffleQueue.shuffle();
    
    // S'assurer que l'élément actuel est en première position
    if (_currentIndex < _shuffleQueue.length) {
      final currentPos = _shuffleQueue.indexOf(_currentIndex);
      if (currentPos != -1) {
        _shuffleQueue.removeAt(currentPos);
        _shuffleQueue.insert(0, _currentIndex);
        _shuffleIndex = 0;
      }
    }
  }

  // Fonctions de fade
  Future<void> fadeIn({Duration duration = const Duration(seconds: 3)}) async {
    _fadeInDuration = duration.inMilliseconds.toDouble();
    // Implémenter le fade in
  }

  Future<void> fadeOut({Duration duration = const Duration(seconds: 3)}) async {
    _fadeOutDuration = duration.inMilliseconds.toDouble();
    // Implémenter le fade out
  }

  // Crossfade
  Future<void> setCrossfadeMode(CrossfadeMode mode) async {
    _crossfadeMode = mode;
    await _saveAdvancedSettings();
  }

  Duration get crossfadeDuration {
    switch (_crossfadeMode) {
      case CrossfadeMode.off:
        return Duration.zero;
      case CrossfadeMode.short:
        return const Duration(seconds: 2);
      case CrossfadeMode.medium:
        return const Duration(seconds: 5);
      case CrossfadeMode.long:
        return const Duration(seconds: 10);
    }
  }

  // Presets d'effets
  Future<void> applyPreset(String presetName) async {
    AudioEffects preset;
    
    switch (presetName.toLowerCase()) {
      case 'vocal':
        preset = const AudioEffects(
          bassBoost: false,
          virtualSurround: true,
          loudnessEnhancer: true,
          reverb: 0.2,
        );
        break;
        
      case 'bass':
        preset = const AudioEffects(
          bassBoost: true,
          virtualSurround: false,
          loudnessEnhancer: true,
          reverb: 0.1,
        );
        break;
        
      case 'classical':
        preset = const AudioEffects(
          bassBoost: false,
          virtualSurround: true,
          loudnessEnhancer: false,
          reverb: 0.4,
        );
        break;
        
      case 'rock':
        preset = const AudioEffects(
          bassBoost: true,
          virtualSurround: false,
          loudnessEnhancer: true,
          reverb: 0.2,
          echo: 0.1,
        );
        break;
        
      case 'podcast':
        preset = const AudioEffects(
          speed: 1.2,
          bassBoost: false,
          virtualSurround: false,
          loudnessEnhancer: true,
        );
        break;
        
      default:
        preset = const AudioEffects(); // Preset par défaut
    }
    
    await setAudioEffects(preset);
  }

  // Reset
  Future<void> resetEffects() async {
    await setAudioEffects(const AudioEffects());
  }

  // Méthodes utilitaires
  String getLoopModeDisplayName(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return 'Aucune répétition';
      case LoopMode.single:
        return 'Répéter le titre';
      case LoopMode.all:
        return 'Répéter tout';
    }
  }

  String getCrossfadeModeDisplayName(CrossfadeMode mode) {
    switch (mode) {
      case CrossfadeMode.off:
        return 'Désactivé';
      case CrossfadeMode.short:
        return 'Court (2s)';
      case CrossfadeMode.medium:
        return 'Moyen (5s)';
      case CrossfadeMode.long:
        return 'Long (10s)';
    }
  }

  // Notification des changements
  void _notifyListeners() {
    _effectsController.add(_effects);
    _loopModeController.add(_loopMode);
    _shuffleModeController.add(_shuffleMode);
    _queueController.add(_playQueue);
  }

  // Sauvegarde/Chargement
  Future<void> _saveAdvancedSettings() async {
    // Simulation de sauvegarde
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('audio_effects', jsonEncode(_effects.toJson()));
    // await prefs.setString('loop_mode', _loopMode.name);
    // await prefs.setBool('shuffle_mode', _shuffleMode);
    // await prefs.setString('crossfade_mode', _crossfadeMode.name);
    // await prefs.setBool('gapless_playback', _gaplessPlayback);
  }

  Future<void> _loadAdvancedSettings() async {
    // Simulation de chargement
    // final prefs = await SharedPreferences.getInstance();
    
    // Charger les effets
    // final effectsJson = prefs.getString('audio_effects');
    // if (effectsJson != null) {
    //   _effects = AudioEffects.fromJson(jsonDecode(effectsJson));
    // }
    
    // Charger les autres paramètres
    // _loopMode = LoopMode.values.firstWhere(
    //   (mode) => mode.name == prefs.getString('loop_mode'),
    //   orElse: () => LoopMode.off,
    // );
    
    // _shuffleMode = prefs.getBool('shuffle_mode') ?? false;
    // etc.
  }

  // Nettoyage
  @override
  void dispose() {
    _effectsController.close();
    _loopModeController.close();
    _shuffleModeController.close();
    _queueController.close();
    super.dispose();
  }
}