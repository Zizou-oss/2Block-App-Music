import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

// Imports des nouveaux systèmes
import '../models/track.dart';
import '../models/playlist.dart';
import '../services/github_service.dart';
import '../services/playlist_service.dart';
import '../core/audio/advanced_audio_service.dart';
import '../core/audio/equalizer_service.dart';
import '../core/theme/theme_provider.dart';
import '../core/animations/animation_manager.dart';
import '../core/visualizer/audio_visualizer.dart';

enum ViewMode { list, grid, cards, minimal }
enum SortBy { title, artist, album, duration, dateAdded, playCount }

class MasterclassHomeScreen extends StatefulWidget {
  const MasterclassHomeScreen({super.key});

  @override
  State<MasterclassHomeScreen> createState() => _MasterclassHomeScreenState();
}

class _MasterclassHomeScreenState extends State<MasterclassHomeScreen>
    with TickerProviderStateMixin {
  
  // Services
  final AdvancedAudioService _audioService = AdvancedAudioService();
  final PlaylistService _playlistService = PlaylistService();
  final EqualizerService _equalizerService = EqualizerService();
  
  // État des données
  List<Track> tracks = [];
  List<Track> filteredTracks = [];
  List<Playlist> playlists = [];
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;
  
  // État de l'interface
  bool _isSearching = false;
  ViewMode _viewMode = ViewMode.list;
  SortBy _sortBy = SortBy.title;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  
  // État du lecteur
  PlayerState _playerState = PlayerState.stopped;
  int? _currentlyPlayingIndex;
  Track? _currentTrack;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Contrôleurs d'animation
  late AnimationController _playerController;
  late AnimationController _searchController;
  late AnimationController _fabController;
  late Animation<double> _playerAnimation;
  late Animation<double> _searchAnimation;
  late Animation<double> _fabAnimation;
  
  // État de l'interface
  bool _isPlayerExpanded = false;
  bool _showVisualizer = true;
  bool _isGridView = false;
  bool _showPlayerQueue = false;
  
  // Gestion de la recherche avec debouncing
  Timer? _searchDebouncer;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;
  
  // État réseau
  NetworkState _networkState = NetworkState.unknown;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
    _setupSearchListener();
    _loadData();
  }

  void _initializeControllers() {
    _playerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _playerAnimation = CurvedAnimation(
      parent: _playerController,
      curve: Curves.easeInOutCubic,
    );
    
    _searchAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeOut,
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _initializeServices() async {
    await _audioService.initializeAdvanced();
    await _playlistService.initialize();
    await _equalizerService.initialize();
    
    _setupAudioServiceListeners();
  }

  void _setupAudioServiceListeners() {
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
        _handleTrackComplete();
      }
    };

    _audioService.onError = (error) {
      if (mounted) {
        _handleAudioError(error);
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

  void _setupSearchListener() {
    _searchController.addListener(() {
      _debouncedFilterTracks(_searchController.text);
    });
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
        filteredTracks = GithubService.searchTracks(query);
        if (filteredTracks.isEmpty) {
          filteredTracks = tracks
              .where((track) => 
                track.title.toLowerCase().contains(query.toLowerCase()) ||
                track.artist.toLowerCase().contains(query.toLowerCase()) ||
                track.album.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      }
      _applySorting();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _loadingState = LoadingState.loading;
      _errorMessage = null;
    });
    
    try {
      await _checkNetworkConnectivity();
      
      tracks = await GithubService.fetchTracks();
      playlists = await _playlistService.playlists;
      filteredTracks = List.from(tracks);
      
      _applySorting();
      
      if (mounted) {
        setState(() {
          _loadingState = LoadingState.loaded;
          _networkState = NetworkState.connected;
          _retryAttempts = 0;
        });
        
        _fabController.forward();
      }
    } on SocketException catch (e) {
      _handleNetworkError('Problème de connexion: ${e.message}');
    } on TimeoutException catch (e) {
      _handleNetworkError('Délai dépassé: ${e.message ?? 'Connexion trop lente'}');
    } catch (e) {
      _handleGenericError(e.toString());
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case SortBy.title:
        filteredTracks.sort((a, b) => _sortAscending 
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case SortBy.artist:
        filteredTracks.sort((a, b) => _sortAscending 
            ? a.artist.compareTo(b.artist)
            : b.artist.compareTo(a.artist));
        break;
      case SortBy.album:
        filteredTracks.sort((a, b) => _sortAscending 
            ? a.album.compareTo(b.album)
            : b.album.compareTo(a.album));
        break;
      case SortBy.duration:
        filteredTracks.sort((a, b) => _sortAscending 
            ? a.duration.compareTo(b.duration)
            : b.duration.compareTo(a.duration));
        break;
      case SortBy.dateAdded:
        filteredTracks.sort((a, b) => _sortAscending 
            ? a.dateAdded.compareTo(b.dateAdded)
            : b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortBy.playCount:
        filteredTracks.sort((a, b) => _sortAscending 
            ? a.playCount.compareTo(b.playCount)
            : b.playCount.compareTo(a.playCount));
        break;
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
    
    _showErrorSnackBar('Erreur: $message');
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
      _loadData();
    });
  }

  Future<void> _startPlayback(Track track, int index) async {
    if (!track.isValidUrl) {
      _showErrorSnackBar('URL invalide pour ce track');
      return;
    }
    
    if (_currentlyPlayingIndex == index && _currentTrack?.url == track.url) {
      await _togglePlayback();
      return;
    }

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
      
      // Configurer la queue de lecture
      final trackUrls = filteredTracks.map((t) => t.url).toList();
      await _audioService.setPlayQueue(trackUrls, startIndex: index);
      
      if (kDebugMode) {
        print('Playing: ${track.title} by ${track.artist}');
      }
      
      await _audioService.play(track.url);
      
      // Mettre à jour les statistiques
      final updatedTrack = track.markAsPlayed();
      await _playlistService.updateTrackStats(updatedTrack);
      
      if (mounted) {
        setState(() {
          _playerState = _audioService.isPlaying() ? PlayerState.playing : PlayerState.paused;
          _currentTrack = updatedTrack;
        });
      }
    } catch (e) {
      _handlePlaybackError('Erreur de lecture: $e');
    }
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
      _handlePlaybackError('Erreur lors du contrôle: $e');
    }
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

  void _handleTrackComplete() {
    if (_audioService.hasNext) {
      _audioService.playNext();
    } else {
      setState(() {
        _playerState = PlayerState.stopped;
        _currentlyPlayingIndex = null;
        _currentTrack = null;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });
    }
  }

  void _handleAudioError(String error) {
    setState(() {
      _playerState = PlayerState.error;
    });
    _showErrorSnackBar('Erreur audio: $error');
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        filteredTracks = List.from(tracks);
        _searchController.reverse();
      } else {
        _searchController.forward();
      }
    });
  }

  void _togglePlayerExpansion() {
    setState(() {
      _isPlayerExpanded = !_isPlayerExpanded;
    });
    
    if (_isPlayerExpanded) {
      _playerController.forward();
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    } else {
      _playerController.reverse();
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  void _changeViewMode(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  void _changeSorting(SortBy sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _applySorting();
    });
  }

  Future<void> _toggleFavorite(Track track) async {
    await _playlistService.toggleFavorite(track);
    // Mettre à jour l'affichage si nécessaire
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioService.dispose();
    _playerController.dispose();
    _searchController.dispose();
    _fabController.dispose();
    _searchDebouncer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (!_isPlayerExpanded)
            _buildMainInterface(),
          if (_shouldShowMiniPlayer)
            _buildPlayerInterface(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildMainInterface() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        _buildContent(),
        SliverToBoxAdapter(
          child: SizedBox(height: _shouldShowMiniPlayer ? 140 : 80),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: _isSearching
            ? AnimatedBuilder(
                animation: _searchAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _searchAnimation.value,
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  );
                },
              )
            : const Text('2Block Musique'),
        background: _buildHeaderBackground(),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
        _buildViewModeButton(),
        _buildSortButton(),
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: _showVisualizer && _playerState == PlayerState.playing
          ? AudioVisualizerWidget(
              type: VisualizerType.wave,
              primaryColor: Colors.white.withOpacity(0.3),
              height: 200,
              isPlaying: _playerState == PlayerState.playing,
            )
          : null,
    );
  }

  Widget _buildContent() {
    switch (_loadingState) {
      case LoadingState.initial:
      case LoadingState.loading:
        return SliverFillRemaining(
          child: Center(
            child: CustomAnimatedWidget(
              config: const AnimationConfig(
                type: AnimationType.pulse,
                duration: Duration(seconds: 1),
                repeat: true,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text('Chargement des pistes...'),
                ],
              ),
            ),
          ),
        );
      
      case LoadingState.error:
        return SliverFillRemaining(
          child: _buildErrorState(),
        );
      
      case LoadingState.loaded:
        return _buildTracksList();
      
      case LoadingState.retry:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text('Nouvelle tentative...'),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildErrorState() {
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
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList() {
    if (filteredTracks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _isSearching 
                    ? 'Aucun résultat trouvé'
                    : 'Aucune piste disponible',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    switch (_viewMode) {
      case ViewMode.list:
        return _buildListView();
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.cards:
        return _buildCardsView();
      case ViewMode.minimal:
        return _buildMinimalView();
    }
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = filteredTracks[index];
          final isCurrentTrack = _currentlyPlayingIndex == index && 
                                 _currentTrack?.url == track.url;
          
          return CustomAnimatedWidget(
            config: AnimationConfig(
              type: AnimationType.slideUp,
              duration: Duration(milliseconds: 200 + (index * 50)),
            ),
            child: _buildTrackListItem(track, index, isCurrentTrack),
          );
        },
        childCount: filteredTracks.length,
      ),
    );
  }

  Widget _buildGridView() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = filteredTracks[index];
          final isCurrentTrack = _currentlyPlayingIndex == index && 
                                 _currentTrack?.url == track.url;
          
          return CustomAnimatedWidget(
            config: AnimationConfig(
              type: AnimationType.scaleUp,
              duration: Duration(milliseconds: 300 + (index * 30)),
            ),
            child: _buildTrackGridItem(track, index, isCurrentTrack),
          );
        },
        childCount: filteredTracks.length,
      ),
    );
  }

  Widget _buildCardsView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = filteredTracks[index];
          final isCurrentTrack = _currentlyPlayingIndex == index && 
                                 _currentTrack?.url == track.url;
          
          return CustomAnimatedWidget(
            config: AnimationConfig(
              type: AnimationType.fadeIn,
              duration: Duration(milliseconds: 150 + (index * 25)),
            ),
            child: _buildTrackCard(track, index, isCurrentTrack),
          );
        },
        childCount: filteredTracks.length,
      ),
    );
  }

  Widget _buildMinimalView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = filteredTracks[index];
          final isCurrentTrack = _currentlyPlayingIndex == index && 
                                 _currentTrack?.url == track.url;
          
          return _buildMinimalTrackItem(track, index, isCurrentTrack);
        },
        childCount: filteredTracks.length,
      ),
    );
  }

  // ... (Continuer avec les widgets spécialisés)

  Widget _buildViewModeButton() {
    return PopupMenuButton<ViewMode>(
      icon: const Icon(Icons.view_module),
      onSelected: _changeViewMode,
      itemBuilder: (context) => ViewMode.values.map((mode) {
        return PopupMenuItem(
          value: mode,
          child: Row(
            children: [
              Icon(_getViewModeIcon(mode)),
              const SizedBox(width: 8),
              Text(_getViewModeName(mode)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortBy>(
      icon: const Icon(Icons.sort),
      onSelected: _changeSorting,
      itemBuilder: (context) => SortBy.values.map((sort) {
        return PopupMenuItem(
          value: sort,
          child: Row(
            children: [
              Text(_getSortName(sort)),
              if (_sortBy == sort) ...[
                const Spacer(),
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuButton() {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () {
        // Ouvrir le menu des paramètres avancés
      },
    );
  }

  Widget _buildFloatingActionButtons() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentTrack != null) ...[
                FloatingActionButton(
                  heroTag: 'shuffle',
                  mini: true,
                  onPressed: () => _audioService.toggleShuffleMode(),
                  child: Icon(
                    _audioService.shuffleMode ? Icons.shuffle_on : Icons.shuffle,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton(
                heroTag: 'play',
                onPressed: () {
                  if (tracks.isNotEmpty && _currentTrack == null) {
                    _startPlayback(tracks[0], 0);
                  } else {
                    _togglePlayback();
                  }
                },
                child: Icon(
                  _playerState == PlayerState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Méthodes utilitaires pour l'interface
  IconData _getViewModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return Icons.list;
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.cards:
        return Icons.view_agenda;
      case ViewMode.minimal:
        return Icons.view_headline;
    }
  }

  String _getViewModeName(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return 'Liste';
      case ViewMode.grid:
        return 'Grille';
      case ViewMode.cards:
        return 'Cartes';
      case ViewMode.minimal:
        return 'Minimal';
    }
  }

  String _getSortName(SortBy sort) {
    switch (sort) {
      case SortBy.title:
        return 'Titre';
      case SortBy.artist:
        return 'Artiste';
      case SortBy.album:
        return 'Album';
      case SortBy.duration:
        return 'Durée';
      case SortBy.dateAdded:
        return 'Date d\'ajout';
      case SortBy.playCount:
        return 'Nb d\'écoutes';
    }
  }

  bool get _shouldShowMiniPlayer => 
      _playerState != PlayerState.stopped && _currentTrack != null;

  // ... (Widgets spécialisés pour les différents items)
  Widget _buildTrackListItem(Track track, int index, bool isCurrentTrack) {
    return ListTile(
      leading: _buildTrackImage(track, isCurrentTrack),
      title: Text(track.title),
      subtitle: Text('${track.artist} • ${track.durationText}'),
      trailing: _buildTrackActions(track),
      onTap: () => _startPlayback(track, index),
    );
  }

  Widget _buildTrackGridItem(Track track, int index, bool isCurrentTrack) {
    return Card(
      child: Column(
        children: [
          Expanded(child: _buildTrackImage(track, isCurrentTrack)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(Track track, int index, bool isCurrentTrack) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: _buildTrackImage(track, isCurrentTrack),
        title: Text(track.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.artist),
            Text('${track.album} • ${track.yearText}'),
          ],
        ),
        trailing: _buildTrackActions(track),
        onTap: () => _startPlayback(track, index),
      ),
    );
  }

  Widget _buildMinimalTrackItem(Track track, int index, bool isCurrentTrack) {
    return ListTile(
      title: Text('${track.artist} - ${track.title}'),
      subtitle: Text(track.durationText),
      onTap: () => _startPlayback(track, index),
    );
  }

  Widget _buildTrackImage(Track track, bool isCurrentTrack) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isCurrentTrack 
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.imageUrl.isNotEmpty
            ? Image.network(
                track.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
              )
            : _buildDefaultImage(),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey[800],
      child: Icon(Icons.music_note, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildTrackActions(Track track) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _playlistService.isTrackFavorite(track)
                ? Icons.favorite
                : Icons.favorite_border,
          ),
          onPressed: () => _toggleFavorite(track),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Ouvrir le menu contextuel du track
          },
        ),
      ],
    );
  }

  Widget _buildPlayerInterface() {
    return Positioned(
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
              color: _isPlayerExpanded 
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Theme.of(context).cardColor,
              borderRadius: _isPlayerExpanded 
                  ? null 
                  : const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: _isPlayerExpanded 
                ? _buildExpandedPlayer() 
                : _buildMiniPlayer(),
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return GestureDetector(
      onTap: _togglePlayerExpansion,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildTrackImage(_currentTrack!, true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentTrack!.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentTrack!.artist,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: _togglePlayback,
                ),
                const Icon(Icons.keyboard_arrow_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPlayer() {
    return Column(
      children: [
        // Header du player
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: _togglePlayerExpansion,
              ),
              Text(
                'Lecture en cours',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Menu du player
                },
              ),
            ],
          ),
        ),
        
        // Visualiseur audio
        if (_showVisualizer)
          SizedBox(
            height: 100,
            child: AudioVisualizerWidget(
              type: VisualizerType.bars,
              primaryColor: Theme.of(context).primaryColor,
              isPlaying: _playerState == PlayerState.playing,
            ),
          ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Image de l'album
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                              errorBuilder: (context, error, stackTrace) => 
                                  _buildDefaultImage(),
                            )
                          : _buildDefaultImage(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Informations du track
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        _currentTrack!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentTrack!.artist,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Contrôles de lecture
                _buildPlayerControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls() {
    return Column(
      children: [
        // Barre de progression
        Slider(
          value: _totalDuration.inMilliseconds > 0
              ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
              : 0.0,
          onChanged: (value) {
            final position = Duration(
              milliseconds: (value * _totalDuration.inMilliseconds).round(),
            );
            _audioService.seek(position);
          },
        ),
        
        // Temps
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_currentPosition)),
              Text(_formatDuration(_totalDuration)),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Boutons de contrôle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 36,
              onPressed: _audioService.hasPrevious 
                  ? () => _audioService.playPrevious()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.replay_10),
              iconSize: 32,
              onPressed: () {
                final newPosition = Duration(
                  milliseconds: (_currentPosition.inMilliseconds - 10000)
                      .clamp(0, _totalDuration.inMilliseconds),
                );
                _audioService.seek(newPosition);
              },
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _playerState == PlayerState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: _togglePlayback,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: 32,
              onPressed: () {
                final newPosition = Duration(
                  milliseconds: (_currentPosition.inMilliseconds + 10000)
                      .clamp(0, _totalDuration.inMilliseconds),
                );
                _audioService.seek(newPosition);
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 36,
              onPressed: _audioService.hasNext 
                  ? () => _audioService.playNext()
                  : null,
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Contrôles secondaires
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                _audioService.shuffleMode ? Icons.shuffle_on : Icons.shuffle,
              ),
              onPressed: () => _audioService.toggleShuffleMode(),
            ),
            IconButton(
              icon: Icon(
                _playlistService.isTrackFavorite(_currentTrack!)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              onPressed: () => _toggleFavorite(_currentTrack!),
            ),
            IconButton(
              icon: Icon(_getLoopModeIcon()),
              onPressed: () => _audioService.toggleLoopMode(),
            ),
            IconButton(
              icon: const Icon(Icons.equalizer),
              onPressed: () {
                // Ouvrir l'égaliseur
              },
            ),
          ],
        ),
      ],
    );
  }

  IconData _getLoopModeIcon() {
    switch (_audioService.loopMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.single:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat_on;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// États réutilisés
enum PlayerState { stopped, loading, playing, paused, error }
enum LoadingState { initial, loading, loaded, error, retry }
enum NetworkState { connected, disconnected, unknown }