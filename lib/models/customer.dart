/// Data model for a registered Goldi Card customer.
class Customer {
  final String id;
  final String cardSerial;
  final String fullName;
  final DateTime birthdate;
  final String address;
  final String? profilePictureUrl;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.cardSerial,
    required this.fullName,
    required this.birthdate,
    required this.address,
    this.profilePictureUrl,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      cardSerial: json['card_serial'] as String,
      fullName: json['full_name'] as String,
      birthdate: DateTime.parse(json['birthdate'] as String),
      address: json['address'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_serial': cardSerial,
      'full_name': fullName,
      'birthdate': birthdate.toIso8601String().split('T').first,
      'address': address,
      'profile_picture_url': profilePictureUrl,
    };
  }
}
