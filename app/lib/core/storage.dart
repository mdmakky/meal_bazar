import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'errors.dart';
import 'ids.dart';
import 'supabase.dart';

/// Private bucket (0009_storage_and_deposits.sql); policies key on the first
/// path segment, so every object lives under its mess.
const receiptsBucket = 'receipts';

/// `{messId}/{uuid}.jpg`.
String receiptPath(String messId) => '$messId/${uuidV4()}.jpg';

/// Receipt and screenshot photos in Supabase Storage.
class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  /// Uploads a compressed JPEG and returns its path. Throws `AppFailure`.
  Future<String> uploadReceipt(String messId, Uint8List bytes) =>
      guard(() async {
        final path = receiptPath(messId);
        await _client.storage
            .from(receiptsBucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        return path;
      });

  /// A one-hour URL for viewing a private object.
  Future<String> signedUrl(String path) => guard(
    () => _client.storage.from(receiptsBucket).createSignedUrl(path, 3600),
  );
}

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(supabaseClientProvider)),
);

/// Auto-disposed so a reopened view never reuses an expired URL.
final receiptUrlProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, path) => ref.watch(storageServiceProvider).signedUrl(path),
);
