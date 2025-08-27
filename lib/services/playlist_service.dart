import 'dart:async';
import '../models/playlist.dart';
import '../models/track.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  final List<Playlist> _playlists = [];
  final StreamController<List<Playlist>> _playlistsController = 
      StreamController<List<Playlist>>.broadcast();
  
  // Stream pour écouter les changements
  Stream<List<Playlist>> get playlistsStream => _playlistsController.stream;
  
  // Getters
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Playlist> get userPlaylists => 
      _playlists.where((p) => p.type == PlaylistType.user).toList();
  List<Playlist> get systemPlaylists => 
      _playlists.where((p) => p.isSystemPlaylist).toList();
  
  Playlist? get favoritesPlaylist => 
      _playlists.where((p) => p.type == PlaylistType.favorites).firstOrNull;
  
  Playlist? get recentPlaylist => 
      _playlists.where((p) => p.type == PlaylistType.recent).firstOrNull;
  
  Playlist? get mostPlayedPlaylist => 
      _playlists.where((p) => p.type == PlaylistType.mostPlayed).firstOrNull;

  // Initialisation
  Future<void> initialize() async {
    // Créer les playlists système par défaut
    await _createSystemPlaylists();
    
    // Charger les playlists utilisateur (simulation)
    await _loadUserPlaylists();
    
    _notifyListeners();
  }

  Future<void> _createSystemPlaylists() async {
    // Favoris
    if (!_playlists.any((p) => p.type == PlaylistType.favorites)) {
      _playlists.add(Playlist.favorites());
    }
    
    // Récemment écoutés
    if (!_playlists.any((p) => p.type == PlaylistType.recent)) {
      _playlists.add(Playlist.recent());
    }
    
    // Les plus écoutés
    if (!_playlists.any((p) => p.type == PlaylistType.mostPlayed)) {
      _playlists.add(Playlist.mostPlayed());
    }
  }

  Future<void> _loadUserPlaylists() async {
    // Simulation du chargement depuis le stockage local
    // Dans une vraie app, ici on chargerait depuis SharedPreferences/Database
    
    // Playlist d'exemple
    final examplePlaylist = Playlist.user(
      name: 'Ma Playlist Test',
      description: 'Une playlist d\'exemple',
      isPublic: false,
    );
    
    _playlists.add(examplePlaylist);
  }

  // Gestion des playlists utilisateur
  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    String? imageUrl,
    List<Track> tracks = const [],
    bool isPublic = false,
    bool isCollaborative = false,
  }) async {
    final playlist = Playlist.user(
      name: name,
      description: description,
      imageUrl: imageUrl,
      tracks: tracks,
      isPublic: isPublic,
      isCollaborative: isCollaborative,
    );
    
    _playlists.add(playlist);
    await _savePlaylist(playlist);
    _notifyListeners();
    
    return playlist;
  }

  Future<void> updatePlaylist(Playlist updatedPlaylist) async {
    final index = _playlists.indexWhere((p) => p.id == updatedPlaylist.id);
    if (index != -1) {
      _playlists[index] = updatedPlaylist;
      await _savePlaylist(updatedPlaylist);
      _notifyListeners();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist != null && !playlist.isSystemPlaylist) {
      _playlists.removeWhere((p) => p.id == playlistId);
      await _deletePlaylistFromStorage(playlistId);
      _notifyListeners();
    }
  }

  // Gestion des tracks dans les playlists
  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.addTrack(track);
      await updatePlaylist(updatedPlaylist);
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, Track track) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.removeTrack(track);
      await updatePlaylist(updatedPlaylist);
    }
  }

  Future<void> moveTrackInPlaylist(String playlistId, int fromIndex, int toIndex) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.moveTrack(fromIndex, toIndex);
      await updatePlaylist(updatedPlaylist);
    }
  }

  // Gestion des favoris
  Future<void> toggleFavorite(Track track) async {
    final favPlaylist = favoritesPlaylist;
    if (favPlaylist != null) {
      if (favPlaylist.containsTrack(track)) {
        await removeTrackFromPlaylist(favPlaylist.id, track);
      } else {
        await addTrackToPlaylist(favPlaylist.id, track);
      }
    }
  }

  bool isTrackFavorite(Track track) {
    final favPlaylist = favoritesPlaylist;
    return favPlaylist?.containsTrack(track) ?? false;
  }

  // Gestion des écoutes récentes
  Future<void> addToRecentlyPlayed(Track track) async {
    final recentPlaylist = recentPlaylist;
    if (recentPlaylist != null) {
      // Retirer le track s'il existe déjà
      final withoutTrack = recentPlaylist.removeTrack(track);
      // L'ajouter au début
      final updatedPlaylist = withoutTrack.addTrack(track);
      await updatePlaylist(updatedPlaylist);
    }
  }

  // Mise à jour des statistiques
  Future<void> updateTrackStats(Track track) async {
    final mostPlayedPlaylist = mostPlayedPlaylist;
    if (mostPlayedPlaylist != null) {
      final updatedTrack = track.markAsPlayed();
      
      // Mettre à jour dans toutes les playlists qui contiennent ce track
      for (final playlist in _playlists) {
        if (playlist.containsTrack(track)) {
          final tracks = playlist.tracks.map((t) => 
              t.url == track.url ? updatedTrack : t).toList();
          final updatedPlaylist = playlist.copyWith(tracks: tracks);
          await updatePlaylist(updatedPlaylist);
        }
      }
      
      // Ajouter aux récemment joués
      await addToRecentlyPlayed(updatedTrack);
    }
  }

  // Recherche et filtrage
  List<Playlist> searchPlaylists(String query) {
    if (query.isEmpty) return playlists;
    
    final lowerQuery = query.toLowerCase();
    return _playlists.where((playlist) =>
      playlist.name.toLowerCase().contains(lowerQuery) ||
      (playlist.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  List<Track> searchTracksInPlaylists(String query) {
    final results = <Track>[];
    for (final playlist in _playlists) {
      results.addAll(playlist.search(query));
    }
    // Retirer les doublons
    return results.toSet().toList();
  }

  // Playlists intelligentes
  Future<Playlist> generateSmartPlaylist({
    required String name,
    String? genre,
    int? year,
    int minRating = 0,
    int maxTracks = 50,
  }) async {
    // Récupérer tous les tracks de toutes les playlists
    final allTracks = <Track>[];
    for (final playlist in _playlists) {
      allTracks.addAll(playlist.tracks);
    }
    
    // Filtrer selon les critères
    var filteredTracks = allTracks.where((track) {
      bool matches = true;
      
      if (genre != null) {
        matches &= track.genre?.toLowerCase() == genre.toLowerCase();
      }
      
      if (year != null) {
        matches &= track.year == year;
      }
      
      matches &= track.rating >= minRating;
      
      return matches;
    }).toList();
    
    // Trier par popularité (playCount + rating)
    filteredTracks.sort((a, b) {
      final scoreA = a.playCount + (a.rating * 10);
      final scoreB = b.playCount + (b.rating * 10);
      return scoreB.compareTo(scoreA);
    });
    
    // Limiter le nombre
    if (filteredTracks.length > maxTracks) {
      filteredTracks = filteredTracks.take(maxTracks).toList();
    }
    
    // Créer la playlist
    final smartPlaylist = Playlist(
      id: 'smart_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: 'Playlist générée automatiquement',
      tracks: filteredTracks,
      type: PlaylistType.smart,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {
        'genre': genre,
        'year': year,
        'minRating': minRating,
        'maxTracks': maxTracks,
      },
    );
    
    _playlists.add(smartPlaylist);
    await _savePlaylist(smartPlaylist);
    _notifyListeners();
    
    return smartPlaylist;
  }

  // Recommandations
  List<Track> getRecommendationsFor(Track track) {
    final recommendations = <Track>[];
    
    // Rechercher des tracks similaires (même artiste, genre, etc.)
    for (final playlist in _playlists) {
      for (final otherTrack in playlist.tracks) {
        if (otherTrack.url != track.url) {
          int similarity = 0;
          
          if (otherTrack.artist == track.artist) similarity += 3;
          if (otherTrack.genre == track.genre) similarity += 2;
          if (otherTrack.album == track.album) similarity += 2;
          if ((otherTrack.year ?? 0) == (track.year ?? 0)) similarity += 1;
          
          if (similarity >= 2) {
            recommendations.add(otherTrack);
          }
        }
      }
    }
    
    // Retirer les doublons et trier par similarité
    return recommendations.toSet().take(10).toList();
  }

  // Méthodes utilitaires
  Playlist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Playlist> getPlaylistsContaining(Track track) {
    return _playlists.where((p) => p.containsTrack(track)).toList();
  }

  // Stockage (simulation)
  Future<void> _savePlaylist(Playlist playlist) async {
    // Ici on sauvegarderait dans SharedPreferences ou une base de données
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setString('playlist_${playlist.id}', jsonEncode(playlist.toJson()));
    // });
  }

  Future<void> _deletePlaylistFromStorage(String playlistId) async {
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.remove('playlist_$playlistId');
    // });
  }

  // Notification des changements
  void _notifyListeners() {
    _playlistsController.add(List.unmodifiable(_playlists));
  }

  // Nettoyage
  void dispose() {
    _playlistsController.close();
  }

  // Export/Import
  Map<String, dynamic> exportPlaylists() {
    return {
      'playlists': _playlists.map((p) => p.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importPlaylists(Map<String, dynamic> data) async {
    final playlistsData = data['playlists'] as List?;
    if (playlistsData != null) {
      for (final playlistData in playlistsData) {
        final playlist = Playlist.fromJson(playlistData);
        if (!playlist.isSystemPlaylist) {
          _playlists.add(playlist);
          await _savePlaylist(playlist);
        }
      }
      _notifyListeners();
    }
  }
}

// Extension pour FirstOrNull (si pas disponible)
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}