import 'package:flutter/material.dart';
import 'package:qistx_app/Models/CartItem.dart';
import 'package:qistx_app/Models/ProductStockModel.dart';
import 'package:qistx_app/View/products/confirmorder.dart';

class Cart extends StatefulWidget {
  final List<Cartitem> cartItems;
  const Cart({super.key, required this.cartItems});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  // ---- Mobile-only filter state (does not affect desktop view) ----
  String _selectedFilter = 'All';
  final List<String> _mobileFilters = const [
    'All',
    'Apparel',
    'Electronics',
    'Packed',
    'Unpacked',
  ];

  double get subtotal {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + (item.product.salePrice * item.quantity),
    );
  }

  // Same validation rules as the Order Inventory "Add Product" popup,
  // just evaluated against the quantity already sitting in this cart row
  // instead of a quantity about to be added.
  String? _quantityErrorFor(Cartitem item) {
    final product = item.product;
    final double quantity = item.quantity;

    if (quantity <= 0) {
      return "Enter a valid quantity";
    }
    if (!product.allowfractionalsales &&
        quantity != quantity.truncateToDouble()) {
      return "Whole ${product.baseUnit} quantities only";
    }
    if (quantity > product.displayStock) {
      return "Only ${product.formattedAvailableStock(0)} available";
    }
    return null;
  }

  // True whenever any line item currently holds a quantity that couldn't
  // actually be checked out (over stock, empty, or a fractional value on a
  // whole-unit-only product). Used to disable Checkout, mirroring how
  // "Add to Cart" is disabled in the Order Inventory popup.
  bool get _hasInvalidQuantities {
    for (final item in widget.cartItems) {
      if (_quantityErrorFor(item) != null) return true;
    }
    return false;
  }

  /// Update the quantity of the cart item at [index]. Called live as the
  /// user types or taps +/- in the row's quantity stepper.
  void _updateQuantity(int index, double quantity) {
    setState(() {
      widget.cartItems[index].quantity = quantity;
    });
  }

  void _removeItem(int index) {
    final removedItem = widget.cartItems[index];

    setState(() {
      widget.cartItems.removeAt(index);
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${removedItem.product.productName} removed from cart"),
        backgroundColor: const Color.fromARGB(221, 231, 10, 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Items visible on the mobile screen after applying the filter chip.
  // NOTE: "Packed"/"Unpacked" assume a matching value in `product.category`.
  // If packing status lives on a different field in ProductStockModel,
  // swap `product.category` below for that field.
  List<MapEntry<int, Cartitem>> get _mobileFilteredEntries {
    final entries = widget.cartItems.asMap().entries.toList();
    if (_selectedFilter == 'All') return entries;
    return entries
        .where(
          (e) =>
              e.value.product.category.toLowerCase() ==
              _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return isDesktop
        ? _buildDesktopView(context, screenWidth)
        : _buildMobileView(context);
  }

  // ============================================================
  // DESKTOP VIEW — unchanged from the original implementation.
  // ============================================================
  Widget _buildDesktopView(BuildContext context, double screenWidth) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fixed Bottom Right Wave Graphic
            Positioned(
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    "assets/images/auth_confirmation_pin.png",
                    width: screenWidth * 0.3,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Scrollable Main Content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 10),

                    const Text(
                      "Cart",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSearchAndCheckout(true),
                    const SizedBox(height: 30),

                    Text(
                      "Showing ${widget.cartItems.length} products",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildCartTable(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Exact Logo Widget with 140x140 sizing and RepaintBoundary
  Widget _buildLogo() {
    return Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        child: SizedBox(
          width: 140,
          height: 140,
          child: Image.asset(
            "assets/Icons/Qist_Logo_trans.png",
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Search Bar and Checkout Button Row (desktop)
  Widget _buildSearchAndCheckout(bool isDesktop) {
    final bool canCheckout =
        widget.cartItems.isNotEmpty && !_hasInvalidQuantities;

    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      children: [
        Expanded(
          flex: isDesktop ? 1 : 0,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search using name and SKU...",
                hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.black87),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 0 : 16, width: isDesktop ? 20 : 0),
        SizedBox(
          height: 50,
          width: isDesktop ? null : double.infinity,
          child: ElevatedButton(
            onPressed: canCheckout
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Confirmorder(cartItems: widget.cartItems),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              disabledBackgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              elevation: 0,
            ),
            child: Text(
              canCheckout
                  ? "Checkout (Subtotal: ${subtotal.toStringAsFixed(0)} PKR)"
                  : widget.cartItems.isEmpty
                  ? "Cart is empty"
                  : "Fix quantity issues to checkout",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // Cart Table Container (White background with shadow) — desktop
  Widget _buildCartTable() {
    if (widget.cartItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 44,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              "Your cart is empty",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const SizedBox(height: 16),
          // List of Products
          ...widget.cartItems.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProductRow(entry.value, entry.key),
            ),
          ),
        ],
      ),
    );
  }

  // Table Headers
  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(flex: 3, child: _headerText("Product")),
        Expanded(flex: 2, child: _headerText("SKU")),
        Expanded(flex: 1, child: _headerText("Category")),
        Expanded(flex: 2, child: _headerText("Quantity")),
        Expanded(flex: 1, child: _headerText("Unit")),
        Expanded(flex: 1, child: _headerText("Price")),
        const SizedBox(width: 40), // Remove icon space
      ],
    );
  }

  Widget _headerText(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.unfold_more, size: 14, color: Colors.black38),
      ],
    );
  }

  // Individual Product Row (with Orange Border) — desktop
  Widget _buildProductRow(Cartitem cartItem, int index) {
    final product = cartItem.product;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF5500), width: 0.8),
      ),
      child: Row(
        children: [
          // Product Name and Image
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child:
                      product.productPhotoUrl != null &&
                          product.productPhotoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            product.productPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                                size: 18,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // SKU
          Expanded(
            flex: 2,
            child: Text(
              product.sku,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),

          // Category
          Expanded(
            flex: 1,
            child: Text(
              product.category,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quantity — increase/decrease stepper with the same stock
          // validation shown in the Order Inventory "Add Product" popup.
          Expanded(
            flex: 2,
            child: _CartQuantityStepper(
              key: ValueKey(product.id),
              cartItem: cartItem,
              errorText: _quantityErrorFor(cartItem),
              onQuantityChanged: (quantity) => _updateQuantity(index, quantity),
            ),
          ),

          // Unit
          Expanded(
            flex: 1,
            child: Text(
              product.baseUnit,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),

          // Price
          Expanded(
            flex: 1,
            child: Text(
              "${(product.salePrice * cartItem.quantity).toStringAsFixed(2)} PKR",
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),

          // Remove from cart
          SizedBox(
            width: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
              onPressed: () => _removeItem(index),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE VIEW — separate, responsive UI matching the new design.
  // ============================================================
  Widget _buildMobileView(BuildContext context) {
    final bool canCheckout =
        widget.cartItems.isNotEmpty && !_hasInvalidQuantities;
    final entries = _mobileFilteredEntries;
    final horizontalPad =
        MediaQuery.of(context).size.width * 0.05; // responsive gutter

    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 30),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cart",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildMobileSearchBar(),
                      const SizedBox(height: 14),

                      _buildMobileFilterChips(),
                      const SizedBox(height: 20),

                      if (entries.isEmpty)
                        _buildMobileEmptyState()
                      else
                        ...entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildMobileCartCard(entry.value, entry.key),
                          ),
                        ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Fixed checkout bar at the bottom of the mobile screen
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  8,
                  horizontalPad,
                  16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: canCheckout
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Confirmorder(cartItems: widget.cartItems),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5500),
                      disabledBackgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      elevation: 0,
                    ),
                    child: Text(
                      canCheckout
                          ? "Checkout (Subtotal: ${subtotal.toStringAsFixed(0)} PKR)"
                          : widget.cartItems.isEmpty
                          ? "Cart is empty"
                          : "Fix quantity issues to checkout",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search using name and SKU...",
          hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.black54, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildMobileFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _mobileFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _mobileFilters[index];
          final bool selected = label == _selectedFilter;
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFFFF5500),
              ),
            ),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedFilter = label);
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFFF5500),
            shape: StadiumBorder(
              side: BorderSide(
                color: const Color(0xFFFF5500).withValues(alpha: 0.6),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildMobileEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 44,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            "Your cart is empty",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Card matching the new mobile design: image, name, price/unit on the
  // left; quantity and line total on the right. Tapping the card opens a
  // bottom sheet to edit quantity or remove the item, keeping the card
  // itself clean like the design.
  Widget _buildMobileCartCard(Cartitem cartItem, int index) {
    final product = cartItem.product;
    final error = _quantityErrorFor(cartItem);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openMobileQuantitySheet(cartItem, index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: error != null
                ? Colors.red.shade300
                : const Color(0xFFFF5500),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  product.productPhotoUrl != null &&
                      product.productPhotoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.productPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Price: PKR ${product.salePrice.toStringAsFixed(0)} / unit",
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "x ${_formatQty(cartItem.quantity)}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "PKR ${(product.salePrice * cartItem.quantity).toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatQty(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  // Bottom sheet used on mobile to adjust quantity or remove the item,
  // triggered by tapping a cart card.
  void _openMobileQuantitySheet(Cartitem cartItem, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            final product = cartItem.product;
            final error = _quantityErrorFor(cartItem);
            final double step = product.allowfractionalsales ? 0.1 : 1;

            void changeQty(double newQty) {
              if (newQty <= 0) return;
              _updateQuantity(index, newQty);
              sheetSetState(() {});
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Price: PKR ${product.salePrice.toStringAsFixed(0)} / ${product.baseUnit}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _sheetStepperButton(
                        icon: Icons.remove,
                        onTap: () {
                          final newVal = cartItem.quantity - step;
                          if (newVal >= step) changeQty(newVal);
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatQty(cartItem.quantity),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _sheetStepperButton(
                        icon: Icons.add,
                        onTap: () => changeQty(cartItem.quantity + step),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _removeItem(index);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      label: Text(
                        "Remove from cart",
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFF5500),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Compact quantity increase/decrease control for a desktop cart row. Same
/// behaviour and stock validation as the stepper in Order Inventory's
/// "Add Product" popup, just sized to sit inside a table row instead of a
/// dialog. Used only by the desktop view.
class _CartQuantityStepper extends StatefulWidget {
  final Cartitem cartItem;
  final String? errorText;
  final ValueChanged<double> onQuantityChanged;

  const _CartQuantityStepper({
    super.key,
    required this.cartItem,
    required this.errorText,
    required this.onQuantityChanged,
  });

  @override
  State<_CartQuantityStepper> createState() => _CartQuantityStepperState();
}

class _CartQuantityStepperState extends State<_CartQuantityStepper> {
  late TextEditingController _controller;

  Productstockmodel get _product => widget.cartItem.product;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatQuantity(widget.cartItem.quantity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatQuantity(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  void _setQuantity(double value) {
    if (value <= 0) return;
    setState(() {
      _controller.text = _formatQuantity(value);
    });
    widget.onQuantityChanged(value);
  }

  void _increment() {
    final double step = _product.allowfractionalsales ? 0.1 : 1;
    _setQuantity(widget.cartItem.quantity + step);
  }

  void _decrement() {
    final double step = _product.allowfractionalsales ? 0.1 : 1;
    final double newValue = widget.cartItem.quantity - step;
    if (newValue >= step) {
      _setQuantity(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5500),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _decrement,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 9),
                  child: Icon(Icons.remove, color: Colors.white, size: 13),
                ),
              ),
              Container(
                width: 42,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: _product.allowfractionalsales,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF5500),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        widget.onQuantityChanged(parsed);
                      }
                    },
                  ),
                ),
              ),
              InkWell(
                onTap: _increment,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 9),
                  child: Icon(Icons.add, color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
