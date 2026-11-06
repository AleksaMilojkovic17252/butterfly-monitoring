/// State of a project's offline package on this phone.
enum OfflinePackageStatus {
  notDownloaded('Not loaded'),
  ready('Ready'),
  updateAvailable('Outdated');

  const OfflinePackageStatus(this.label);
  final String label;
}

/// A project's offline package state plus what its next Download or Update
/// would fetch for the basemap (T060).
class OfflinePackage {
  const OfflinePackage(this.status, {this.basemapBytesToDownload});
  final OfflinePackageStatus status;

  /// Size in bytes of the basemap file a Download or Update would fetch; null
  /// when there is none to fetch (the project has no basemap, the phone has
  /// the current file, or the server could not be asked).
  final int? basemapBytesToDownload;
}
