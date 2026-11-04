import 'package:gal/gal.dart';

class GalleryDataSource {
  static const album = 'Downloader';

  Future<bool> ensureAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) return true;
    return Gal.requestAccess(toAlbum: true);
  }

  Future<void> saveVideo(String path) => Gal.putVideo(path, album: album);

  Future<void> open() => Gal.open();
}
