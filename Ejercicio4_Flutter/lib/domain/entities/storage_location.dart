/// Las tres ubicaciones accesibles del sandbox (Documents, Inbox y tmp),
/// igual que `rootLocations` en FileSystemService.swift.
enum LocationType { documents, inbox, temporary }

class StorageLocation {
  const StorageLocation({
    required this.name,
    required this.path,
    required this.type,
  });

  final String name;
  final String path;
  final LocationType type;
}
