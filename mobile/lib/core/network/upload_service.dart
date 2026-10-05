import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'network_providers.dart';

/// What an image is for. Matches the API's `purpose` field on `POST /uploads`.
enum UploadPurpose { avatar, rideCover, post, groupCover, place, other }

/// Uploads images and returns their public URL, which you then store on the
/// profile (`avatarUrl`), ride (`imageUrl`), post, group or place.
class UploadService {
  static const _path = '/uploads';

  final ApiClient _api;
  final ImagePicker _picker;

  UploadService(this._api, [ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  /// Uploads an already picked image. The server accepts JPEG, PNG, WebP and
  /// GIF up to 5 MB and checks the real file type from its bytes.
  Future<String> uploadImage(XFile file, {required UploadPurpose purpose}) async {
    final bytes = await file.readAsBytes(); // readAsBytes works on web too
    final json = await _api.upload<Map<String, dynamic>>(
      _path,
      file: MultipartFile.fromBytes(bytes, filename: file.name),
      fields: {'purpose': purpose.name},
    );
    return json['url'] as String;
  }

  /// Opens the gallery (or camera), uploads the chosen photo and returns its
  /// URL. Returns null if the user cancels. Images are downscaled first so
  /// uploads stay small on mobile data.
  Future<String?> pickAndUpload({
    required UploadPurpose purpose,
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file == null) return null;
    return uploadImage(file, purpose: purpose);
  }

  /// Picks several photos (for places) and uploads them one by one.
  Future<List<String>> pickAndUploadMany({required UploadPurpose purpose, int limit = 10}) async {
    if (limit < 1) return const [];
    if (limit == 1) {
      final url = await pickAndUpload(purpose: purpose);
      return url == null ? const [] : [url];
    }
    final files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 85, limit: limit);
    final urls = <String>[];
    for (final file in files.take(limit)) {
      urls.add(await uploadImage(file, purpose: purpose));
    }
    return urls;
  }
}

final uploadServiceProvider = Provider<UploadService>((ref) => UploadService(ref.watch(apiClientProvider)));
