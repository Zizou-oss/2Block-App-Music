/// Modèle représentant un son (track)

class Track {
  final String title;    // Titre du morceau
  final String url;      // Lien du fichier .mp3 (en ligne)
  final String imageUrl; // Nouvelle propriété
  final String? localPath; // Chemin local si téléchargé

  Track({
    required this.title,
    required this.url,
    required this.imageUrl,
    this.localPath,
  });

  // Factory pour créer un Track à partir d'un JSON (utile plus tard)
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      localPath: json['localPath'],
    );
  }

  // Conversion en JSON pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'imageUrl': imageUrl,
      'localPath': localPath,
    };
  }

  // Validation de l'URL
  bool get isValidUrl {
    return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
  }

  // Copie avec de nouvelles valeurs
  Track copyWith({
    String? title,
    String? url,
    String? imageUrl,
    String? localPath,
  }) {
    return Track(
      title: title ?? this.title,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
    );
  }
}
