import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Models/CartItem.dart';
import 'package:qistx_app/Models/ProductStockModel.dart';
import 'package:qistx_app/Providers/ProductStockProvider.dart';
import 'package:qistx_app/View/products/cart.dart';

class Orderinventory extends StatefulWidget {
  const Orderinventory({super.key});
  @override
  State<Orderinventory> createState() => _OrderinventoryState();
}

class _AddProductSheet extends StatefulWidget {
  final Productstockmodel product;
  final double cartQuantity;
  final bool isMobile;
  final ScrollController? scrollController;
  final void Function(double quantity) onAddToCart;

  const _AddProductSheet({
    required this.product,
    this.cartQuantity = 0,
    required this.isMobile,
    required this.onAddToCart,
    this.scrollController,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  late double _quantity;
  late TextEditingController _quantityController;

  double get _availableStock =>
      widget.product.getAvailableStock(widget.cartQuantity);

  String? get _quantityError {
    if (_quantity <= 0) return "Enter a valid quantity";
    if (!widget.product.allowfractionalsales &&
        _quantity != _quantity.truncateToDouble()) {
      return "Whole ${widget.product.baseUnit} quantities only";
    }
    if (_quantity > _availableStock) {
      return "Only ${widget.product.formattedAvailableStock(widget.cartQuantity)} available";
    }
    return null;
  }

  bool get _isQuantityValid => _quantityError == null;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
    _quantityController = TextEditingController(
      text: widget.product.allowfractionalsales ? '1.0' : '1',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(double value) {
    if (value <= 0) return;
    setState(() {
      _quantity = value;
      _quantityController.text = value == value.truncateToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool m = widget.isMobile; // shorthand: mobile styling on/off
    final double subtotal = product.salePrice * _quantity;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        m ? 20 : 24,
        m ? 12 : 24,
        m ? 20 : 24,
        m ? 25 : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m) ...[
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Header
          m
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add Product",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      "Add Product",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: m ? 10 : 16),

          if (m) ...[
            _buildImage(product, height: 200, radius: 14),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.productName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.sell_outlined,
              "Price: PKR ${product.salePrice.toStringAsFixed(0)} / ${product.baseUnit}",
              iconSize: 18,
              fontSize: 14,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.inventory_2_outlined,
              "Available: ${product.formattedAvailableStock(widget.cartQuantity)}",
              iconSize: 18,
              fontSize: 14,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF5500).withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(product, height: 180, radius: 10),
                  const SizedBox(height: 12),
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.sell_outlined,
                    "Price: PKR ${product.salePrice.toStringAsFixed(0)} / ${product.baseUnit}",
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.inventory_2_outlined,
                    "Stock Remaining: ${product.formattedAvailableStock(widget.cartQuantity)}",
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: m ? 22 : 20),

          if (m) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quantity",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Quantity Stepper
          Container(
            height: m ? 50 : 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5500),
              borderRadius: BorderRadius.circular(m ? 25 : 22),
            ),
            child: Row(
              mainAxisAlignment: m
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: m ? MainAxisSize.max : MainAxisSize.min,
              children: [
                _stepperButton(
                  Icons.remove,
                  mobile: m,
                  onTap: () {
                    final step = product.allowfractionalsales ? 0.1 : 1.0;
                    final newValue = _quantity - step;
                    if (newValue >= (product.allowfractionalsales ? 0.1 : 1)) {
                      _updateQuantity(newValue);
                    }
                  },
                ),
                Container(
                  width: m ? 100 : 75,
                  height: m ? 38 : 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(m ? 20 : 17),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: product.allowfractionalsales,
                      ),
                      style: m
                          ? null
                          : const TextStyle(
                              color: Color(0xFFFF5500),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: !m,
                        contentPadding: m
                            ? const EdgeInsets.only(bottom: 10)
                            : EdgeInsets.zero,
                      ),
                      onChanged: (value) => setState(
                        () => _quantity = double.tryParse(value) ?? 0,
                      ),
                    ),
                  ),
                ),
                _stepperButton(
                  Icons.add,
                  mobile: m,
                  onTap: () {
                    final step = product.allowfractionalsales ? 0.1 : 1.0;
                    _updateQuantity(_quantity + step);
                  },
                ),
              ],
            ),
          ),

