import '../models/track.dart';

class GithubService {
  static Future<List<Track>> fetchTracks() async {
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
}