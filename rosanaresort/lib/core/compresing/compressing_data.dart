
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class CompressingData {
  String _getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi'].contains(ext)) return 'video';
    if (ext == 'pdf') return 'pdf';
    return 'other';
  }
  Future<String?> _compressImage(String path) async {
    XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      path,
      "${path}_compressed.jpg",
      quality: 60,
      minWidth: 800,
      minHeight: 800,
    );
    return compressedFile?.path??"";
  }
  Future<String?> _compressVideo(String path) async {
    final info = await VideoCompress.compressVideo(
      path,
      quality: VideoQuality.MediumQuality,
    );

    return info?.file?.path != null ? info!.file?.path??"" : null;
  }
  // Future<String?> _compressToZip(String filePath) async {
  //   final file = File(filePath);
  //   final bytes = await file.readAsBytes();
  //
  //   final archive = Archive();
  //   archive.addFile(ArchiveFile(
  //     filePath.split('/').last,
  //     bytes.length,
  //     bytes,
  //   ));
  //
  //   final zipData = ZipEncoder().encode(archive);
  //
  //   final zipFile = File('$filePath.zip');
  //   await zipFile.writeAsBytes(zipData);
  //
  //   return zipFile.path;
  //
  // }
  Future<String?> compressFile(String path) async {
    final type = _getFileType(path);

    switch (type) {
      case 'image':
        return await _compressImage(path);

      case 'video':
        return await _compressVideo(path);



      default:
        return path;
    }
  }
}