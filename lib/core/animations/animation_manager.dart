import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;

enum AnimationType {
  fadeIn,
  fadeOut,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scaleUp,
  scaleDown,
  rotate,
  bounce,
  elastic,
  wave,
  pulse,
  shake,
  flip,
  morphing
}

enum AnimationSpeed { slow, normal, fast, custom }

class AnimationConfig {
  final AnimationType type;
  final Duration duration;
  final Curve curve;
  final double? value;
  final Offset? offset;
  final bool repeat;
  final bool reverse;

  const AnimationConfig({
    required this.type,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.value,
    this.offset,
    this.repeat = false,
    this.reverse = false,
  });
}

class AnimationManager {
  static const Map<AnimationSpeed, Duration> _speedDurations = {
    AnimationSpeed.slow: Duration(milliseconds: 800),
    AnimationSpeed.normal: Duration(milliseconds: 300),
    AnimationSpeed.fast: Duration(milliseconds: 150),
  };

  static Duration getDuration(AnimationSpeed speed, {Duration? custom}) {
    if (speed == AnimationSpeed.custom && custom != null) {
      return custom;
    }
    return _speedDurations[speed] ?? _speedDurations[AnimationSpeed.normal]!;
  }

  // Animations de base
  static Widget fadeIn({
    required Widget child,
    AnimationSpeed speed = AnimationSpeed.normal,
    Duration? customDuration,
    Curve curve = Curves.easeIn,
    VoidCallback? onComplete,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: getDuration(speed, custom: customDuration),
      curve: curve,
      onEnd: onComplete,
      child: child,
    );
  }

  static Widget slideUp({
    required Widget child,
    AnimationSpeed speed = AnimationSpeed.normal,
    Duration? customDuration,
    Curve curve = Curves.easeOutCubic,
    double distance = 50.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: distance, end: 0.0),
      duration: getDuration(speed, custom: customDuration),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget scaleIn({
    required Widget child,
    AnimationSpeed speed = AnimationSpeed.normal,
    Duration? customDuration,
    Curve curve = Curves.elasticOut,
    double fromScale = 0.0,
    double toScale = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: fromScale, end: toScale),
      duration: getDuration(speed, custom: customDuration),
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

// Widget d'animation personnalisé
class CustomAnimatedWidget extends StatefulWidget {
  final Widget child;
  final AnimationConfig config;
  final VoidCallback? onComplete;

  const CustomAnimatedWidget({
    super.key,
    required this.child,
    required this.config,
    this.onComplete,
  });

  @override
  State<CustomAnimatedWidget> createState() => _CustomAnimatedWidgetState();
}

class _CustomAnimatedWidgetState extends State<CustomAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.config.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.config.curve,
    );

    if (widget.config.repeat) {
      _controller.repeat(reverse: widget.config.reverse);
    } else {
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildAnimatedWidget();
      },
      child: widget.child,
    );
  }

  Widget _buildAnimatedWidget() {
    switch (widget.config.type) {
      case AnimationType.fadeIn:
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );

      case AnimationType.fadeOut:
        return Opacity(
          opacity: 1.0 - _animation.value,
          child: widget.child,
        );

      case AnimationType.slideUp:
        return Transform.translate(
          offset: Offset(0, (1.0 - _animation.value) * 50),
          child: widget.child,
        );

      case AnimationType.slideDown:
        return Transform.translate(
          offset: Offset(0, (_animation.value - 1.0) * 50),
          child: widget.child,
        );

      case AnimationType.slideLeft:
        return Transform.translate(
          offset: Offset((1.0 - _animation.value) * 50, 0),
          child: widget.child,
        );

      case AnimationType.slideRight:
        return Transform.translate(
          offset: Offset((_animation.value - 1.0) * 50, 0),
          child: widget.child,
        );

      case AnimationType.scaleUp:
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );

      case AnimationType.scaleDown:
        return Transform.scale(
          scale: 1.0 - _animation.value,
          child: widget.child,
        );

      case AnimationType.rotate:
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: widget.child,
        );

      case AnimationType.bounce:
        return Transform.translate(
          offset: Offset(0, math.sin(_animation.value * math.pi) * -20),
          child: widget.child,
        );

      case AnimationType.elastic:
        final elasticValue = math.sin(_animation.value * math.pi * 2) * 
                           math.exp(-_animation.value * 3);
        return Transform.scale(
          scale: 1.0 + elasticValue * 0.1,
          child: widget.child,
        );

      case AnimationType.wave:
        return Transform.translate(
          offset: Offset(math.sin(_animation.value * math.pi * 4) * 10, 0),
          child: widget.child,
        );

      case AnimationType.pulse:
        final pulse = 1.0 + math.sin(_animation.value * math.pi * 2) * 0.1;
        return Transform.scale(
          scale: pulse,
          child: widget.child,
        );

      case AnimationType.shake:
        final shake = math.sin(_animation.value * math.pi * 8) * 5;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: widget.child,
        );

      case AnimationType.flip:
        final angle = _animation.value * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: widget.child,
        );

      case AnimationType.morphing:
        return Transform.scale(
          scale: 1.0 + math.sin(_animation.value * math.pi) * 0.2,
          child: Transform.rotate(
            angle: _animation.value * 0.1,
            child: widget.child,
          ),
        );
    }
  }
}

// Animations de page
class PageTransitionAnimations {
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.right,
  }) {
    Offset begin;
    switch (direction) {
      case SlideDirection.up:
        begin = const Offset(0.0, 1.0);
        break;
      case SlideDirection.down:
        begin = const Offset(0.0, -1.0);
        break;
      case SlideDirection.left:
        begin = const Offset(1.0, 0.0);
        break;
      case SlideDirection.right:
        begin = const Offset(-1.0, 0.0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      )),
      child: child,
    );
  }

  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.elasticOut,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }

  static Widget rotationTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  static Widget morphTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation.value),
          child: Transform.rotate(
            angle: (1 - animation.value) * 0.5,
            child: Opacity(
              opacity: animation.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

enum SlideDirection { up, down, left, right }

// Animations de listes
class ListAnimations {
  static Widget staggeredListAnimation({
    required List<Widget> children,
    Duration duration = const Duration(milliseconds: 100),
    Duration delay = const Duration(milliseconds: 50),
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration + (delay * index),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 50),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }
}

// Animations de chargement
class LoadingAnimations {
  static Widget pulsingDots({
    Color color = Colors.blue,
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            final animatedValue = math.sin((value + index * 0.3) * math.pi * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3 + (animatedValue * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  static Widget rotatingIcon({
    required IconData icon,
    Color color = Colors.blue,
    double size = 24.0,
    Duration duration = const Duration(seconds: 1),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * math.pi,
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        );
      },
    );
  }
}

// Gestionnaire d'animations global
class GlobalAnimationManager {
  static bool _animationsEnabled = true;
  static AnimationSpeed _globalSpeed = AnimationSpeed.normal;

  static bool get animationsEnabled => _animationsEnabled;
  static AnimationSpeed get globalSpeed => _globalSpeed;

  static void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
  }

  static void setGlobalSpeed(AnimationSpeed speed) {
    _globalSpeed = speed;
  }

  static Duration getAdjustedDuration(Duration original) {
    if (!_animationsEnabled) return Duration.zero;
    
    switch (_globalSpeed) {
      case AnimationSpeed.slow:
        return Duration(milliseconds: (original.inMilliseconds * 1.5).round());
      case AnimationSpeed.normal:
        return original;
      case AnimationSpeed.fast:
        return Duration(milliseconds: (original.inMilliseconds * 0.5).round());
      case AnimationSpeed.custom:
        return original;
    }
  }
}