import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qistx_app/View/classesui/dashedcirclepainter.dart';
import 'package:qistx_app/View/profilecreation/create_customer_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateShopProfile extends StatefulWidget {
  const CreateShopProfile({super.key});

  @override
  State<CreateShopProfile> createState() => _CreateShopProfileState();
}

class _CreateShopProfileState extends State<CreateShopProfile> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();

  String? _selectedCategory;
  File? _selectedImageFile; // Mobile / Desktop Native
  Uint8List? _selectedImageBytes; // Web Support
  String? _uploadedImageUrl;
  bool _isLoading = false;

  // Standard shop categories list
  final List<String> _categories = [
    "Groceries & Supermarkets",
    "Restaurants & Cafés",
    "Bakeries & Dessert Shops",
    "Pharmacies & Health",
    "Clothing & Apparel",
    "Footwear & Shoes",
    "Jewelry & Accessories",
    "Cosmetics & Beauty",
    "Mobile & Electronics",
    "Computers & Gadgets",
    "Toy & Game Stores",
    "Books & Stationery",
    "Furniture & Home Decor",
    "Home Appliances",
    "Hardware & Tools",
    "Sports & Fitness",
    "Pet Shops & Care",
    "Florists & Gift Shops",
    "Baby & Kids Stores",
    "Auto Parts & Services",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _saveCurrentScreen();
  }

  Future<void> _saveCurrentScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_screen", "create_shop_profile");
    } catch (e) {
      debugPrint("SharedPreferences Error: $e");
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  /// Pick Shop Logo Image
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) return;

      PlatformFile file = result.files.first;

      if (kIsWeb) {
        setState(() {
          _selectedImageBytes = file.bytes;
          _selectedImageFile = null;
        });
      } else {
        if (file.path == null) return;

        setState(() {
          _selectedImageFile = File(file.path!);
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      debugPrint("Image Pick Error: $e");
    }
  }

  //// Compressed function
  Future<Uint8List?> compressTo300KB(Uint8List bytes) async {
    if (bytes.lengthInBytes <= 300 * 1024) {
      return bytes;
    }

    img.Image? image = img.decodeImage(bytes);

    if (image == null) return null;

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

  /// Upload Logo Image to Supabase Storage Bucket ('shop_logos')
  Future<String?> _uploadImageToSupabase(String userId, String shopId) async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
      return null;
    }

    Uint8List? originalBytes;

    if (kIsWeb) {
      originalBytes = _selectedImageBytes;
    } else {
      originalBytes = await _selectedImageFile!.readAsBytes();
    }

    if (originalBytes == null) return null;

    Uint8List? imageBytes = await compressTo300KB(originalBytes);

    if (imageBytes == null) {
      throw Exception("Image compression failed.");
    }

    if (imageBytes.lengthInBytes > 300 * 1024) {
      throw Exception("Image size must not exceed 300 KB.");
    }

    try {
      const String fileExt = "jpg";
      final String filePath = '$userId/shop_profile_$shopId.$fileExt';

      await _supabase.storage
          .from('account-assets')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: "image/jpeg",
              upsert: true,
            ),
          );

      final imageUrl = _supabase.storage
          .from('account-assets')
          .getPublicUrl(filePath);

      debugPrint("Image Uploaded Successfully");
      debugPrint("Path : $filePath");
      debugPrint("URL  : $imageUrl");

      return imageUrl;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  /// Save Shop Profile Data & Continue
  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }
      final shopId = const Uuid().v4();

      _uploadedImageUrl = await _uploadImageToSupabase(user.id, shopId);

      final existingShop = await _supabase
          .from('shops')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      final shopData = {
        "id": shopId,
        "user_id": user.id,
        "shop_name": _shopNameController.text.trim(),
        "shop_category": _selectedCategory,
        "logo_url": _uploadedImageUrl,
        "updated_at": DateTime.now().toIso8601String(),
      };

      if (existingShop == null) {
        shopData["created_at"] = DateTime.now().toIso8601String();
        await _supabase.from("shops").insert(shopData);
      } else {
        await _supabase.from("shops").update(shopData).eq("user_id", user.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop profile saved successfully.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreateCustomerProfile()),
      );
    } catch (e) {
      debugPrint("Save Shop Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save shop profile.\n$e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Bottom Right Wave Decorative Graphic (Only for Desktop)
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

                // Top Left Brand Logo (Only for Desktop)
                if (isDesktop && constraints.maxWidth > 350)
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
                        ),
                      ),
                    ),
                  ),

                // Main Content Body Layout
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48.0 : 20.0,
                        vertical: 40.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 900 : 400,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              isDesktop
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildHeaderSection(isDesktop),
                                        ),
                                        const SizedBox(width: 50),
                                        Expanded(
                                          child: _buildFormFieldsSection(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildHeaderSection(isDesktop),
                                        const SizedBox(height: 28),
                                        _buildFormFieldsSection(),
                                      ],
                                    ),
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

  /// Header Text Block
  Widget _buildHeaderSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Setup Your Shop",
          style: TextStyle(
            fontSize: isDesktop ? 34 : 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Enter your store credentials and branding to start managing your shop.",
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Form Section (Logo Picker + Shop Name + Category Dropdown + Action Button)
  /// Form Section (Logo Picker + Shop Name + Category Dropdown + Action Button)
  Widget _buildFormFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shop Logo Section (Optimized for Mobile & Desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            bool isVeryNarrow = constraints.maxWidth < 350;

            if (isVeryNarrow) {
              // Pure Column layout for very small screens
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildLogoAvatar(),
                  const SizedBox(height: 16),
                  _buildLogoTextAndButton(),
                ],
              );
            } else {
              // Row layout for standard mobile and desktop
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildLogoAvatar(),
                  const SizedBox(width: 18),
                  Expanded(child: _buildLogoTextAndButton()),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 24),

        // Shop Name Input Field
        _buildTextField(
          controller: _shopNameController,
          hintText: "Shop Name",
          icon: Icons.storefront_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Please enter your shop name";
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Choose Shop Category Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          decoration: InputDecoration(
            hintText: "Choose Shop Category",
            hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: Colors.black54,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF5500),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          validator: (val) {
            if (val == null || val.isEmpty) {
              return "Please select a category for your shop";
            }
            return null;
          },
        ),

        const SizedBox(height: 32),

        // Save & Continue Button
        SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Flexible(
                        child: Text(
                          "Save & Continue",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // Helper Widget for Logo Avatar
  Widget _buildLogoAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        width: 85,
        height: 85,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(85, 85),
              painter: DashedCirclePainter(),
            ),
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFECECEC),
                backgroundImage: _selectedImageBytes != null
                    ? MemoryImage(_selectedImageBytes!)
                    : (_selectedImageFile != null
                          ? FileImage(_selectedImageFile!) as ImageProvider
                          : null),
                child:
                    (_selectedImageFile == null && _selectedImageBytes == null)
                    ? const Icon(
                        Icons.storefront_outlined,
                        size: 40,
                        color: Color(0xFF616161),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Logo Text & Upload Button
  Widget _buildLogoTextAndButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            label: const Text(
              "Upload Logo",
              style: TextStyle(
                color: Color(0xFFFF5500),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: const BorderSide(color: Color(0xFFFF5500), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Custom TextFormField Helper
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
