import 'dart:async';
import 'dart:io';
import '../models/track.dart';

class GithubService {
  static List<Track>? _cachedTracks;
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 30);
  
  static Future<List<Track>> fetchTracks({bool forceRefresh = false}) async {
    // Vérifier le cache d'abord
    if (!forceRefresh && _cachedTracks != null && _lastFetchTime != null) {
      final timeDifference = DateTime.now().difference(_lastFetchTime!);
      if (timeDifference < _cacheValidDuration) {
        return _cachedTracks!;
      }
    }
    
    try {
      await _checkNetworkConnectivity();
      
      final tracks = await _loadTracks();
      
      // Valider les tracks
      final validTracks = tracks.where((track) => track.isValidUrl).toList();
      
      // Mettre en cache
      _cachedTracks = validTracks;
      _lastFetchTime = DateTime.now();
      
      return validTracks;
    } catch (e) {
      // En cas d'erreur, retourner le cache si disponible
      if (_cachedTracks != null) {
        return _cachedTracks!;
      }
      rethrow;
    }
  }
  
  static Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('github.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('Pas de connexion internet');
      }
    } on SocketException {
      throw const SocketException('Impossible de se connecter au serveur');
    } on TimeoutException {
      throw TimeoutException('Délai de connexion dépassé', const Duration(seconds: 5));
    }
  }
  
  static Future<List<Track>> _loadTracks() async {
    // Simulation d'un délai réseau plus réaliste
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      Track(
        title: 'Vie d\'avant',
        url: 'https://raw.githubusercontent.com/Zizou-oss/my-audio-files/main/2Block-Vie-d\'enfance.m4a',
        imageUrl: 'assets/images/song1.jpg',
        localPath: '',
      ),
      Track(
        title: 'Compliqué',
        url: 'https://raw.githubusercontent.com/Zizou-oss/my-audio-files/main/2Block-Compliqu%C3%A9.m4a',
        imageUrl: 'assets/images/song1.jpg',
        localPath: '',
      ),
      Track(
        title: 'Mélodie',
        url: 'https://raw.githubusercontent.com/Zizou-oss/my-audio-files/main/2Block-Melodie.m4a',
        imageUrl: 'assets/images/song1.jpg',
        localPath: '',
      ),
      Track(
        title: 'Africain',
        url: 'https://raw.githubusercontent.com/Zizou-oss/my-audio-files/main/2Block-Africain.m4a',
        imageUrl: 'assets/images/song1.jpg',
        localPath: '',
      ),
      Track(
        title: '2025',
        url: 'https://raw.githubusercontent.com/Zizou-oss/my-audio-files/main/Loudab%20-%20two%20tousand%20and%20twenty%20five%20%20freestyle%20(2025)%202025-04-08%2021_09.m4a',
        imageUrl: 'assets/images/song1.jpg',
        localPath: '',
      ),
      Track(
        title: 'Cash à la maison',
        url: 'https://raw.githubusercontent.com/Zizou-oss/my-audio-files/main/2Block-C.A.L.M.m4a',
        imageUrl: 'assets/images/song1.jpg',
        localPath: '',
      ),
    ];
  }
  
  // Méthode pour vider le cache
  static void clearCache() {
    _cachedTracks = null;
    _lastFetchTime = null;
  }
  
  // Méthode pour obtenir un track par titre
  static Track? getTrackByTitle(String title) {
    return _cachedTracks?.firstWhere(
      (track) => track.title.toLowerCase() == title.toLowerCase(),
      orElse: () => Track(title: '', url: '', imageUrl: ''),
    );
  }
  
  // Méthode pour rechercher des tracks
  static List<Track> searchTracks(String query) {
    if (_cachedTracks == null || query.isEmpty) return [];
    
    return _cachedTracks!.where((track) =>
      track.title.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  // Vérifier si le cache est valide
  static bool get isCacheValid {
    if (_cachedTracks == null || _lastFetchTime == null) return false;
    final timeDifference = DateTime.now().difference(_lastFetchTime!);
    return timeDifference < _cacheValidDuration;
  }
}