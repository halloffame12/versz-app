import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:video_thumbnail/video_thumbnail.dart'; // Future phase support

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    return image != null ? File(image.path) : null;
  }

  Future<File?> pickVideo(ImageSource source) async {
    final XFile? video = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    return video != null ? File(video.path) : null;
  }

  Future<String?> generateThumbnail(String videoPath) async {
    // Stub: video_thumbnail not in dependencies yet
    // Future: Implement when adding video features
    // Requires: flutter pub add video_thumbnail
    return null;
  }

  Future<double> getFileSizeInMb(File file) async {
    final int sizeInBytes = await file.length();
    return sizeInBytes / (1024 * 1024);
  }
}
