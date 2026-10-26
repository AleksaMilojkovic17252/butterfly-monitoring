/// State of a project's offline package on this phone.
enum OfflinePackageStatus {
  notDownloaded('Not loaded'),
  ready('Ready'),
  updateAvailable('Outdated');

  const OfflinePackageStatus(this.label);
  final String label;
}
