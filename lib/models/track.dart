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
      title: json['title'],
      url: json['url'],
      localPath: json['localPath'], imageUrl: '',
    );
  }
}
