import 'package:firebase_storage/firebase_storage.dart';

class ImageUrlResolver {
  Future<String?> resolve(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    if (rawUrl.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(rawUrl).getDownloadURL();
    }
    return rawUrl;
  }
}
