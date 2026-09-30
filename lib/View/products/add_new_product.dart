import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qistx_app/Models/productmodel.dart';
import 'package:qistx_app/View/products/customer_khata.dart';
import 'package:qistx_app/View/products/inventrycatelog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddNewProduct extends StatefulWidget {
  final String? customerId;
  const AddNewProduct({super.key, this.customerId});

  @override
  State<AddNewProduct> createState() => _AddNewProductState();
}

class _AddNewProductState extends State<AddNewProduct> {
  final ScrollController pageScrollController = ScrollController();
  bool _isSaving = false;
  ///// Controllers///
  final productNameController = TextEditingController();
  final skuController = TextEditingController();
  final lotIdController = TextEditingController();
  final initialStockController = TextEditingController();
  final costPriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final warningQtyController = TextEditingController();

  final sizeController = TextEditingController();
  final brandNameController = TextEditingController();
  final expiryDateController = TextEditingController();
  final netContentController = TextEditingController();
  final modelController = TextEditingController();
  final warrantyController = TextEditingController();
  //// Controller End ///

  // Theme Colors
  final Color primaryOrange = const Color(0xFFFF6600);
  final Color greyBackground = const Color(0xFFE0E0E0);
  String? selectedBaseUnit;

  String? selectedColor;
  String? selectedGender;
  String? selectedgrade;
  // Wholesale Unit Conversions
  List<Map<String, dynamic>> wholesaleConversions = [];
  final List<String> gradelist = ['A', 'B', 'C', 'D'];
  // Base Unit List
  final List<String> baseUnitList = ['Piece', 'Dozen', 'Pair'];

  // Apparel Size List

  // Apparel Color List
  final List<String> colorList = [
    'Black',
    'White',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Grey',
  ];

  // Apparel Gender List
  final List<String> genderList = ['Men', 'Women', 'Unisex', 'Kids'];

  bool allowFractionalSales = true;
  bool lowStockWarning = false;

  Uint8List? _selectedImageBytes; // Web Support
  File? _selectedImageFile;

  // Selected Category & Product Subtype
  String? selectedCategory = 'Apparel';
  String productType =
      'Unpacked Products'; // Unpacked Products vs Packed Products

  @override
  void initState() {
    super.initState();
    // _saveCurrentScreen();

    productNameController.addListener(_updateAutoSku);
  }

  /// Update Sku
  void _updateAutoSku() {
    final productName = productNameController.text.trim();

    if (productName.isEmpty || selectedCategory == null) {
      skuController.clear();
      lotIdController.clear();
      return;
    }

    final sku = generateSku(
      productName: productName,
      category: selectedCategory!,
    );

    skuController.text = sku;

    final lotId = generateLotId(sku);

    lotIdController.text = lotId;
  }

