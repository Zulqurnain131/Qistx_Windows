class ProductStockModel {
  final String id;
  final String productName;
  final String sku;
  final String category;
  final String? productPhotoUrl;
  final String baseUnit;
  final double initialStock;
  final double salePrice;
  final double? warningQty;
  final bool allowfractionalsales;

  ProductStockModel({
    required this.id,
    required this.productName,
    required this.sku,
    required this.category,
    this.productPhotoUrl,
    required this.baseUnit,
    required this.initialStock,
    required this.salePrice,
    this.warningQty,
    required this.allowfractionalsales,
  });

  // ---------------------------------------------------------
  // FROM JSON
  // ---------------------------------------------------------

  factory ProductStockModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> batches =
        (json['product_batches'] as List<dynamic>?) ?? [];

    final Map<String, dynamic>? batch = batches.isNotEmpty
        ? batches.first as Map<String, dynamic>
        : null;

    return ProductStockModel(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      productPhotoUrl: json['product_photo_url']?.toString(),
      baseUnit: json['base_unit']?.toString() ?? 'Piece',

      // Database stock
      initialStock: _toDouble(batch?['initial_stock']),

      salePrice: _toDouble(batch?['sale_price']),

      // Database warning quantity
      warningQty: json['warning_qty'] != null
          ? _toDouble(json['warning_qty'])
          : null,
      // IMPORTANT
      allowfractionalsales: json['allow_fractional_sales'] == true,
    );
  }

  // ---------------------------------------------------------
  // DOUBLE CONVERTER
  // ---------------------------------------------------------

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  // ---------------------------------------------------------
  // NORMALIZED UNIT
  // ---------------------------------------------------------

  String get normalizedUnit {
    return baseUnit.toLowerCase().trim();
  }

  // ---------------------------------------------------------
  // STOCK CONVERSION
  //
  // Database mein stock smallest/base unit mein stored hai.
  //
  // Example:
  //
  // 30000 + Kilogram (kg)
  // 30000 / 1000 = 30 kg
  //
  // 240 + Dozen
  // 240 / 12 = 20 dozen
  //
  // 20 + Pair
  // 20 / 2 = 10 pair
  // ---------------------------------------------------------

  double get displayStock {
    switch (normalizedUnit) {
      // -----------------------------------------
      // KILOGRAM
      // -----------------------------------------

      case 'kg':
      case 'kilogram':
      case 'kilograms':
      case 'kilogram (kg)':
        return initialStock / 1000;

      // -----------------------------------------
      // LITER
      // -----------------------------------------

      case 'l':
      case 'liter':
      case 'litre':
      case 'liters':
      case 'litres':
      case 'liter (l)':
      case 'litre (l)':
        return initialStock / 1000;

      // -----------------------------------------
      // DOZEN
      // -----------------------------------------

      case 'dozen':
        return initialStock / 12;

      // -----------------------------------------
      // PAIR
      // -----------------------------------------

      case 'pair':
        return initialStock / 2;

      // -----------------------------------------
      // PIECE
      // -----------------------------------------

      case 'piece':
      case 'pieces':
        return initialStock;

      // -----------------------------------------
      // UNKNOWN UNIT
      // -----------------------------------------

      default:
        return initialStock;
    }
  }

  // ---------------------------------------------------------
  // WARNING QUANTITY CONVERSION
  // ---------------------------------------------------------

  double get displayWarningQty {
    if (warningQty == null) {
      return 0;
    }

    switch (normalizedUnit) {
      // -----------------------------------------
      // KILOGRAM
      // -----------------------------------------

      case 'kg':
      case 'kilogram':
      case 'kilograms':
      case 'kilogram (kg)':
        return warningQty! / 1000;

      // -----------------------------------------
      // LITER
      // -----------------------------------------

      case 'l':
      case 'liter':
      case 'litre':
      case 'liters':
      case 'litres':
      case 'liter (l)':
      case 'litre (l)':
        return warningQty! / 1000;

      // -----------------------------------------
      // DOZEN
      // -----------------------------------------

      case 'dozen':
        return warningQty! / 12;

      // -----------------------------------------
      // PAIR
      // -----------------------------------------

      case 'pair':
        return warningQty! / 2;

      // -----------------------------------------
      // PIECE
      // -----------------------------------------

      case 'piece':
      case 'pieces':
        return warningQty!;

      // -----------------------------------------
      // UNKNOWN UNIT
      // -----------------------------------------

      default:
        return warningQty!;
    }
  }

  // ---------------------------------------------------------
  // FORMATTED STOCK
  // ---------------------------------------------------------

  String get formattedStock {
    final stock = displayStock;

    if (stock == stock.truncateToDouble()) {
      return '${stock.toInt()} $baseUnit';
    }

    return '${stock.toStringAsFixed(2)} $baseUnit';
  }

  // ---------------------------------------------------------
  // FORMATTED WARNING QUANTITY
  // ---------------------------------------------------------

  String get formattedWarningQty {
    if (warningQty == null) {
      return 'N/A';
    }

    final qty = displayWarningQty;

    if (qty == qty.truncateToDouble()) {
      return '${qty.toInt()} $baseUnit';
    }

    return '${qty.toStringAsFixed(2)} $baseUnit';
  }

  // ---------------------------------------------------------
  // STOCK STATUS
  // ---------------------------------------------------------

  String get stockStatus {
    // Stock completely finished
    if (displayStock <= 0) {
      return 'Out of Stock';
    }

    // Stock warning level par ya us se kam hai
    if (warningQty != null && displayStock <= displayWarningQty) {
      return 'Low Stock';
    }

    // Stock warning level se zyada hai
    return 'In Stock';
  }

  double getAvailableStock(double cartQuantity) {
    final available = displayStock - cartQuantity;

    // Negative stock kabhi show nahi karna
    return available < 0 ? 0 : available;
  }

  // ---------------------------------------------------------
  // FORMATTED AVAILABLE STOCK
  // ---------------------------------------------------------
  //////////////////// Stock:40 Pack
  // String formattedAvailableStock(double cartQuantity) {
  //   final stock = getAvailableStock(cartQuantity);

  //   if (stock == stock.truncateToDouble()) {
  //     return '${stock.toInt()} $baseUnit';
  //   }

  //   return '${stock.toStringAsFixed(2)} $baseUnit';
  // }

  String formattedAvailableStock(double cartQuantity) {
    final stock = getAvailableStock(cartQuantity);

    if (stock == stock.truncateToDouble()) {
      return stock.toInt().toString();
    }

    return stock.toStringAsFixed(2);
  }
  // ---------------------------------------------------------
  // TEMPORARY STOCK STATUS
  // ---------------------------------------------------------

  String availableStockStatus(double cartQuantity) {
    final stock = getAvailableStock(cartQuantity);

    if (stock <= 0) {
      return 'Out of Stock';
    }

    if (warningQty != null && stock <= displayWarningQty) {
      return 'Low Stock';
    }

    return 'In Stock';
  }
}
