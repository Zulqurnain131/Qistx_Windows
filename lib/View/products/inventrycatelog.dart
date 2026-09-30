import 'package:flutter/material.dart';
import 'package:qistx_app/View/products/add_new_product.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Models/ProductStockModel.dart';
import 'package:qistx_app/Providers/ProductStockProvider.dart';

class Inventrycatelog extends StatefulWidget {
  const Inventrycatelog({super.key});

  @override
  State<Inventrycatelog> createState() => _InventrycatelogState();
}

class _InventrycatelogState extends State<Inventrycatelog> {
  static const kOrange = Color(0xFFFF5500);

  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    "All",
    "Apparel",
    "Electronics",
    "Packed",
    "Unpacked",
  ];
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      context.read<ProductStockProvider>().fetchProducts();
    });
  }

  Future<void> _deleteProduct(ProductStockModel product) async {
    final provider = context.read<ProductStockProvider>();

    await provider.deleteProduct(product.id);

    if (!mounted) return;

    if (provider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete product: ${provider.errorMessage}"),
          backgroundColor: Colors.red,
        ),
      );

      provider.clearError();
    }
  }

  Future<void> _confirmDeleteProduct(ProductStockModel product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text(
          'Are you sure you want to delete "${product.productName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 163, 29, 20),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteProduct(product);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;
    // Extra tier for narrow phones so paddings/fonts scale down instead of
    // overflowing on small devices (e.g. old/compact Android phones).
    final bool isSmallPhone = !isDesktop && screenWidth < 360;
    final double horizontalPadding = isDesktop
        ? 48.0
        : (isSmallPhone ? 14.0 : 20.0);
    final double titleFontSize = isDesktop ? 32 : (isSmallPhone ? 21 : 26);

    final String selectedCategory = _categories[_selectedCategoryIndex];
    final String searchQuery = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      // "+" floating button only on mobile — desktop keeps the header button.
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              backgroundColor: kOrange,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNewProduct()),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                if (isDesktop && constraints.maxWidth > 320)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: RepaintBoundary(
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
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isDesktop ? 16.0 : 30.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (isDesktop && constraints.maxWidth > 350)
                      //   Align(
                      //     alignment: Alignment.topLeft,
                      //     child: RepaintBoundary(
                      //       child: SizedBox(
                      //         width: 90,
                      //         height: 90,
                      //         child: Image.asset(
                      //           "assets/Icons/Qist_Logo_trans.png",
                      //           fit: BoxFit.contain,
                      //         ),
                      //       ),
                      //     ),
                      //   ),

                      // Title & Action Bar — desktop keeps the button beside the
                      // title, mobile only shows the title (the "+" is a FAB now).
                      isDesktop
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Inventory Catalog",
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  _buildAddProductButton(),
                                ],
                              ),
                            )
                          : Text(
                              "Inventory Catalog",
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                      SizedBox(height: isDesktop ? 14 : 24),
                      // Search Bar
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

                      SizedBox(height: isDesktop ? 12 : 16),

                      // Category Filter Chips Row (own horizontal scroll)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...List.generate(_categories.length, (index) {
                              final bool isSelected =
                                  _selectedCategoryIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(_categories[index]),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  selectedColor: kOrange,
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
                                          ? kOrange
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  onSelected: (selected) => setState(
                                    () => _selectedCategoryIndex = index,
                                  ),
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
                              backgroundColor: kOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isDesktop ? 12 : 16),

                      // ab
                      SizedBox(height: isDesktop ? 10 : 15),

                      Expanded(
                        child: Consumer<ProductStockProvider>(
                          builder: (context, provider, child) {
                            final products = provider.products;

                            final List<ProductStockModel> filteredProducts =
                                products.where((product) {
                                  final bool categoryMatch =
                                      selectedCategory == "All" ||
                                      product.category.toLowerCase() ==
                                          selectedCategory.toLowerCase();

                                  final bool searchMatch =
                                      searchQuery.isEmpty ||
                                      product.productName
                                          .toLowerCase()
                                          .contains(searchQuery) ||
                                      product.sku.toLowerCase().contains(
                                        searchQuery,
                                      );

                                  return categoryMatch && searchMatch;
                                }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Showing ${filteredProducts.length} products",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                SizedBox(height: isDesktop ? 10 : 15),

                                Expanded(
                                  child: isDesktop
                                      ? Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              _buildTableHeader(),

                                              Expanded(
                                                child: _buildProductList(
                                                  filteredProducts,
                                                  isSmallPhone,
                                                  isDesktop,
                                                  provider.isLoading,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _buildProductList(
                                          filteredProducts,
                                          isSmallPhone,
                                          isDesktop,
                                          provider.isLoading,
                                        ),
                                ),
                              ],
                            );
                          },
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

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black54,
      fontSize: 13,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Product ↕", style: style)),
          Expanded(flex: 2, child: Text("SKU ↕", style: style)),
          Expanded(flex: 2, child: Text("Category ↕", style: style)),
          Expanded(flex: 2, child: Text("Status ↕", style: style)),
          Expanded(flex: 2, child: Text("Stock ↕", style: style)),
          Expanded(flex: 2, child: Text("Price ↕", style: style)),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProductList(
    List<ProductStockModel> filteredProducts,
    bool isSmallPhone,
    bool isDesktop,
    bool isLoading,
  ) {
    if (isLoading && filteredProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kOrange));
    }

    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          "No products found",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      );
    }
    // baqi aapka existing code
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone ? 12 : 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kOrange.withOpacity(0.5), width: 1.1),
          ),
          child: isDesktop
              ? _buildDesktopRow(product)
              : _buildMobileCard(product),
        );
      },
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddNewProduct()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrange,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Add New Product",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _productImage(ProductStockModel product, {double size = 76}) {
    final hasPhoto =
        product.productPhotoUrl != null && product.productPhotoUrl!.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasPhoto
            ? Image.network(
                product.productPhotoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In Stock':
        return Colors.green;
      case 'Low Stock':
        return Colors.amber.shade700;
      default:
        return Colors.red;
    }
  }

  Widget _statusBadge(String status, {double width = 80, double height = 30}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRow(ProductStockModel product) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              _productImage(product),
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
            // overflow: TextOverflow.ellipsis,
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
            child: _statusBadge(product.stockStatus),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            product.formattedStock,
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
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          tooltip: "Delete Product",
          onPressed: () => _confirmDeleteProduct(product),
        ),
      ],
    );
  }

  /// Matches the mobile screenshot: image + name/SKU/category, a status
  /// pill, then a divider and a stock/price row with icons.
  Widget _buildMobileCard(ProductStockModel product) {
    return SizedBox(
      height: 145, // List item ki fixed height
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: _productImage(product, size: 76),
              ),

              const SizedBox(width: 20),

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
                      "SKU: ${product.sku}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      "Category: ${product.category}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 90),
            child: _statusBadge(product.stockStatus),
          ),

          const SizedBox(height: 8),

          Divider(color: Colors.grey.shade200, height: 1),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: Colors.black45,
              ),
              const SizedBox(width: 4),

              Text(
                "Stock: ${product.formattedStock}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              const Icon(Icons.sell_outlined, size: 14, color: Colors.black45),
              const SizedBox(width: 4),

              Text(
                "Price: ${product.salePrice.toStringAsFixed(0)} PKR",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
