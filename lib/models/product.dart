class Product {
  final String id;
  final String name;
  final String description;
  final String barcode;
  final double price;
  final double discountPercent;
  final int stockQuantity;
  final int lowStockThreshold;
  final String category;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    this.barcode = '',
    required this.price,
    this.discountPercent = 0,
    required this.stockQuantity,
    this.lowStockThreshold = 10,
    this.category = 'General',
    this.imageUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get discountedPrice => price * (1 - discountPercent / 100);

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  bool get isOutOfStock => stockQuantity <= 0;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? discountPercent,
    int? stockQuantity,
    int? lowStockThreshold,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      discountPercent: discountPercent ?? this.discountPercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'price': price,
      'discountPercent': discountPercent,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      stockQuantity: json['stockQuantity'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      category: json['category'] as String? ?? 'General',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