  ////////////// Save Data Function
  Future<bool> _saveProduct() async {
    print("Product Function Called");
    if (_isSaving) return false;

    final productName = productNameController.text.trim();
    final sku = skuController.text.trim();
    final initialStockText = initialStockController.text.trim();
    final costPriceText = costPriceController.text.trim();
    final salePriceText = salePriceController.text.trim();

    // ---------------- VALIDATION ----------------

    if (productName.isEmpty) {
      _showMessage("Please enter Product Name");
      return false;
    }

    if (selectedCategory == null) {
      _showMessage("Please select Category");
      return false;
    }

    if (selectedBaseUnit == null) {
      _showMessage("Please select Base Unit");
      return false;
    }
    await generateUniqueSku(
      productName: productName,
      category: selectedCategory!,
    );

    // Show generated SKU in UI
    skuController.text = sku;
    final lotId = generateLotId(sku);

    lotIdController.text = lotId;

    final double? enteredInitialStock = double.tryParse(initialStockText);
    final double? costPrice = double.tryParse(costPriceText);
    final double? salePrice = double.tryParse(salePriceText);

    if (enteredInitialStock == null || enteredInitialStock < 0) {
      _showMessage("Please enter a valid Initial Stock");
      return false;
    }

    if (costPrice == null || costPrice < 0) {
      _showMessage("Please enter a valid Cost Price");
      return false;
    }

    if (salePrice == null || salePrice < 0) {
      _showMessage("Please enter a valid Sale Price");
      return false;
    }
    // Convert entered stock into smallest/base storage unit
    final double initialStock = calculateInitialStock(
      enteredStock: enteredInitialStock,
      baseUnit: selectedBaseUnit!,
    );

    double? warningQty;

    if (lowStockWarning) {
      warningQty = double.tryParse(warningQtyController.text.trim());

      if (warningQty == null || warningQty < 0) {
        _showMessage("Please enter a valid Warning Quantity");
        return false;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // ---------------- SHOP ID ----------------

      final shopId = await getShopId();

      if (shopId == null) {
        throw Exception("Active shop not found");
      }

      // ---------------- CHECK SKU ----------------

      if (await skuExists(sku)) {
        _showMessage("This SKU already exists");
        return false;
      }

      // ---------------- IMAGE UPLOAD ----------------

      String? productPhotoUrl;

      if (_selectedImageBytes != null) {
        productPhotoUrl = await _uploadProductImage(shopId);

        if (productPhotoUrl == null) {
          throw Exception("Product image upload failed");
        }
      }

      // ---------------- DYNAMIC ATTRIBUTES ----------------

      final dynamicAttributes = buildDynamicAttributes();

      // ---------------- PRODUCT MODEL ----------------

      final now = DateTime.now();

      final product = ProductModel(
        shopId: shopId,
        productName: productName,
        sku: sku,
        category: selectedCategory!,
        productPhotoUrl: productPhotoUrl,
        baseUnit: selectedBaseUnit,
        allowFractionalSales: selectedCategory == 'Unpacked'
            ? allowFractionalSales
            : false,
        lowStockWarning: lowStockWarning,
        warningQty: warningQty,
        dynamicAttributes: dynamicAttributes,
        lotIdReference: lotId,
        initialStock: initialStock,
        costPrice: costPrice,
        salePrice: salePrice,
        createdAt: now,
        updatedAt: now,
      );

      // ---------------- INSERT PRODUCT ----------------

      final productResponse = await supabase
          .from('products')
          .insert({
            'shop_id': product.shopId,
            'product_name': product.productName,
            'sku': product.sku,
            'category': product.category.toLowerCase(),
            'product_photo_url': product.productPhotoUrl,
            'base_unit': product.baseUnit,
            'allow_fractional_sales': product.allowFractionalSales,
            'low_stock_warning': product.lowStockWarning,
            'warning_qty': product.warningQty,
            'dynamic_attributes': product.dynamicAttributes,
            'created_at': product.createdAt.toIso8601String(),
            'updated_at': product.updatedAt.toIso8601String(),
          })
          .select('id')
          .single();

      final productId = productResponse['id'];

      // ---------------- INSERT BATCH ----------------

      await supabase.from('product_batches').insert({
        'product_id': productId,
        'lot_id_reference': product.lotIdReference,
        'initial_stock': product.initialStock,
        'cost_price': product.costPrice,
        'sale_price': product.salePrice,
        'created_at': product.createdAt.toIso8601String(),
        'updated_at': product.updatedAt.toIso8601String(),
      });

      // ---------------- INSERT WHOLESALE CONVERSIONS ----------------

      if (wholesaleConversions.isNotEmpty) {
        final conversions = wholesaleConversions.map((conversion) {
          return {
            'product_id': productId,
            'unit_name': conversion['unitName'],
            'multiplier': conversion['multiplier'],
            'created_at': now.toIso8601String(),
          };
        }).toList();

        await supabase.from('product_unit_conversions').insert(conversions);
      }

      if (!mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product added successfully"),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } catch (e) {
      debugPrint("SAVE PRODUCT ERROR: $e");

      if (!mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add product: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  ///// Saving Product IN Next Screen
  Future<void> _handleAddProduct() async {
    if (_isSaving) return;

    final productSaved = await _saveProduct();

    if (!mounted) return;

    if (productSaved) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => CustomerKhata(customerId: widget.customerId),
      //   ),
      // );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Inventrycatelog()),
      );
    }
  }

  /// Save Picture
  Future<String?> _uploadProductImage(String shopId) async {
    if (_selectedImageBytes == null) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}.jpg';

      final filePath = '$shopId/$fileName';

      await supabase.storage
          .from('product-assets')
          .uploadBinary(
            filePath,
            _selectedImageBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final publicUrl = supabase.storage
          .from('product-assets')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Product image upload error: $e');
      return null;
    }
  }

  //// Get Shop ID
  Future<String?> getShopId() async {
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await supabase
        .from('shops')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    return result?['id']?.toString();
  }

  ///// Genrate Sku Function
  String generateSku({required String productName, required String category}) {
    final name = productName.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]+'),
      '-',
    );

    final cat = category.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]+'),
      '-',
    );

    final digits = Random().nextInt(9000) + 1000;

    return '$name-$cat-$digits';
  }

  Future<bool> skuExists(String sku) async {
    final supabase = Supabase.instance.client;

    final result = await supabase
        .from('products')
        .select('id')
        .eq('sku', sku)
        .maybeSingle();

    return result != null;
  }

  Future<String> generateUniqueSku({
    required String productName,
    required String category,
  }) async {
    String sku;

    do {
      sku = generateSku(productName: productName, category: category);
    } while (await skuExists(sku));

    return sku;
  }

  //// Genrate LOT ID
  String generateLotId(String sku) {
    final now = DateTime.now();

    final yy = now.year.toString().substring(2);
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');

    return '$yy$mm$dd-$sku';
  }

  /// Base Unit Multiplilier
  double getBaseUnitMultiplier(String unit) {
    switch (unit) {
      case 'Piece':
        return 1;

      case 'Dozen':
        return 12;

      case 'Pair':
        return 2;

      case 'Kilogram (kg)':
        return 1000;

      case 'Gram (g)':
        return 1;

      case 'Liter (L)':
        return 1000;

      case 'Milliliter (ml)':
        return 1;

      case 'Pack':
        return 1;

      case 'Box':
        return 1;

      case 'Carton':
        return 1;

      case 'Set':
        return 1;

      default:
        return 1;
    }
  }

  //// Initial Stock Function
  double calculateInitialStock({
    required double enteredStock,
    required String baseUnit,
  }) {
    final multiplier = getBaseUnitMultiplier(baseUnit);

    return enteredStock * multiplier;
  }

  //// Dynamic Attributes ////
  Map<String, dynamic> buildDynamicAttributes() {
    if (selectedCategory == 'Apparel') {
      return {
        'size': sizeController.text.trim(),
        'color': selectedColor,
        'brand': brandNameController.text.trim(),
        'gender': selectedGender,
      };
    }

    if (selectedCategory == 'Unpacked') {
      return {
        'grade': selectedgrade,
        'expiry_date': expiryDateController.text.trim(),
      };
    }

    if (selectedCategory == 'Packed') {
      return {
        'brand': brandNameController.text.trim(),
        'net_content': netContentController.text.trim(),
        'expiry_date': expiryDateController.text.trim(),
      };
    }

    if (selectedCategory == 'Electronics') {
      return {
        'brand': brandNameController.text.trim(),
        'model': modelController.text.trim(),
        'warranty_months': warrantyController.text.trim(),
      };
    }

    return {};
  }

  //// Base Unit Functions
  Future<void> _showWholesaleConversionDialog({int? editIndex}) async {
    final bool isEditing = editIndex != null;

    final TextEditingController unitNameController = TextEditingController(
      text: isEditing ? wholesaleConversions[editIndex!]['unitName'] : '',
    );

    final TextEditingController multiplierController = TextEditingController(
      text: isEditing
          ? wholesaleConversions[editIndex!]['multiplier'].toString()
          : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEditing ? "Edit Unit Conversion" : "Add Unit Conversion",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isEditing
                        ? "Update the unit name or conversion multiplier."
                        : "Set a wholesale unit and its conversion multiplier.",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: unitNameController,
                  decoration: InputDecoration(
                    hintText: "Unit Name",
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: multiplierController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: "Multiplier",
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black54),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final String unitName = unitNameController.text.trim();

                final String multiplierText = multiplierController.text.trim();

                if (unitName.isEmpty || multiplierText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter Unit Name and Multiplier"),
                    ),
                  );
                  return;
                }

                final double? multiplier = double.tryParse(multiplierText);

                if (multiplier == null || multiplier <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid multiplier"),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (isEditing) {
                    // Update existing conversion
                    wholesaleConversions[editIndex!] = {
                      'unitName': unitName,
                      'multiplier': multiplier,
                    };
                  } else {
                    // Add new conversion
                    wholesaleConversions.add({
                      'unitName': unitName,
                      'multiplier': multiplier,
                    });
                  }
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isEditing ? "Update" : "Save"),
            ),
          ],
        );
      },
    );

    unitNameController.dispose();
    multiplierController.dispose();
  }

  // Future<void> _saveCurrentScreen() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString("last_screen", "add_new_product");
  //   } catch (e) {
  //     debugPrint("SharedPreferences Error: $e");
  //   }
  // }

  /// image compress function
  Future<Uint8List?> compressTo300KB(Uint8List bytes) async {
    // Already under 300 KB
    if (bytes.lengthInBytes <= 300 * 1024) {
      return bytes;
    }

    img.Image? image = img.decodeImage(bytes);

    if (image == null) return null;

    // Resize large images
    if (image.width > 1280) {
      image = img.copyResize(image, width: 1280);
    }

    int quality = 90;
    Uint8List compressedBytes;

    do {
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      quality -= 5;
    } while (compressedBytes.lengthInBytes > 300 * 1024 && quality >= 10);

    return compressedBytes;
  }

  /// Cross-platform image picker handling Windows desktop, Web, and Mobile seamlessly.
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;

      Uint8List? originalBytes;

      // Web / Desktop
      if (file.bytes != null) {
        originalBytes = file.bytes;
      }
      // Mobile / fallback
      else if (file.path != null) {
        originalBytes = await File(file.path!).readAsBytes();
      }

      if (originalBytes == null) {
        return;
      }

      // Compress only if image is larger than 300 KB
      final Uint8List? compressedBytes = await compressTo300KB(originalBytes);

      if (compressedBytes == null) {
        debugPrint("Image compression failed.");
        return;
      }

      debugPrint(
        "Original size: "
        "${(originalBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
      );

      debugPrint(
        "Final size: "
        "${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
      );

      setState(() {
        // Store compressed image bytes
        _selectedImageBytes = compressedBytes;

        // File ki zaroorat ab nahi
        _selectedImageFile = null;
      });
    } catch (e) {
      debugPrint("Image picking error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isShortScreen = constraints.maxHeight < 620;

            return Stack(
              children: [
                // Bottom Right Decorative Wave (desktop only — hidden on mobile/tablet)
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

                // Top Left Brand Logo (desktop only — hidden on mobile/tablet)
                if (isDesktop && !isShortScreen && constraints.maxWidth > 350)
                  Positioned(
                    top: 20,
                    left: 40,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.asset(
                          "assets/Icons/Qist_Logo_trans.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                                "QISTX",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),

                // Main Content with Scrollbar
                Scrollbar(
                  controller: pageScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: pageScrollController,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20.0 : 40.0,
                            vertical: isDesktop ? 100.0 : 60.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Inline Logo for Very Short Devices (desktop only —
                              // mobile/tablet never shows the QistX icon)
                              if (isDesktop &&
                                  (isShortScreen ||
                                      constraints.maxWidth <= 350)) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 90,
                                    height: 45,
                                    child: Image.asset(
                                      "assets/Icons/Qist_Logo_trans.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Desktop = existing two column layout (unchanged)
                              // Mobile/Tablet = single column, screenshot order
                              isDesktop
                                  ? _buildDesktopLayout()
                                  : _buildMobileLayout(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================================================================
  // DESKTOP LAYOUT (unchanged behaviour, two columns side by side)
  // ==================================================================
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildLeftColumn(isDesktop: true)),
          const SizedBox(width: 40),
          Expanded(child: _buildRightColumn()),
        ],
      ),
    );
  }

  // ---------------- LEFT COLUMN WIDGET (desktop) ---------------- //
  Widget _buildLeftColumn({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleBlock(isDesktop: isDesktop),
          const SizedBox(height: 40),
          _buildGeneralInformationSection(),
          const SizedBox(height: 30),
          _buildLotBatchPricingSection(),
          const SizedBox(height: 40),
          const SizedBox(height: 48),
          SizedBox(width: 440, height: 50, child: _buildAddProductButton()),
        ],
      ),
    );
  }

  // ---------------- RIGHT COLUMN WIDGET (desktop, scrollable general info components) ---------------- //
  Widget _buildRightColumn() {
    return Padding(
      padding: const EdgeInsets.only(top: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnitsConversionsSection(),
          const SizedBox(height: 45),
          _buildDynamicAttributesSection(),
        ],
      ),
    );
  }

  // ==================================================================
  // MOBILE / TABLET LAYOUT (matches the provided screenshot order)
  // Title -> General Information -> Units/Conversions/Local Stock ->
  // Toggles & Warnings -> Wholesale Unit Conversions -> Dynamic Category
  // Attributes -> Lot/Batch/Initial Stock/Pricing -> Add Product button
  // ==================================================================
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleBlock(isDesktop: false),
        const SizedBox(height: 24),
        _buildGeneralInformationSection(),
        const SizedBox(height: 30),
        _buildUnitsConversionsSection(),
        const SizedBox(height: 30),
        _buildDynamicAttributesSection(),
        const SizedBox(height: 30),
        _buildLotBatchPricingSection(),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: _buildAddProductButton(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==================================================================
  // SHARED SECTIONS (used by both desktop and mobile layouts)
  // ==================================================================

  Widget _buildTitleBlock({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDesktop ? "Add New Product" : "Add New\nProduct",
          // On desktop the column is wide enough that the title should stay
          // on a single line instead of force-breaking.
          softWrap: !isDesktop,
          overflow: isDesktop ? TextOverflow.visible : TextOverflow.clip,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Set up product details, pricing, stock units,\nand lot batches across any retail category.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // "General Information": product photo, product name, category, SKU
  Widget _buildGeneralInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("General Information"),
        const SizedBox(height: 16),

        // Product Photo Upload Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: greyBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _selectedImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.image_outlined, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product Photo",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Tap to Upload",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 14,
                  // Agar image select ho gayi hai toh green color, warna primary orange
                  backgroundColor:
                      (_selectedImageBytes != null ||
                          _selectedImageFile != null)
                      ? Colors.green
                      : primaryOrange,
                  child: Icon(
                    // Agar image select ho gayi hai toh check icon, warna add icon
                    (_selectedImageBytes != null || _selectedImageFile != null)
                        ? Icons.check
                        : Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          "Product Name",
          Icons.calendar_view_day_outlined,
          productNameController,
        ),
        const SizedBox(height: 16),

        // Category Dropdown
        Container(
          height: 49,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
              ),
              items: ['Apparel', 'Unpacked', 'Packed', 'Electronics']
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 20,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            cat,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategory = val;
                  selectedBaseUnit = null;

                  selectedColor = null;
                  selectedGender = null;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSkuField(),
      ],
    );
  }

  // "Units, Conversions & Local Stock Settings": base unit, toggles &
  List<String> _getUnitsByCategory() {
    switch (selectedCategory) {
      case 'Apparel':
        return baseUnitList;

      case 'Unpacked':
        return [
          'Kilogram (kg)',
          'Gram (g)',
          'Liter (L)',
          'Milliliter (ml)',
          'Piece',
        ];

      case 'Packed':
        return ['Piece', 'Pack', 'Box', 'Carton', 'Dozen'];

      case 'Electronics':
        return ['Piece', 'Box', 'Set'];

      default:
        return ['Piece'];
    }
  }

  // warnings, wholesale unit conversions
  Widget _buildUnitsConversionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Units, Conversions & Local Stock Settings"),
        const SizedBox(height: 16),

        // Base Unit Selection Dropdown container
        Container(
          height: 49,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _getUnitsByCategory().contains(selectedBaseUnit)
                  ? selectedBaseUnit
                  : null,
              isExpanded: true,
              hint: const Row(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 20,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Base Unit Selection",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
              ),
              items: _getUnitsByCategory()
                  .toSet()
                  .map(
                    (unit) => DropdownMenuItem<String>(
                      value: unit,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.dashboard_outlined,
                            size: 20,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            unit,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedBaseUnit = val;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("Toggles & Warnings"),
        const SizedBox(height: 12),

        if (selectedCategory == 'Unpacked')
          Row(
            children: [
              Checkbox(
                value: allowFractionalSales,
                activeColor: primaryOrange,
                onChanged: (val) {
                  setState(() {
                    allowFractionalSales = val ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  "Allow Fractional Sales (inputs like 0.250 kg)",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        Row(
          children: [
            Checkbox(
              value: lowStockWarning,
              activeColor: primaryOrange,
              onChanged: (val) {
                setState(() {
                  lowStockWarning = val ?? false;
                });
              },
            ),
            const Text(
              "Low Stock Warning",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),

        // Show Warning on Qty only when Low Stock Warning is enabled
        if (lowStockWarning) ...[
          const SizedBox(height: 16),

          _buildTextField(
            "Warning on Qty",
            Icons.warning_amber_outlined,
            warningQtyController,
          ),

          const SizedBox(height: 20),
        ],
        const SizedBox(height: 20),

        const Text(
          "Wholesale Unit Conversions (e.g., Carton = Multiplier 24 Pieces)",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Wholesale Unit Conversions List
        if (wholesaleConversions.isNotEmpty)
          Column(
            children: wholesaleConversions.asMap().entries.map((entry) {
              final int index = entry.key;
              final Map<String, dynamic> conversion = entry.value;

              return GestureDetector(
                onTap: () {
                  _showWholesaleConversionDialog(editIndex: index);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Unit Name: ${conversion['unitName']}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Multiplier: ${conversion['multiplier']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            wholesaleConversions.removeAt(index);
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: 140,
          height: 40,
          child: OutlinedButton(
            onPressed: () {
              _showWholesaleConversionDialog();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryOrange, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Add",
              style: TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDynamicAttributesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Dynamic Category Attributes"),
        const SizedBox(height: 16),
        ..._buildDynamicAttributes(),
      ],
    );
  }

  // "Lot, Batch, Initial Stock and Pricing"
  Widget _buildLotBatchPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Lot, Batch, Initial Stock and Pricing"),
        const SizedBox(height: 16),
        _buildTextField(
          "Lot ID / Reference",
          Icons.layers_outlined,
          lotIdController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Initial Stock",
          Icons.inventory_2_outlined,
          initialStockController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Cost Price (PKR)",
          Icons.attach_money,
          costPriceController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Sale Price (PKR)",
          Icons.local_offer_outlined,
          salePriceController,
        ),
      ],
    );
  }

  Widget _buildAddProductButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _handleAddProduct,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        disabledBackgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: _isSaving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Product",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
    );
  }

  // Dynamic Category & Product Type Attribute Generator
  List<Widget> _buildDynamicAttributes() {
    List<Widget> attributes = [];

    if (selectedCategory == 'Apparel') {
      attributes.addAll([
        _buildTextField(
          "Enter Size",
          Icons.storefront_outlined,
          sizeController,
        ),

        const SizedBox(height: 16),

        _buildDropdownField(
          hint: "Select Color",
          icon: Icons.color_lens_outlined,
          value: selectedColor,
          items: colorList,
          onChanged: (value) {
            setState(() {
              selectedColor = value;
            });
          },
        ),

        const SizedBox(height: 16),

        _buildTextField(
          "Brand Name",
          Icons.storefront_outlined,
          brandNameController,
        ),

        const SizedBox(height: 16),

        _buildDropdownField(
          hint: "Gender",
          icon: Icons.wc_outlined,
          value: selectedGender,
          items: genderList,
          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
        ),
      ]);
    } else if (selectedCategory == 'Unpacked') {
      attributes.addAll([
        _buildDropdownField(
          hint: "Grade",
          icon: Icons.star_border,
          value: selectedgrade,
          items: gradelist,
          onChanged: (value) {
            setState(() {
              selectedgrade = value;
            });
          },
        ),

        const SizedBox(height: 16),

        _buildTextField("Expiry Date", Icons.access_time, expiryDateController),
      ]);
    } else if (selectedCategory == 'Packed') {
      attributes.addAll([
        _buildTextField(
          "Brand Name",
          Icons.local_cafe_outlined,
          brandNameController,
        ),

        const SizedBox(height: 16),

        _buildTextField(
          "Net Content",
          Icons.all_inclusive,
          netContentController,
        ),

        const SizedBox(height: 16),

        _buildTextField("Expiry Date", Icons.access_time, expiryDateController),
      ]);
    } else if (selectedCategory == 'Electronics') {
      attributes.addAll([
        _buildTextField(
          "Brand Name",
          Icons.local_cafe_outlined,
          brandNameController,
        ),

        const SizedBox(height: 16),

        _buildTextField("Model", Icons.view_in_ar_outlined, modelController),

        const SizedBox(height: 16),

        _buildTextField(
          "Warranty (Months)",
          Icons.access_time,
          warrantyController,
        ),
      ]);
    }

    return attributes;
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.black87, size: 22),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.orange, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,

          hint: Row(
            children: [
              Icon(icon, size: 22, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                hint,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),

          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 22, color: Colors.black87),
                  const SizedBox(width: 12),
                  Text(
                    item,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSkuField() {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: skuController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: "SKU will be generated automatically",
          hintStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.local_offer_outlined,
            color: Colors.black87,
            size: 22,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: const Icon(Icons.auto_awesome, color: Colors.green),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.orange, width: 1.5),
          ),
        ),
      ),
    );
  }
}
