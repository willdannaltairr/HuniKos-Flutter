import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Membaca berkas lewat XFile, bukan path, supaya unggahan tetap jalan di web
/// (di sana "path" berupa blob URL yang tidak bisa dibuka File biasa).
Future<MultipartFile> multipartFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  return MultipartFile.fromBytes(bytes, filename: file.name);
}
