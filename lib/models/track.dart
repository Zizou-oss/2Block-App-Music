/// Modèle enrichi représentant un track audio

class Track {
  final String title;         // Titre du morceau
  final String artist;        // Artiste
  final String album;         // Album
  final String url;           // Lien du fichier audio
  final String imageUrl;      // Image de couverture
  final String? localPath;    // Chemin local si téléchargé
  final Duration duration;    // Durée du track
  final String? genre;        // Genre musical
  final int? year;           // Année de sortie
  final int playCount;       // Nombre d'écoutes
  final DateTime dateAdded;  // Date d'ajout
  final DateTime? lastPlayed; // Dernière écoute
  final bool isFavorite;     // Favori ou non
  final double rating;       // Note (0-5)
  final Map<String, dynamic> metadata; // Métadonnées additionnelles

  Track({
    required this.title,
    this.artist = 'Artiste Inconnu',
    this.album = 'Album Inconnu',
    required this.url,
    required this.imageUrl,
    this.localPath,
    this.duration = Duration.zero,
    this.genre,
    this.year,
    this.playCount = 0,
    DateTime? dateAdded,
    this.lastPlayed,
    this.isFavorite = false,
    this.rating = 0.0,
    this.metadata = const {},
  }) : dateAdded = dateAdded ?? DateTime.now();

  // Factory pour créer un Track à partir d'un JSON
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      title: json['title'] ?? '',
      artist: json['artist'] ?? 'Artiste Inconnu',
      album: json['album'] ?? 'Album Inconnu',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      localPath: json['localPath'],
      duration: Duration(milliseconds: json['duration'] ?? 0),
      genre: json['genre'],
      year: json['year'],
      playCount: json['playCount'] ?? 0,
      dateAdded: DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.tryParse(json['lastPlayed']) 
          : null,
      isFavorite: json['isFavorite'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Conversion en JSON pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'url': url,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'duration': duration.inMilliseconds,
      'genre': genre,
      'year': year,
      'playCount': playCount,
      'dateAdded': dateAdded.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'isFavorite': isFavorite,
      'rating': rating,
      'metadata': metadata,
    };
  }

  // Validation de l'URL
  bool get isValidUrl {
    return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
  }

  // Formatage de la durée
  String get durationText {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Informations artiste-titre
  String get artistTitle => '$artist - $title';
  
  // Année de sortie formatée
  String get yearText => year?.toString() ?? 'Inconnue';
  
  // Note en étoiles
  String get starsRating {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';
    return stars.padRight(5, '☆');
  }

  // Copie avec de nouvelles valeurs
  Track copyWith({
    String? title,
    String? artist,
    String? album,
    String? url,
    String? imageUrl,
    String? localPath,
    Duration? duration,
    String? genre,
    int? year,
    int? playCount,
    DateTime? dateAdded,
    DateTime? lastPlayed,
    bool? isFavorite,
    double? rating,
    Map<String, dynamic>? metadata,
  }) {
    return Track(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      playCount: playCount ?? this.playCount,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utilitaires
  Track markAsPlayed() {
    return copyWith(
      playCount: playCount + 1,
      lastPlayed: DateTime.now(),
    );
  }

  Track toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  Track rate(double newRating) {
    return copyWith(rating: newRating.clamp(0.0, 5.0));
  }

  Track updateMetadata(Map<String, dynamic> newMetadata) {
    final updatedMetadata = Map<String, dynamic>.from(metadata);
    updatedMetadata.addAll(newMetadata);
    return copyWith(metadata: updatedMetadata);
  }
}
