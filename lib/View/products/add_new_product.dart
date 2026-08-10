import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddNewProduct extends StatefulWidget {
  const AddNewProduct({super.key});

  @override
  State<AddNewProduct> createState() => _AddNewProductState();
}

class _AddNewProductState extends State<AddNewProduct> {
  final ScrollController pageScrollController = ScrollController();

  // Theme Colors
  final Color primaryOrange = const Color(0xFFFF6600);
  final Color greyBackground = const Color(0xFFE0E0E0);

  Uint8List? _selectedImageBytes; // Web Support
  File? _selectedImageFile;

  // Selected Category & Product Subtype
  String? selectedCategory = 'Apparel';
  String productType =
      'Unpacked Products'; // Unpacked Products vs Packed Products

  @override
  void initState() {
    super.initState();
    _saveCurrentScreen();
  }

  Future<void> _saveCurrentScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_screen", "add_new_product");
    } catch (e) {
      debugPrint("SharedPreferences Error: $e");
    }
  }

  /// Cross-platform image picker handling Windows desktop, Web, and Mobile seamlessly.
  Future<void> _pickImage() async {
    try {
      // FilePicker se sirf images filter karein
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Web aur Desktop (Windows/Mac/Linux) ke liye bytes use karna sabse safe hai
        if (kIsWeb ||
            Platform.isWindows ||
            Platform.isMacOS ||
            Platform.isLinux) {
          if (file.bytes != null) {
            setState(() {
              _selectedImageBytes = file.bytes;
              _selectedImageFile = null;
            });
          } else if (file.path != null) {
            // Agar bytes null hon toh path se read kar lein
            final bytes = await File(file.path!).readAsBytes();
            setState(() {
              _selectedImageBytes = bytes;
              _selectedImageFile = null;
            });
          }
        } else {
          // Mobile (Android/iOS) ke liye File path use karein
          if (file.path != null) {
            setState(() {
              _selectedImageFile = File(file.path!);
              _selectedImageBytes = null;
            });
          }
        }
      }
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

        _buildTextField("Product Name", Icons.calendar_view_day_outlined),
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
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildTextField("SKU", Icons.local_offer_outlined),
      ],
    );
  }

  // "Units, Conversions & Local Stock Settings": base unit, toggles &
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
          child: Row(
            children: [
              const Icon(
                Icons.dashboard_outlined,
                size: 20,
                color: Colors.black87,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Base Unit Selection",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader("Toggles & Warnings"),
        const SizedBox(height: 12),

        Row(
          children: [
            Checkbox(
              value: true,
              activeColor: primaryOrange,
              onChanged: (val) {},
            ),
            const Text(
              "Allow Fractional Sales (inputs like 0.250 kg)",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: false,
              activeColor: primaryOrange,
              onChanged: (val) {},
            ),
            const Text(
              "Low Stock Warning",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildTextField("Warning on Qty", Icons.warning_amber_outlined),
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

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Unit Name: Carton",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Multiplier: 24",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: 140,
          height: 40,
          child: OutlinedButton(
            onPressed: () {},
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
        _buildTextField("Lot ID / Reference", Icons.layers_outlined),
        const SizedBox(height: 16),
        _buildTextField("Initial Stock", Icons.inventory_2_outlined),
        const SizedBox(height: 16),
        _buildTextField("Cost Price (PKR)", Icons.attach_money),
        const SizedBox(height: 16),
        _buildTextField("Sale Price (PKR)", Icons.local_offer_outlined),
      ],
    );
  }

  Widget _buildAddProductButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: const Row(
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
        _buildDropdownField("Select Size", Icons.format_size),
        const SizedBox(height: 16),
        _buildDropdownField("Select Color", Icons.color_lens_outlined),
        const SizedBox(height: 16),
        _buildTextField("Brand Name", Icons.storefront_outlined),
        const SizedBox(height: 16),
        _buildDropdownField("Gender", Icons.wc_outlined),
      ]);
    } else if (selectedCategory == 'Unpacked') {
      attributes.addAll([
        _buildDropdownField("Grade", Icons.star_border),
        const SizedBox(height: 16),
        _buildTextField("Expiry Date", Icons.access_time),
      ]);
    } else if (selectedCategory == 'Packed') {
      attributes.addAll([
        _buildTextField("Brand Name", Icons.local_cafe_outlined),
        const SizedBox(height: 16),
        _buildTextField("Net Content", Icons.all_inclusive),
        const SizedBox(height: 16),
        _buildTextField("Expiry Date", Icons.access_time),
      ]);
    } else if (selectedCategory == 'Electronics') {
      attributes.addAll([
        _buildTextField("Brand Name", Icons.local_cafe_outlined),
        const SizedBox(height: 16),
        _buildTextField("Model", Icons.view_in_ar_outlined),
        const SizedBox(height: 16),
        _buildTextField("Warranty (Months)", Icons.access_time),
      ]);
    }
    return attributes;
  }
}

Widget _buildTextField(String hint, IconData icon) {
  return SizedBox(
    height: 55,
    child: TextField(
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

Widget _buildDropdownField(String text, IconData icon) {
  return Container(
    height: 49,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade400, width: 1),
    ),
    child: Row(
      children: [
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
      ],
    ),
  );
}