          if (_quantityError != null) ...[
            const SizedBox(height: 10),
            Text(
              _quantityError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          SizedBox(height: m ? 18 : 16),

          m
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Item Subtotal: PKR ${subtotal.toStringAsFixed(0)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  "Item Subtotal: PKR ${subtotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

          SizedBox(height: m ? 18 : 16),

          SizedBox(
            width: double.infinity,
            height: m ? 52 : 48,
            child: ElevatedButton(
              onPressed: _isQuantityValid
                  ? () => widget.onAddToCart(_quantity)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                disabledBackgroundColor: m ? Colors.grey : Colors.grey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(m ? 12 : 10),
                ),
              ),
              child: m
                  ? const Text(
                      "Add to Cart",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Add to Cart",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(
    Productstockmodel product, {
    required double height,
    required double radius,
  }) {
    final iconSize = height > 150 ? 40.0 : 32.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: (product.productPhotoUrl?.isNotEmpty ?? false)
            ? Image.network(
                product.productPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(iconSize),
              )
            : _placeholder(iconSize),
      ),
    );
  }

  Widget _placeholder(double iconSize) => Container(
    color: Colors.grey.shade200,
    child: Center(
      child: Icon(Icons.image_outlined, size: iconSize, color: Colors.grey),
    ),
  );

  Widget _infoRow(
    IconData icon,
    String text, {
    double iconSize = 14,
    double fontSize = 12.5,
  }) => Row(
    children: [
      Icon(icon, size: iconSize, color: const Color(0xFFFF5500)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, color: Colors.black87),
        ),
      ),
    ],
  );

  Widget _stepperButton(
    IconData icon, {
    required bool mobile,
    required VoidCallback onTap,
  }) {
    if (mobile) {
      return IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}
// ============================================================
// MOBILE ONLY - ADD PRODUCT BOTTOM SHEET
// Desktop UI is completely separate and untouched.
// ============================================================

class _MobileAddProductSheet extends StatefulWidget {
  final Productstockmodel product;
  final double cartQuantity;
  final void Function(double quantity) onAddToCart;

  const _MobileAddProductSheet({
    required this.product,
    this.cartQuantity = 0,
    required this.onAddToCart,
  });

  @override
  State<_MobileAddProductSheet> createState() => _MobileAddProductSheetState();
}

class _MobileAddProductSheetState extends State<_MobileAddProductSheet> {
  late double _quantity;
  late TextEditingController _quantityController;

  double get _availableStock =>
      widget.product.getAvailableStock(widget.cartQuantity);

  String? get _quantityError {
    if (_quantity <= 0) {
      return "Enter a valid quantity";
    }

    if (!widget.product.allowfractionalsales &&
        _quantity != _quantity.truncateToDouble()) {
      return "Whole ${widget.product.baseUnit} quantities only";
    }

    if (_quantity > _availableStock) {
      return "Only ${widget.product.formattedAvailableStock(widget.cartQuantity)} available";
    }

    return null;
  }

  bool get _isQuantityValid => _quantityError == null;

  @override
  void initState() {
    super.initState();

    _quantity = 1;

    _quantityController = TextEditingController(
      text: widget.product.allowfractionalsales ? '1.0' : '1',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(double value) {
    if (value <= 0) return;

    setState(() {
      _quantity = value;

      _quantityController.text = value == value.truncateToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);

      _quantityController.selection = TextSelection.collapsed(
        offset: _quantityController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final double subtotal = product.salePrice * _quantity;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,

        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------
            const SizedBox(
              height: 24,
              child: Center(
                child: Text(
                  "Add Product",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // PRODUCT CARD
            // --------------------------------------------------
            Container(
              width: 250,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF5500), width: 1),
              ),
              child: Column(
                children: [
                  // PRODUCT IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: double.infinity,
                      height: 100,
                      child: (product.productPhotoUrl?.isNotEmpty ?? false)
                          ? Image.network(
                              product.productPhotoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 9),

                  // PRODUCT NAME
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // PRICE
                  Row(
                    children: [
                      const Icon(
                        Icons.sell_outlined,
                        size: 11,
                        color: Color(0xFFFF5500),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Price: PKR ${product.salePrice.toStringAsFixed(0)} / ${product.baseUnit}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // STOCK
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 11,
                        color: Color(0xFFFF5500),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Stock Remaining: ${product.formattedAvailableStock(widget.cartQuantity)}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ------------------------------------------------
                  // QUANTITY STEPPER
                  // ------------------------------------------------
                  Container(
                    height: 19,
                    width: 108,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5500),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        // MINUS
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final step = product.allowfractionalsales
                                  ? 0.1
                                  : 1.0;

                              final newValue = _quantity - step;

                              if (newValue >=
                                  (product.allowfractionalsales ? 0.1 : 1)) {
                                _updateQuantity(newValue);
                              }
                            },
                            child: const Center(
                              child: Icon(
                                Icons.remove,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // QUANTITY
                        Container(
                          width: 42,
                          height: 19,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: _quantityController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: product.allowfractionalsales,
                            ),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFFF5500),
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _quantity = double.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),

                        // PLUS
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final step = product.allowfractionalsales
                                  ? 0.1
                                  : 1.0;

                              _updateQuantity(_quantity + step);
                            },
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // ERROR
            // --------------------------------------------------
            if (_quantityError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _quantityError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // SUBTOTAL
            // --------------------------------------------------
            Text(
              "Item Subtotal: PKR ${subtotal.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // ADD TO CART BUTTON
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: _isQuantityValid
                    ? () => widget.onAddToCart(_quantity)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5500),
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Add to Cart",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: Colors.white, size: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MOBILE PRODUCT CARD WIDGET  (full-width vertical list card)
class _MobileProductCard extends StatelessWidget {
  final Productstockmodel product;
  final double cartQuantity;
  final VoidCallback onTap;

  const _MobileProductCard({
    required this.product,
    this.cartQuantity = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stockLabel = product.formattedAvailableStock(cartQuantity);
    print("StockLablel:$stockLabel");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF5500), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildImage()),

            const SizedBox(height: 10),

            _label(
              product.productName,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              maxLines: 1,
            ),

            const SizedBox(height: 6),

            _label(
              "PKR ${product.salePrice.toStringAsFixed(0)} / ${product.baseUnit}",
              fontSize: 13,
              fontWeight: FontWeight.normal,
              maxLines: 1,
            ),

            const SizedBox(height: 5),

            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Stock: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: stockLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        child: (product.productPhotoUrl?.isNotEmpty ?? false)
            ? Image.network(
                product.productPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _label(
    String text, {
    required double fontSize,
    required FontWeight fontWeight,
    int? maxLines,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.black87,
      ),
    );
  }
}

// ============================================================
// MAIN STATE
// ============================================================
class _OrderinventoryState extends State<Orderinventory> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    "All",
    "Apparel",
    "Electronics",
    "Packed",
    "Unpacked",
  ];

  List<Cartitem> cartItems = [];

  int _selectedCategoryIndex = 0;

  int get cartItemCount => cartItems.length;

  double _cartQuantityFor(String productId) {
    final index = cartItems.indexWhere((item) => item.product.id == productId);
    return index != -1 ? cartItems[index].quantity : 0;
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<Productstockprovider>().fetchProducts();
    });
  }

  void _addToCart(Productstockmodel product, double quantity) {
    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    final existingQuantity = index != -1 ? cartItems[index].quantity : 0;
    final totalQuantity = existingQuantity + quantity;

    if (totalQuantity > product.displayStock) {
      _showSnackBar("Quantity cannot exceed available stock", Colors.red);
      return;
    }

    setState(() {
      if (index != -1) {
        cartItems[index].quantity += quantity;
      } else {
        cartItems.add(Cartitem(product: product, quantity: quantity));
      }
    });

    if (!mounted) return;
    _showSnackBar("${product.productName} added to cart", Colors.green);
  }

  // ============================================================
  // Mobile -> Bottom Sheet | Desktop -> Dialog
  // Both wrap the same shared _AddProductSheet widget.
  // ============================================================
  void _showAddProductDialog(Productstockmodel product) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    final cartQty = _cartQuantityFor(product.id);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.55),
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.55,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: _MobileAddProductSheet(
                product: product,
                cartQuantity: cartQty,
                onAddToCart: (quantity) {
                  Navigator.pop(sheetContext);
                  _addToCart(product, quantity);
                },
              ),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _AddProductSheet(
              product: product,
              cartQuantity: cartQty,
              isMobile: false,
              onAddToCart: (quantity) {
                Navigator.pop(dialogContext);
                _addToCart(product, quantity);
              },
            ),
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,

      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFF5500),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Cart(cartItems: cartItems),
                  ),
                );

                if (!mounted) return;
                setState(() {});
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 26,
                  ),

                  if (cartItemCount > 0)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$cartItemCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF5500),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                if (isDesktop && constraints.maxWidth > 320)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.85,
                        child: Image.asset(
                          "assets/images/auth_confirmation_pin.png",
                          width: screenWidth * 0.32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48.0 : 20.0,
                    // vertical: 30.0,
                    vertical: isDesktop ? 16.0 : 30.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (isDesktop && constraints.maxWidth > 350)
                      //   Align(
                      //     alignment: Alignment.topLeft,
                      //     child: SizedBox(
                      //       width: 90,
                      //       height: 90,
                      //       child: Image.asset(
                      //         "assets/Icons/Qist_Logo_trans.png",
                      //         fit: BoxFit.contain,
                      //       ),
                      //     ),
                      //   ),
                      if (isDesktop)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Order Inventory",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Use search or categories to quickly add items, verify prices and stock, and proceed to checkout.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              _buildCartButton(),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Order Inventory",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      // const SizedBox(height: 24),
                      SizedBox(height: isDesktop ? 15 : 24),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Search using name and SKU...",
                            hintStyle: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black54,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      // const SizedBox(height: 16),
                      SizedBox(height: isDesktop ? 15 : 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...List.generate(_categories.length, (index) {
                              final isSelected =
                                  _selectedCategoryIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(_categories[index]),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  selectedColor: const Color(0xFFFF5500),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFFFF5500)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  onSelected: (bool selected) {
                                    setState(
                                      () => _selectedCategoryIndex = index,
                                    );
                                  },
                                ),
                              );
                            }),
                            const SizedBox(width: 6),
                            ActionChip(
                              avatar: const Icon(
                                Icons.filter_list,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Filter",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              backgroundColor: const Color(0xFFFF5500),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 16),
                      SizedBox(height: isDesktop ? 15 : 16),
                      Consumer<Productstockprovider>(
                        builder: (context, provider, child) {
                          final searchQuery = _searchController.text
                              .trim()
                              .toLowerCase();

                          final selectedCategory =
                              _categories[_selectedCategoryIndex];

                          final filteredProducts = provider.products.where((
                            product,
                          ) {
                            final categoryMatch =
                                selectedCategory == "All" ||
                                product.category.toLowerCase() ==
                                    selectedCategory.toLowerCase();

                            final searchMatch =
                                searchQuery.isEmpty ||
                                product.productName.toLowerCase().contains(
                                  searchQuery,
                                ) ||
                                product.sku.toLowerCase().contains(searchQuery);

                            return categoryMatch && searchMatch;
                          }).toList();

                          return Text(
                            "Showing ${filteredProducts.length} products",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      // const SizedBox(height: 15),
                      SizedBox(height: isDesktop ? 15 : 15),
                      Expanded(
                        child: Container(
                          padding: isDesktop
                              ? const EdgeInsets.all(14)
                              : EdgeInsets.zero,
                          decoration: isDesktop
                              ? BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : null,
                          child: Column(
                            children: [
                              if (isDesktop)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 16,
                                    left: 12,
                                    right: 12,
                                  ),
                                  child: Row(
                                    children: const [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "Product ↕",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "SKU ↕",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Category ↕",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Status ↕",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Stock ↕",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Price ↕",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      // SizedBox(width: 40),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: Consumer<Productstockprovider>(
                                  builder: (context, provider, child) {
                                    final products = provider.products;

                                    final searchQuery = _searchController.text
                                        .trim()
                                        .toLowerCase();

                                    final selectedCategory =
                                        _categories[_selectedCategoryIndex];

                                    final filteredProducts = products.where((
                                      product,
                                    ) {
                                      final categoryMatch =
                                          selectedCategory == "All" ||
                                          product.category.toLowerCase() ==
                                              selectedCategory.toLowerCase();

                                      final searchMatch =
                                          searchQuery.isEmpty ||
                                          product.productName
                                              .toLowerCase()
                                              .contains(searchQuery) ||
                                          product.sku.toLowerCase().contains(
                                            searchQuery,
                                          );

                                      return categoryMatch && searchMatch;
                                    }).toList();

                                    // Loading
                                    if (provider.isLoading &&
                                        products.isEmpty) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFFF5500),
                                        ),
                                      );
                                    }

                                    // Empty
                                    if (products.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "No products found",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }

                                    // Products
                                    return isDesktop
                                        ? _buildDesktopList(filteredProducts)
                                        : _buildMobileList(filteredProducts);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE: FULL-WIDTH VERTICAL LIST
  // (Separate function, kept isolated from the desktop table below.
  // Every card here is just `_MobileProductCard` — the only thing
  // that changed is which builder this switch calls.)
  // ============================================================
  Widget _buildMobileList(List<Productstockmodel> filteredProducts) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];

        return _MobileProductCard(
          product: product,
          cartQuantity: _cartQuantityFor(product.id),
          onTap: () => _showAddProductDialog(product),
        );
      },
    );
  }

  // ============================================================
  // DESKTOP: TABLE LAYOUT — untouched
  // ============================================================
  Widget _buildDesktopList(List<Productstockmodel> filteredProducts) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final cartQty = _cartQuantityFor(product.id);
        final stockLabel = product.formattedAvailableStock(cartQty);
        final statusLabel = product.availableStockStatus(cartQty);

        return GestureDetector(
          onTap: () => _showAddProductDialog(product),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFF5500).withOpacity(0.5),
                width: 1.1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: (product.productPhotoUrl?.isNotEmpty ?? false)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  product.productPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          product.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    product.sku,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    product.category,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        color: statusLabel == 'In Stock'
                            ? Colors.green
                            : statusLabel == 'Low Stock'
                            ? Colors.amber.shade700
                            : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    stockLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${product.salePrice.toStringAsFixed(2)} PKR",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CART BUTTON
  // ============================================================
  Widget _buildCartButton({bool isMobile = false}) {
    final cartIconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isMobile ? Icons.shopping_cart : Icons.shopping_cart_outlined,
          color: Color(0xFFFF5500),
          size: isMobile ? 26 : 22,
        ),
        if (cartItemCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5500),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$cartItemCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );

    if (isMobile) {
      return InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Cart(cartItems: cartItems)),
          );
          if (!mounted) return;
          setState(() {});
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: cartIconWidget,
        ),
      );
    }

    return SizedBox(
      height: 48,
      width: 170,
      child: OutlinedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Cart(cartItems: cartItems)),
          );
          if (!mounted) return;
          setState(() {});
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFFF5500), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            cartIconWidget,
            const SizedBox(width: 15),
            const Text(
              "Cart",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF5500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
