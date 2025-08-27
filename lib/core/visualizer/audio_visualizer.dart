import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

enum VisualizerType {
  bars,
  wave,
  circle,
  spectrum,
  particle,
  ripple,
  flow,
  pulse
}

class AudioData {
  final List<double> frequencies;
  final double amplitude;
  final double bass;
  final double midrange;
  final double treble;
  final DateTime timestamp;

  const AudioData({
    required this.frequencies,
    required this.amplitude,
    required this.bass,
    required this.midrange,
    required this.treble,
    required this.timestamp,
  });

  factory AudioData.empty() {
    return AudioData(
      frequencies: List.filled(64, 0.0),
      amplitude: 0.0,
      bass: 0.0,
      midrange: 0.0,
      treble: 0.0,
      timestamp: DateTime.now(),
    );
  }

  factory AudioData.mock() {
    final random = math.Random();
    return AudioData(
      frequencies: List.generate(64, (i) => random.nextDouble() * 0.8),
      amplitude: random.nextDouble() * 0.7,
      bass: random.nextDouble() * 0.6,
      midrange: random.nextDouble() * 0.8,
      treble: random.nextDouble() * 0.5,
      timestamp: DateTime.now(),
    );
  }
}

class AudioVisualizerService {
  static final AudioVisualizerService _instance = AudioVisualizerService._internal();
  factory AudioVisualizerService() => _instance;
  AudioVisualizerService._internal();

  final StreamController<AudioData> _audioDataController = 
      StreamController<AudioData>.broadcast();
  
  Timer? _mockDataTimer;
  bool _isAnalyzing = false;
  bool _isMockMode = true; // Pour la simulation

  Stream<AudioData> get audioDataStream => _audioDataController.stream;
  bool get isAnalyzing => _isAnalyzing;

  // Démarrer l'analyse audio
  Future<void> startAnalysis() async {
    if (_isAnalyzing) return;
    
    _isAnalyzing = true;
    
    if (_isMockMode) {
      _startMockAnalysis();
    } else {
      _startRealAnalysis();
    }
  }

  // Arrêter l'analyse
  Future<void> stopAnalysis() async {
    _isAnalyzing = false;
    _mockDataTimer?.cancel();
    _mockDataTimer = null;
  }

  // Simulation d'analyse audio
  void _startMockAnalysis() {
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isAnalyzing) {
        timer.cancel();
        return;
      }
      
      _audioDataController.add(AudioData.mock());
    });
  }

  // Vraie analyse audio (à implémenter avec un plugin approprié)
  void _startRealAnalysis() {
    // Ici on intégrerait un plugin d'analyse audio réel
    // comme audio_spectrum_analyzer ou similar
  }

  void dispose() {
    stopAnalysis();
    _audioDataController.close();
  }
}

// Widget de visualisation principal
class AudioVisualizerWidget extends StatefulWidget {
  final VisualizerType type;
  final Color primaryColor;
  final Color? secondaryColor;
  final double height;
  final double width;
  final bool isPlaying;
  final EdgeInsets padding;

  const AudioVisualizerWidget({
    super.key,
    this.type = VisualizerType.bars,
    this.primaryColor = Colors.blue,
    this.secondaryColor,
    this.height = 100,
    this.width = double.infinity,
    this.isPlaying = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  AudioData _currentData = AudioData.empty();
  StreamSubscription<AudioData>? _audioSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    if (widget.isPlaying) {
      _startListening();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startListening();
      } else {
        _stopListening();
      }
    }
  }

  void _startListening() {
    _audioSubscription = AudioVisualizerService().audioDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentData = data;
        });
        _animationController.forward(from: 0);
      }
    });

    AudioVisualizerService().startAnalysis();
  }

  void _stopListening() {
    _audioSubscription?.cancel();
    _audioSubscription = null;
    AudioVisualizerService().stopAnalysis();
    
    if (mounted) {
      setState(() {
        _currentData = AudioData.empty();
      });
    }
  }

  @override
  void dispose() {
    _stopListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _getVisualizerPainter(),
            size: Size(widget.width, widget.height),
          );
        },
      ),
    );
  }

  CustomPainter _getVisualizerPainter() {
    switch (widget.type) {
      case VisualizerType.bars:
        return BarVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          animation: _animationController,
        );
      case VisualizerType.wave:
        return WaveVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
      case VisualizerType.circle:
        return CircleVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
      case VisualizerType.spectrum:
        return SpectrumVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
      case VisualizerType.particle:
        return ParticleVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
      case VisualizerType.ripple:
        return RippleVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
      case VisualizerType.flow:
        return FlowVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
      case VisualizerType.pulse:
        return PulseVisualizerPainter(
          audioData: _currentData,
          primaryColor: widget.primaryColor,
          animation: _animationController,
        );
    }
  }
}

