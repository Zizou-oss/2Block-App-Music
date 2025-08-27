import 'track.dart';

enum PlaylistType { 
  user,           // Créée par l'utilisateur
  smart,          // Générée automatiquement
  favorites,      // Favoris
  recent,         // Récemment écoutés
  mostPlayed,     // Les plus écoutés
  recommended     // Recommandations
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<Track> tracks;
  final PlaylistType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  
  // Statistiques
  final int playCount;
  final Duration totalDuration;
  final bool isPublic;
  final bool isCollaborative;
  final String? createdBy;
  
  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.tracks,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.playCount = 0,
    this.isPublic = false,
    this.isCollaborative = false,
    this.createdBy,
  }) : totalDuration = _calculateTotalDuration(tracks);
  
  static Duration _calculateTotalDuration(List<Track> tracks) {
    return tracks.fold(Duration.zero, (total, track) => total + track.duration);
  }
  
  // Factory constructors pour différents types
  factory Playlist.user({
    required String name,
    String? description,
    String? imageUrl,
    List<Track> tracks = const [],
    bool isPublic = false,
    bool isCollaborative = false,
  }) {
    return Playlist(
      id: _generateId(),
      name: name,
      description: description,
      imageUrl: imageUrl,
      tracks: List.from(tracks),
      type: PlaylistType.user,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPublic: isPublic,
      isCollaborative: isCollaborative,
    );
  }
  
  factory Playlist.favorites() {
    return Playlist(
      id: 'favorites',
      name: 'Mes Favoris',
      description: 'Vos titres préférés',
      imageUrl: null,
      tracks: [],
      type: PlaylistType.favorites,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {'system': true},
    );
  }
  
  factory Playlist.recent() {
    return Playlist(
      id: 'recent',
      name: 'Récemment Écoutés',
      description: 'Vos dernières écoutes',
      imageUrl: null,
      tracks: [],
      type: PlaylistType.recent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {'system': true, 'maxTracks': 50},
    );
  }
  
  factory Playlist.mostPlayed() {
    return Playlist(
      id: 'most_played',
      name: 'Les Plus Écoutés',
      description: 'Vos titres les plus joués',
      imageUrl: null,
      tracks: [],
      type: PlaylistType.mostPlayed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {'system': true, 'maxTracks': 100},
    );
  }
  
  // Méthodes de manipulation
  Playlist addTrack(Track track) {
    final newTracks = List<Track>.from(tracks);
    
    // Éviter les doublons pour certains types
    if (type == PlaylistType.favorites && 
        newTracks.any((t) => t.url == track.url)) {
      return this;
    }
    
    newTracks.add(track);
    
    // Limiter le nombre de tracks pour certains types
    final maxTracks = metadata['maxTracks'] as int?;
    if (maxTracks != null && newTracks.length > maxTracks) {
      newTracks.removeRange(0, newTracks.length - maxTracks);
    }
    
    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    );
  }
  
  Playlist removeTrack(Track track) {
    final newTracks = tracks.where((t) => t.url != track.url).toList();
    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    );
  }
  
  Playlist addTrackAtIndex(Track track, int index) {
    final newTracks = List<Track>.from(tracks);
    newTracks.insert(index.clamp(0, newTracks.length), track);
    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    );
  }
  
  Playlist moveTrack(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= tracks.length ||
        toIndex < 0 || toIndex >= tracks.length) {
      return this;
    }
    
    final newTracks = List<Track>.from(tracks);
    final track = newTracks.removeAt(fromIndex);
    newTracks.insert(toIndex, track);
    
    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    );
  }
  
  Playlist shuffle() {
    final newTracks = List<Track>.from(tracks)..shuffle();
    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    );
  }
  
  Playlist sortBy(TrackSortType sortType, {bool ascending = true}) {
    final newTracks = List<Track>.from(tracks);
    
    switch (sortType) {
      case TrackSortType.title:
        newTracks.sort((a, b) => ascending 
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case TrackSortType.artist:
        newTracks.sort((a, b) => ascending 
            ? a.artist.compareTo(b.artist)
            : b.artist.compareTo(a.artist));
        break;
      case TrackSortType.duration:
        newTracks.sort((a, b) => ascending 
            ? a.duration.compareTo(b.duration)
            : b.duration.compareTo(a.duration));
        break;
      case TrackSortType.dateAdded:
        newTracks.sort((a, b) => ascending 
            ? a.dateAdded.compareTo(b.dateAdded)
            : b.dateAdded.compareTo(a.dateAdded));
        break;
      case TrackSortType.playCount:
        newTracks.sort((a, b) => ascending 
            ? a.playCount.compareTo(b.playCount)
            : b.playCount.compareTo(a.playCount));
        break;
    }
    
    return copyWith(
      tracks: newTracks,
      updatedAt: DateTime.now(),
    );
  }
  
  // Getters utiles
  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;
  int get trackCount => tracks.length;
  bool get isSystemPlaylist => metadata['system'] == true;
  String get durationText => _formatDuration(totalDuration);
  
  // Recherche dans la playlist
  List<Track> search(String query) {
    if (query.isEmpty) return tracks;
    
    final lowerQuery = query.toLowerCase();
    return tracks.where((track) =>
      track.title.toLowerCase().contains(lowerQuery) ||
      track.artist.toLowerCase().contains(lowerQuery)
    ).toList();
  }
  
  // Vérifications
  bool containsTrack(Track track) {
    return tracks.any((t) => t.url == track.url);
  }
  
  // Copie avec modifications
  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<Track>? tracks,
    PlaylistType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    int? playCount,
    bool? isPublic,
    bool? isCollaborative,
    String? createdBy,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tracks: tracks ?? this.tracks,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      playCount: playCount ?? this.playCount,
      isPublic: isPublic ?? this.isPublic,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      createdBy: createdBy ?? this.createdBy,
    );
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'playCount': playCount,
      'isPublic': isPublic,
      'isCollaborative': isCollaborative,
      'createdBy': createdBy,
    };
  }
  
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      tracks: (json['tracks'] as List?)
          ?.map((trackJson) => Track.fromJson(trackJson))
          .toList() ?? [],
      type: PlaylistType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => PlaylistType.user,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      playCount: json['playCount'] ?? 0,
      isPublic: json['isPublic'] ?? false,
      isCollaborative: json['isCollaborative'] ?? false,
      createdBy: json['createdBy'],
    );
  }
  
  // Méthodes utilitaires statiques
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

enum TrackSortType {
  title,
  artist,
  duration,
  dateAdded,
  playCount
}