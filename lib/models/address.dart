class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String city;
  final String state;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  Address copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? city,
    String? state,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fullAddress)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fullAddress': fullAddress,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