// Painter pour barres verticales
class BarVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Color? secondaryColor;
  final Animation<double> animation;

  BarVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    this.secondaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final barCount = audioData.frequencies.length ~/ 2; // Réduire le nombre de barres
    final barWidth = size.width / barCount;
    final maxHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      final frequency = audioData.frequencies[i * 2];
      final animatedHeight = frequency * maxHeight * animation.value;
      
      // Gradient de couleur basé sur la fréquence
      final colorIntensity = (frequency * animation.value).clamp(0.0, 1.0);
      paint.color = Color.lerp(
        primaryColor.withOpacity(0.3),
        secondaryColor ?? primaryColor,
        colorIntensity,
      )!;

      final rect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.1,
        size.height - animatedHeight,
        barWidth * 0.8,
        animatedHeight,
      );

      // Coins arrondis
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth * 0.1),
      );

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter pour forme d'onde
class WaveVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  WaveVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final centerY = size.height / 2;
    final amplitude = centerY * 0.8;

    path.moveTo(0, centerY);

    for (int i = 0; i < audioData.frequencies.length; i++) {
      final x = (i / audioData.frequencies.length) * size.width;
      final frequency = audioData.frequencies[i];
      final y = centerY + (frequency * amplitude * animation.value * 
                          math.sin(i * 0.1 + animation.value * math.pi * 2));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Effet de gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withOpacity(0.1),
        primaryColor.withOpacity(0.3),
      ],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, centerY);
    fillPath.lineTo(0, centerY);
    fillPath.close();

    canvas.drawPath(fillPath, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter circulaire
class CircleVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  CircleVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.2;
    final maxRadius = math.min(size.width, size.height) * 0.4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Cercle de base
    paint.color = primaryColor.withOpacity(0.3);
    canvas.drawCircle(center, baseRadius, paint);

    // Barres circulaires
    final angleStep = (2 * math.pi) / audioData.frequencies.length;
    
    for (int i = 0; i < audioData.frequencies.length; i++) {
      final frequency = audioData.frequencies[i];
      final angle = i * angleStep;
      final radius = baseRadius + (frequency * (maxRadius - baseRadius) * animation.value);
      
      final startX = center.dx + math.cos(angle) * baseRadius;
      final startY = center.dy + math.sin(angle) * baseRadius;
      final endX = center.dx + math.cos(angle) * radius;
      final endY = center.dy + math.sin(angle) * radius;

      paint.color = primaryColor.withOpacity(0.5 + frequency * 0.5);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Cercle central pulsant
    final pulseRadius = baseRadius * 0.5 * (1 + audioData.amplitude * animation.value);
    paint.color = primaryColor;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter pour le spectre
class SpectrumVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  SpectrumVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    final gradient = RadialGradient(
      colors: [
        primaryColor.withOpacity(0.8),
        primaryColor.withOpacity(0.2),
      ],
    );

    for (int i = 0; i < audioData.frequencies.length; i++) {
      final frequency = audioData.frequencies[i];
      final x = (i / audioData.frequencies.length) * size.width;
      final radius = frequency * 20 * animation.value;
      
      paint.shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, size.height / 2), radius: radius),
      );

      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter pour particules
class ParticleVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  ParticleVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Seed fixe pour la cohérence

    for (int i = 0; i < audioData.frequencies.length; i++) {
      final frequency = audioData.frequencies[i];
      if (frequency < 0.1) continue;

      final particleCount = (frequency * 10).round();
      
      for (int j = 0; j < particleCount; j++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final radius = frequency * 5 * animation.value;
        
        paint.color = primaryColor.withOpacity(frequency * animation.value);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painters pour les autres types...
class RippleVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  RippleVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rippleCount = 5;
    final maxRadius = math.min(size.width, size.height) * 0.5;

    for (int i = 0; i < rippleCount; i++) {
      final progress = (animation.value + i * 0.2) % 1.0;
      final radius = maxRadius * progress * audioData.amplitude;
      final opacity = (1.0 - progress) * audioData.amplitude;

      paint.color = primaryColor.withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FlowVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  FlowVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < audioData.frequencies.length ~/ 4; i++) {
      final frequency = audioData.frequencies[i * 4];
      final path = Path();
      
      final startX = (i / (audioData.frequencies.length / 4)) * size.width;
      final amplitude = frequency * size.height * 0.3 * animation.value;
      
      path.moveTo(startX, size.height / 2);
      
      for (double t = 0; t <= 1; t += 0.02) {
        final x = startX + t * size.width * 0.1;
        final y = size.height / 2 + 
                  amplitude * math.sin(t * math.pi * 4 + animation.value * math.pi * 2);
        path.lineTo(x, y);
      }

      paint.color = primaryColor.withOpacity(frequency * animation.value);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PulseVisualizerPainter extends CustomPainter {
  final AudioData audioData;
  final Color primaryColor;
  final Animation<double> animation;

  PulseVisualizerPainter({
    required this.audioData,
    required this.primaryColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.1;
    
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Pulse principal
    final mainPulse = baseRadius * (1 + audioData.amplitude * 2 * animation.value);
    paint.color = primaryColor.withOpacity(0.8);
    canvas.drawCircle(center, mainPulse, paint);

    // Pulses secondaires
    final secondaryPulse = baseRadius * (0.5 + audioData.bass * animation.value);
    paint.color = primaryColor.withOpacity(0.4);
    canvas.drawCircle(center, secondaryPulse, paint);

    // Pulse externe
    final externalPulse = baseRadius * (2 + audioData.treble * animation.value);
    paint.color = primaryColor.withOpacity(0.2);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    canvas.drawCircle(center, externalPulse, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}