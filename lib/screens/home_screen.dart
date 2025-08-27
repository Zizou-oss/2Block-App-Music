import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../models/track.dart';
import '../services/github_service.dart';
import '../services/audio_service.dart';

enum PlayerState { stopped, loading, playing, paused, error }
enum LoadingState { initial, loading, loaded, error, retry }
enum NetworkState { connected, disconnected, unknown }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Track> tracks = [];
  List<Track> filteredTracks = [];
  LoadingState _loadingState = LoadingState.initial;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _errorMessage;
  Timer? _searchDebouncer;
  NetworkState _networkState = NetworkState.unknown;
  
  // Contrôleurs pour la gestion de la performance
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;

  PlayerState _playerState = PlayerState.stopped;
  int? _currentlyPlayingIndex;
  Track? _currentTrack;
  final AudioService _audioService = AudioService();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  late AnimationController _playerController;
  late Animation<double> _playerAnimation;
  bool _isPlayerExpanded = false;

  @override
  void initState() {
    super.initState();
    _playerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _playerAnimation = CurvedAnimation(
      parent: _playerController,
      curve: Curves.easeInOutCubic,
    );

    loadTracks();
    _initializeAudioService();
    _searchController.addListener(() {
      _debouncedFilterTracks(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioService.dispose();
    _playerController.dispose();
    _searchDebouncer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _initializeAudioService() {
    _audioService.onPlayerStateChanged = (isPlaying) {
      if (mounted) {
        setState(() {
          if (_playerState != PlayerState.stopped && _playerState != PlayerState.loading) {
            _playerState = isPlaying ? PlayerState.playing : PlayerState.paused;
          }
        });
      }
    };

    _audioService.onComplete = () {
      if (mounted) {
        _stopPlayback();
      }
    };

    _audioService.onError = (error) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };

    _audioService.onDurationChanged = (duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    };

    _audioService.onPositionChanged = (position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    };
  }

  void _debouncedFilterTracks(String query) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _filterTracks(query);
    });
  }

  void _filterTracks(String query) {
    if (!mounted) return;
    
    setState(() {
      if (query.isEmpty) {
        filteredTracks = List.from(tracks);
      } else {
        // Utiliser le service optimisé pour la recherche
        filteredTracks = GithubService.searchTracks(query);
        if (filteredTracks.isEmpty) {
          // Fallback sur la recherche locale si le service ne retourne rien
          filteredTracks = tracks
              .where((track) => track.title.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        filteredTracks = List.from(tracks);
      } else {
        filteredTracks = List.from(tracks);
      }
    });
  }

  Future<void> loadTracks({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      _loadingState = LoadingState.loading;
      _errorMessage = null;
    });
    
    try {
      // Vérifier la connectivité réseau
      await _checkNetworkConnectivity();
      
      tracks = await GithubService.fetchTracks(forceRefresh: forceRefresh);
      filteredTracks = List.from(tracks);
      
      if (mounted) {
        setState(() {
          _loadingState = LoadingState.loaded;
          _networkState = NetworkState.connected;
          _retryAttempts = 0;
        });
      }
    } on SocketException catch (e) {
      _handleNetworkError('Problème de connexion: ${e.message}');
    } on TimeoutException catch (e) {
      _handleNetworkError('Délai dépassé: ${e.message ?? 'Connexion trop lente'}');
    } catch (e) {
      _handleGenericError(e.toString());
    }
  }
  
  Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('github.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('Pas de connexion internet');
      }
      _networkState = NetworkState.connected;
    } catch (e) {
      _networkState = NetworkState.disconnected;
      rethrow;
    }
  }
  
  void _handleNetworkError(String message) {
    if (!mounted) return;
    
    setState(() {
      _loadingState = LoadingState.error;
      _networkState = NetworkState.disconnected;
      _errorMessage = message;
    });
    
    _showErrorSnackBar(message, canRetry: true);
  }
  
  void _handleGenericError(String message) {
    if (!mounted) return;
    
    setState(() {
      _loadingState = LoadingState.error;
      _errorMessage = message;
    });
    
    _showErrorSnackBar('Erreur de chargement: $message');
  }
  
  void _showErrorSnackBar(String message, {bool canRetry = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: canRetry ? SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: () => _retryLoad(),
        ) : null,
      ),
    );
  }
  
  Future<void> _retryLoad() async {
    if (_retryAttempts >= _maxRetryAttempts) {
      _showErrorSnackBar('Trop de tentatives échouées. Vérifiez votre connexion.');
      return;
    }
    
    _retryAttempts++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: _retryAttempts * 2), () {
      loadTracks(forceRefresh: true);
    });
  }

  Future<void> _startPlayback(Track track, int index) async {
    // Validation des entrées
    if (!track.isValidUrl) {
      _showErrorSnackBar('URL invalide pour ce track');
      return;
    }
    
    if (_currentlyPlayingIndex == index && _currentTrack?.url == track.url) {
      await _togglePlayback();
      return;
    }

    // Vérifier la connectivité avant de commencer
    if (_networkState == NetworkState.disconnected) {
      try {
        await _checkNetworkConnectivity();
      } catch (e) {
        _showErrorSnackBar('Pas de connexion internet', canRetry: true);
        return;
      }
    }

    setState(() {
      _playerState = PlayerState.loading;
      _currentlyPlayingIndex = index;
      _currentTrack = track;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });

    try {
      await _audioService.stop();
      if (kDebugMode) {
        print('Playing URL: ${track.url}');
      }
      await _audioService.play(track.url);
      
      if (mounted) {
        setState(() {
          _playerState = _audioService.isPlaying() ? PlayerState.playing : PlayerState.paused;
        });
      }
    } on SocketException catch (e) {
      _handlePlaybackNetworkError('Problème de réseau: ${e.message}');
    } on TimeoutException catch (e) {
      _handlePlaybackNetworkError('Délai dépassé: ${e.message ?? 'Chargement trop lent'}');
    } catch (e) {
      _handlePlaybackError('Erreur de lecture: $e');
    }
  }
  
  void _handlePlaybackNetworkError(String message) {
    if (!mounted) return;
    
    setState(() {
      _playerState = PlayerState.error;
      _networkState = NetworkState.disconnected;
    });
    
    _showErrorSnackBar(message, canRetry: true);
  }
  
  void _handlePlaybackError(String message) {
    if (!mounted) return;
    
    setState(() {
      _playerState = PlayerState.error;
      _currentlyPlayingIndex = null;
      _currentTrack = null;
    });
    
    _showErrorSnackBar(message);
  }

  Future<void> _togglePlayback() async {
    if (_currentTrack == null || _playerState == PlayerState.loading) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _audioService.pause();
        setState(() {
          _playerState = PlayerState.paused;
        });
      } else if (_playerState == PlayerState.paused) {
        await _audioService.resume();
        setState(() {
          _playerState = PlayerState.playing;
        });
      }
    } catch (e) {
      setState(() {
        _playerState = PlayerState.error;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du contrôle: $e')),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _audioService.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _currentlyPlayingIndex = null;
      _currentTrack = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
    if (_isPlayerExpanded) {
      _togglePlayerExpansion();
    }
  }

  void _togglePlayerExpansion() {
    setState(() {
      _isPlayerExpanded = !_isPlayerExpanded;
    });
    if (_isPlayerExpanded) {
      _playerController.forward();
    } else {
      _playerController.reverse();
    }
  }

  bool get _shouldShowMiniPlayer => _playerState != PlayerState.stopped && _currentTrack != null;

  IconData get _playPauseIcon {
    switch (_playerState) {
      case PlayerState.loading:
        return Icons.hourglass_empty;
      case PlayerState.playing:
        return Icons.pause;
      case PlayerState.paused:
      case PlayerState.error:
        return Icons.play_arrow;
      default:
        return Icons.play_arrow;
    }
  }

  String get _statusText {
    switch (_playerState) {
      case PlayerState.loading:
        return 'Chargement...';
      case PlayerState.playing:
        return 'Lecture';
      case PlayerState.paused:
        return 'Pause';
      case PlayerState.error:
        return 'Erreur';
      default:
        return '';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: (value * _totalDuration.inMilliseconds).round());
    _audioService.seek(position);
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _isPlayerExpanded
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un titre...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    )
                  : const Text(
                      '2Block Musique',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: _toggleSearch,
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF212121),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1DB954), Color(0xFF191414)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paramètres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Personnalisez votre expérience',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF1DB954)),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.equalizer, color: Color(0xFF1DB954)),
              title: const Text('Égaliseur', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF1DB954)),
              title: const Text('À propos', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.call, color: Color(0xFF1DB954)),
              title: const Text('Contact', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (!_isPlayerExpanded)
            _buildMainContent(),
          if (_shouldShowMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _playerAnimation,
                builder: (context, child) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final expandedHeight = screenHeight - MediaQuery.of(context).padding.top;
                  final minHeight = 90.0;
                  final currentHeight = minHeight + (expandedHeight - minHeight) * _playerAnimation.value;
                  return Container(
                    height: currentHeight,
                    decoration: BoxDecoration(
                      color: _isPlayerExpanded ? const Color(0xFF121212) : const Color(0xFF212121),
                      borderRadius:
                          _isPlayerExpanded ? null : const BorderRadius.vertical(top: Radius.circular(0)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
                      ],
                    ),
                    child: _isPlayerExpanded ? _buildExpandedPlayer() : _buildMiniPlayer(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return GestureDetector(
      onTap: _togglePlayerExpansion,
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) _togglePlayerExpansion();
      },
      child: Column(
        children: [
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              backgroundColor: const Color(0xFF1DB954).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
              value: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                  : 0.0,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _playerState == PlayerState.playing
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1DB954).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _currentTrack!.imageUrl.isNotEmpty
                          ? Image.network(
                              _currentTrack!.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentTrack!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Color(0xFF1DB954),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _playerState == PlayerState.loading
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(_playPauseIcon, color: const Color(0xFF1DB954), size: 24),
                              onPressed: _playerState != PlayerState.loading ? _togglePlayback : null,
                            ),
                      const Icon(Icons.keyboard_arrow_up, color: Colors.grey, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPlayer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                onPressed: _togglePlayerExpansion,
              ),
              const Text(
                'Lecture en cours',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _currentTrack!.imageUrl.isNotEmpty
                          ? Image.network(
                              _currentTrack!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 80),
                              ),
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 80),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        _currentTrack!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusText,
                        style: const TextStyle(
                          color: Color(0xFF1DB954),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF1DB954),
                          inactiveTrackColor: Colors.grey[800],
                          thumbColor: const Color(0xFF1DB954),
                          overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _totalDuration.inMilliseconds > 0
                              ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                              : 0.0,
                          onChanged: (value) => _seekTo(value),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.grey, size: 36),
                        onPressed: null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white70, size: 32),
                        onPressed: () {
                          final newPosition = Duration(
                            milliseconds: (_currentPosition.inMilliseconds - 10000)
                                .clamp(0, _totalDuration.inMilliseconds),
                          );
                          _seekTo(newPosition.inMilliseconds / _totalDuration.inMilliseconds);
                        },
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                        child: _playerState == PlayerState.loading
                            ? const Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: Icon(_playPauseIcon, color: Colors.white, size: 36),
                                onPressed: _playerState != PlayerState.loading ? _togglePlayback : null,
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white70, size: 32),
                        onPressed: () {
                          final newPosition = Duration(
                            milliseconds: (_currentPosition.inMilliseconds + 10000)
                                .clamp(0, _totalDuration.inMilliseconds),
                          );
                          _seekTo(newPosition.inMilliseconds / _totalDuration.inMilliseconds);
                        },
                      ),
                      const IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.grey, size: 36),
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Colors.white70, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white70, size: 24),
                        onPressed: _stopPlayback,
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: Colors.white70, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white70, size: 24),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_loadingState) {
      case LoadingState.initial:
      case LoadingState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1DB954)),
              SizedBox(height: 16),
              Text(
                'Chargement des pistes...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      
      case LoadingState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _networkState == NetworkState.disconnected 
                    ? Icons.wifi_off 
                    : Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Une erreur est survenue',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => loadTracks(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_networkState == NetworkState.disconnected) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      try {
                        await _checkNetworkConnectivity();
                        loadTracks(forceRefresh: true);
                      } catch (e) {
                        _showErrorSnackBar('Toujours pas de connexion');
                      }
                    },
                    child: const Text(
                      'Vérifier la connexion',
                      style: TextStyle(color: Color(0xFF1DB954)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      
      case LoadingState.loaded:
        return RefreshIndicator(
          color: const Color(0xFF1DB954),
          onRefresh: () => loadTracks(forceRefresh: true),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (!_isSearching || (_isSearching && _searchController.text.isEmpty))
                SliverToBoxAdapter(
                  child: Container(
                    height: 180,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1DB954), Color(0xFF191414)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ma Collection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${tracks.length} titres disponibles',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              if (tracks.isNotEmpty) {
                                _startPlayback(tracks[0], 0);
                              }
                            },
                            child: const Text('Écouter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isSearching && _searchController.text.isNotEmpty
                              ? 'Résultats pour "${_searchController.text}"'
                              : 'Tous les titres',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_networkState == NetworkState.disconnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Hors ligne',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isSearching && _searchController.text.isNotEmpty && filteredTracks.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, color: Colors.grey, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Aucun titre trouvé',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = filteredTracks[index];
                    final bool isCurrentTrack =
                        _currentlyPlayingIndex == index && _currentTrack?.url == track.url;
                    return _buildTrackListItem(track, index, isCurrentTrack);
                  },
                  childCount: filteredTracks.length,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: _shouldShowMiniPlayer ? 140 : 80)),
            ],
          ),
        );
      
      case LoadingState.retry:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1DB954)),
              SizedBox(height: 16),
              Text(
                'Nouvelle tentative...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTrackListItem(Track track, int index, bool isCurrentTrack) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentTrack ? const Color(0xFF2A2A2A) : const Color(0xFF212121),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTrack
            ? Border.all(color: const Color(0xFF1DB954), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.imageUrl.isNotEmpty
                  ? Image.network(
                      track.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingImage();
                      },
                    )
                  : _buildDefaultImage(),
            ),
            if (isCurrentTrack)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.volume_up
                          : _playerState == PlayerState.loading
                              ? Icons.hourglass_empty
                              : Icons.pause,
                      color: const Color(0xFF1DB954),
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          track.title,
          style: TextStyle(
            color: isCurrentTrack ? const Color(0xFF1DB954) : Colors.white,
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          isCurrentTrack ? _statusText : 'Appuyez pour écouter',
          style: TextStyle(
            color: isCurrentTrack ? const Color(0xFF1DB954) : Colors.grey,
            fontSize: 12,
          ),
        ),
        onTap: () => _startPlayback(track, index),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[800],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
          ),
        ),
      ),
    );
  }
}