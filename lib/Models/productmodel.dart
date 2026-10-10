class ProductModel {
  final String shopId;
  final String productName;
  final String sku;
  final String category;
  final String? productPhotoUrl;
  final String? baseUnit;
  final bool allowFractionalSales;
  final bool lowStockWarning;
  final double? warningQty;
  final Map<String, dynamic> dynamicAttributes;

  final String lotIdReference;
  final double initialStock;
  final double costPrice;
  final double salePrice;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.shopId,
    required this.productName,
    required this.sku,
    required this.category,
    this.productPhotoUrl,
    this.baseUnit,
    required this.allowFractionalSales,
    required this.lowStockWarning,
    this.warningQty,
    required this.dynamicAttributes,
    required this.lotIdReference,
    required this.initialStock,
    required this.costPrice,
    required this.salePrice,
    required this.createdAt,
    required this.updatedAt,
  });
}
