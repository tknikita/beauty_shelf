import 'storage_service.dart';
import 'storage_web.dart' if (dart.library.io) 'storage_io.dart' as impl;

StorageService createStorageService() {
  return impl.createStorage();
}
