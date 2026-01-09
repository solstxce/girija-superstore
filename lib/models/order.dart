import 'cart_item.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<CartItem> items;
  final Address deliveryAddress;
  final double? userLatitude;
  final double? userLongitude;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? notes;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.items,
    required this.deliveryAddress,
    this.userLatitude,
    this.userLongitude,
    this.status = OrderStatus.pending,
    required this.subtotal,
    this.discount = 0,
    this.deliveryFee = 0,
    required this.total,
    DateTime? createdAt,
    this.deliveredAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get liveLocationUrl {
    if (userLatitude != null && userLongitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$userLatitude,$userLongitude';
    }
    return deliveryAddress.googleMapsUrl;
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    List<CartItem>? items,
    Address? deliveryAddress,
    double? userLatitude,
    double? userLongitude,
    OrderStatus? status,
    double? subtotal,
    double? discount,
    double? deliveryFee,
    double? total,
    DateTime? createdAt,
    DateTime? deliveredAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((e) => e.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'status': status.name,
      'subtotal': subtotal,
      'discount': discount,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String? ?? '',
      items: (json['items'] as List)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress:
          Address.fromJson(json['deliveryAddress'] as Map<String, dynamic>),
      userLatitude: json['userLatitude'] as double?,
      userLongitude: json['userLongitude'] as double?,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
