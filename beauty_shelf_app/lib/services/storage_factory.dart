import 'storage_service.dart';
import 'storage_io.dart' as impl;

/// Mobile-only build: storage is always backed by the local SQLite database.
StorageService createStorageService() {
  return impl.createStorage();
}
