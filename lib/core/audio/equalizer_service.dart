import 'dart:async';
import 'dart:math';

enum EqualizerPreset {
  flat,
  rock,
  pop,
  jazz,
  classical,
  electronic,
  hiphop,
  vocal,
  bass,
  treble,
  custom
}

class EqualizerBand {
  final double frequency;
  final double gain;
  final double quality;

  const EqualizerBand({
    required this.frequency,
    required this.gain,
    this.quality = 1.0,
  });

  EqualizerBand copyWith({
    double? frequency,
    double? gain,
    double? quality,
  }) {
    return EqualizerBand(
      frequency: frequency ?? this.frequency,
      gain: gain ?? this.gain,
      quality: quality ?? this.quality,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'gain': gain,
      'quality': quality,
    };
  }

  factory EqualizerBand.fromJson(Map<String, dynamic> json) {
    return EqualizerBand(
      frequency: (json['frequency'] ?? 0.0).toDouble(),
      gain: (json['gain'] ?? 0.0).toDouble(),
      quality: (json['quality'] ?? 1.0).toDouble(),
    );
  }
}

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  // Bandes d'égalisation standard (Hz)
  static const List<double> standardFrequencies = [
    32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
  ];

  List<EqualizerBand> _bands = [];
  EqualizerPreset _currentPreset = EqualizerPreset.flat;
  bool _isEnabled = false;
  double _preamp = 0.0; // Préamplification (-20 à +20 dB)

  // Stream controllers
  final StreamController<List<EqualizerBand>> _bandsController = 
      StreamController<List<EqualizerBand>>.broadcast();
  final StreamController<EqualizerPreset> _presetController = 
      StreamController<EqualizerPreset>.broadcast();
  final StreamController<bool> _enabledController = 
      StreamController<bool>.broadcast();

  // Streams
  Stream<List<EqualizerBand>> get bandsStream => _bandsController.stream;
  Stream<EqualizerPreset> get presetStream => _presetController.stream;
  Stream<bool> get enabledStream => _enabledController.stream;

  // Getters
  List<EqualizerBand> get bands => List.unmodifiable(_bands);
  EqualizerPreset get currentPreset => _currentPreset;
  bool get isEnabled => _isEnabled;
  double get preamp => _preamp;

  // Initialisation
  Future<void> initialize() async {
    _initializeBands();
    await _loadSettings();
    _notifyListeners();
  }

  void _initializeBands() {
    _bands = standardFrequencies.map((freq) => 
        EqualizerBand(frequency: freq, gain: 0.0)).toList();
  }

  // Gestion des presets
  Future<void> setPreset(EqualizerPreset preset) async {
    _currentPreset = preset;
    _bands = _getBandsForPreset(preset);
    _presetController.add(preset);
    _bandsController.add(_bands);
    await _saveSettings();
  }

  List<EqualizerBand> _getBandsForPreset(EqualizerPreset preset) {
    switch (preset) {
      case EqualizerPreset.flat:
        return standardFrequencies.map((freq) => 
            EqualizerBand(frequency: freq, gain: 0.0)).toList();
            
      case EqualizerPreset.rock:
        return [
          const EqualizerBand(frequency: 32, gain: 8.0),
          const EqualizerBand(frequency: 64, gain: 6.0),
          const EqualizerBand(frequency: 125, gain: 4.0),
          const EqualizerBand(frequency: 250, gain: 2.0),
          const EqualizerBand(frequency: 500, gain: -2.0),
          const EqualizerBand(frequency: 1000, gain: -4.0),
          const EqualizerBand(frequency: 2000, gain: 0.0),
          const EqualizerBand(frequency: 4000, gain: 4.0),
          const EqualizerBand(frequency: 8000, gain: 6.0),
          const EqualizerBand(frequency: 16000, gain: 8.0),
        ];
        
      case EqualizerPreset.pop:
        return [
          const EqualizerBand(frequency: 32, gain: -2.0),
          const EqualizerBand(frequency: 64, gain: -1.0),
          const EqualizerBand(frequency: 125, gain: 0.0),
          const EqualizerBand(frequency: 250, gain: 2.0),
          const EqualizerBand(frequency: 500, gain: 4.0),
          const EqualizerBand(frequency: 1000, gain: 6.0),
          const EqualizerBand(frequency: 2000, gain: 6.0),
          const EqualizerBand(frequency: 4000, gain: 4.0),
          const EqualizerBand(frequency: 8000, gain: 2.0),
          const EqualizerBand(frequency: 16000, gain: -1.0),
        ];
        
      case EqualizerPreset.jazz:
        return [
          const EqualizerBand(frequency: 32, gain: 4.0),
          const EqualizerBand(frequency: 64, gain: 3.0),
          const EqualizerBand(frequency: 125, gain: 2.0),
          const EqualizerBand(frequency: 250, gain: 2.0),
          const EqualizerBand(frequency: 500, gain: -1.0),
          const EqualizerBand(frequency: 1000, gain: -2.0),
          const EqualizerBand(frequency: 2000, gain: 0.0),
          const EqualizerBand(frequency: 4000, gain: 2.0),
          const EqualizerBand(frequency: 8000, gain: 3.0),
          const EqualizerBand(frequency: 16000, gain: 4.0),
        ];
        
      case EqualizerPreset.classical:
        return [
          const EqualizerBand(frequency: 32, gain: 5.0),
          const EqualizerBand(frequency: 64, gain: 3.0),
          const EqualizerBand(frequency: 125, gain: 2.0),
          const EqualizerBand(frequency: 250, gain: 2.0),
          const EqualizerBand(frequency: 500, gain: -1.0),
          const EqualizerBand(frequency: 1000, gain: -2.0),
          const EqualizerBand(frequency: 2000, gain: -1.0),
          const EqualizerBand(frequency: 4000, gain: 2.0),
          const EqualizerBand(frequency: 8000, gain: 4.0),
          const EqualizerBand(frequency: 16000, gain: 5.0),
        ];
        
      case EqualizerPreset.electronic:
        return [
          const EqualizerBand(frequency: 32, gain: 6.0),
          const EqualizerBand(frequency: 64, gain: 4.0),
          const EqualizerBand(frequency: 125, gain: 2.0),
          const EqualizerBand(frequency: 250, gain: 0.0),
          const EqualizerBand(frequency: 500, gain: -2.0),
          const EqualizerBand(frequency: 1000, gain: 2.0),
          const EqualizerBand(frequency: 2000, gain: 0.0),
          const EqualizerBand(frequency: 4000, gain: 2.0),
          const EqualizerBand(frequency: 8000, gain: 4.0),
          const EqualizerBand(frequency: 16000, gain: 6.0),
        ];
        
      case EqualizerPreset.hiphop:
        return [
          const EqualizerBand(frequency: 32, gain: 8.0),
          const EqualizerBand(frequency: 64, gain: 6.0),
          const EqualizerBand(frequency: 125, gain: 4.0),
          const EqualizerBand(frequency: 250, gain: 1.0),
          const EqualizerBand(frequency: 500, gain: -1.0),
          const EqualizerBand(frequency: 1000, gain: -2.0),
          const EqualizerBand(frequency: 2000, gain: -1.0),
          const EqualizerBand(frequency: 4000, gain: 2.0),
          const EqualizerBand(frequency: 8000, gain: 3.0),
          const EqualizerBand(frequency: 16000, gain: 4.0),
        ];
        
      case EqualizerPreset.vocal:
        return [
          const EqualizerBand(frequency: 32, gain: -3.0),
          const EqualizerBand(frequency: 64, gain: -2.0),
          const EqualizerBand(frequency: 125, gain: -1.0),
          const EqualizerBand(frequency: 250, gain: 3.0),
          const EqualizerBand(frequency: 500, gain: 6.0),
          const EqualizerBand(frequency: 1000, gain: 8.0),
          const EqualizerBand(frequency: 2000, gain: 8.0),
          const EqualizerBand(frequency: 4000, gain: 6.0),
          const EqualizerBand(frequency: 8000, gain: 3.0),
          const EqualizerBand(frequency: 16000, gain: 0.0),
        ];
        
      case EqualizerPreset.bass:
        return [
          const EqualizerBand(frequency: 32, gain: 10.0),
          const EqualizerBand(frequency: 64, gain: 8.0),
          const EqualizerBand(frequency: 125, gain: 6.0),
          const EqualizerBand(frequency: 250, gain: 4.0),
          const EqualizerBand(frequency: 500, gain: 2.0),
          const EqualizerBand(frequency: 1000, gain: 0.0),
          const EqualizerBand(frequency: 2000, gain: -2.0),
          const EqualizerBand(frequency: 4000, gain: -3.0),
          const EqualizerBand(frequency: 8000, gain: -4.0),
          const EqualizerBand(frequency: 16000, gain: -5.0),
        ];
        
      case EqualizerPreset.treble:
        return [
          const EqualizerBand(frequency: 32, gain: -5.0),
          const EqualizerBand(frequency: 64, gain: -4.0),
          const EqualizerBand(frequency: 125, gain: -3.0),
          const EqualizerBand(frequency: 250, gain: -2.0),
          const EqualizerBand(frequency: 500, gain: 0.0),
          const EqualizerBand(frequency: 1000, gain: 2.0),
          const EqualizerBand(frequency: 2000, gain: 4.0),
          const EqualizerBand(frequency: 4000, gain: 6.0),
          const EqualizerBand(frequency: 8000, gain: 8.0),
          const EqualizerBand(frequency: 16000, gain: 10.0),
        ];
        
      case EqualizerPreset.custom:
        return _bands; // Retourner les bandes actuelles pour custom
    }
  }

  // Modification des bandes
  Future<void> setBandGain(int bandIndex, double gain) async {
    if (bandIndex >= 0 && bandIndex < _bands.length) {
      _bands[bandIndex] = _bands[bandIndex].copyWith(gain: gain.clamp(-20.0, 20.0));
      _currentPreset = EqualizerPreset.custom;
      _presetController.add(_currentPreset);
      _bandsController.add(_bands);
      await _saveSettings();
    }
  }

  Future<void> setPreamp(double value) async {
    _preamp = value.clamp(-20.0, 20.0);
    await _saveSettings();
  }

  // Activation/Désactivation
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    _enabledController.add(enabled);
    await _saveSettings();
  }

  // Méthodes utilitaires
  String getPresetName(EqualizerPreset preset) {
    switch (preset) {
      case EqualizerPreset.flat:
        return 'Plat';
      case EqualizerPreset.rock:
        return 'Rock';
      case EqualizerPreset.pop:
        return 'Pop';
      case EqualizerPreset.jazz:
        return 'Jazz';
      case EqualizerPreset.classical:
        return 'Classique';
      case EqualizerPreset.electronic:
        return 'Électronique';
      case EqualizerPreset.hiphop:
        return 'Hip-Hop';
      case EqualizerPreset.vocal:
        return 'Vocal';
      case EqualizerPreset.bass:
        return 'Basses';
      case EqualizerPreset.treble:
        return 'Aigus';
      case EqualizerPreset.custom:
        return 'Personnalisé';
    }
  }

  String formatFrequency(double frequency) {
    if (frequency < 1000) {
      return '${frequency.toInt()} Hz';
    } else {
      return '${(frequency / 1000).toStringAsFixed(frequency >= 10000 ? 0 : 1)} kHz';
    }
  }

  String formatGain(double gain) {
    return '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)} dB';
  }

  // Analyse et recommandations
  EqualizerPreset recommendPresetForGenre(String? genre) {
    if (genre == null) return EqualizerPreset.flat;
    
    final lowerGenre = genre.toLowerCase();
    
    if (lowerGenre.contains('rock') || lowerGenre.contains('metal')) {
      return EqualizerPreset.rock;
    } else if (lowerGenre.contains('pop') || lowerGenre.contains('dance')) {
      return EqualizerPreset.pop;
    } else if (lowerGenre.contains('jazz') || lowerGenre.contains('blues')) {
      return EqualizerPreset.jazz;
    } else if (lowerGenre.contains('classical') || lowerGenre.contains('orchestral')) {
      return EqualizerPreset.classical;
    } else if (lowerGenre.contains('electronic') || lowerGenre.contains('techno') || 
               lowerGenre.contains('house')) {
      return EqualizerPreset.electronic;
    } else if (lowerGenre.contains('hip') || lowerGenre.contains('rap')) {
      return EqualizerPreset.hiphop;
    } else {
      return EqualizerPreset.flat;
    }
  }

  // Reset
  Future<void> reset() async {
    await setPreset(EqualizerPreset.flat);
    await setPreamp(0.0);
    await setEnabled(false);
  }

  // Notification des changements
  void _notifyListeners() {
    _bandsController.add(_bands);
    _presetController.add(_currentPreset);
    _enabledController.add(_isEnabled);
  }

  // Sauvegarde/Chargement (simulation)
  Future<void> _saveSettings() async {
    // Ici on sauvegarderait dans SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('equalizer_bands', jsonEncode(_bands.map((b) => b.toJson()).toList()));
    // await prefs.setString('equalizer_preset', _currentPreset.name);
    // await prefs.setBool('equalizer_enabled', _isEnabled);
    // await prefs.setDouble('equalizer_preamp', _preamp);
  }

  Future<void> _loadSettings() async {
    // final prefs = await SharedPreferences.getInstance();
    
    // Charger les bandes
    // final bandsJson = prefs.getString('equalizer_bands');
    // if (bandsJson != null) {
    //   final bandsList = jsonDecode(bandsJson) as List;
    //   _bands = bandsList.map((b) => EqualizerBand.fromJson(b)).toList();
    // }
    
    // Charger le preset
    // final presetName = prefs.getString('equalizer_preset');
    // if (presetName != null) {
    //   _currentPreset = EqualizerPreset.values.firstWhere(
    //     (p) => p.name == presetName,
    //     orElse: () => EqualizerPreset.flat,
    //   );
    // }
    
    // Charger l'état activé
    // _isEnabled = prefs.getBool('equalizer_enabled') ?? false;
    
    // Charger le préamp
    // _preamp = prefs.getDouble('equalizer_preamp') ?? 0.0;
  }

  // Nettoyage
  void dispose() {
    _bandsController.close();
    _presetController.close();
    _enabledController.close();
  }
}