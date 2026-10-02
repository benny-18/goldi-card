/// Data model for the one-time store/device configuration.
class StoreConfig {
  final String branchName;
  final int clusterNumber;
  final String staffName;

  StoreConfig({
    required this.branchName,
    required this.clusterNumber,
    required this.staffName,
  });
}
