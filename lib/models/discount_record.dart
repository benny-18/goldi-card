/// Data model for a single discount redemption record.
class DiscountRecord {
  final String id;
  final String customerId;
  final double discountPercent;
  final String branchName;
  final int clusterNumber;
  final String processedBy;
  final DateTime redeemedAt;

  DiscountRecord({
    required this.id,
    required this.customerId,
    required this.discountPercent,
    required this.branchName,
    required this.clusterNumber,
    required this.processedBy,
    required this.redeemedAt,
  });

  factory DiscountRecord.fromJson(Map<String, dynamic> json) {
    return DiscountRecord(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      discountPercent: (json['discount_percent'] as num).toDouble(),
      branchName: json['branch_name'] as String,
      clusterNumber: json['cluster_number'] as int,
      processedBy: json['processed_by'] as String,
      redeemedAt: DateTime.parse(json['redeemed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'discount_percent': discountPercent,
      'branch_name': branchName,
      'cluster_number': clusterNumber,
      'processed_by': processedBy,
    };
  }
}
